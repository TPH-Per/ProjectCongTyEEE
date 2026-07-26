# Thiết Kế Kiến Trúc PerSever - Hệ Thống In Bếp Phân Tán (Pub/Sub & Local Queue)

Dựa trên yêu cầu của bạn, đây là bản thiết kế lại (Redesign) hoàn chỉnh cho luồng in ấn (Kitchen Printing) của nhà hàng, tuân thủ chặt chẽ **nguyên tắc RPC-only** và **RLS Security** từ Schema V6. 

Mô hình này kết hợp **Supabase Realtime Broadcast (Pub/Sub)** để tối ưu hóa độ trễ (low latency) và **Local Print Queue** tại mỗi chi nhánh để giải quyết triệt để lỗi xung đột lệnh in (race condition), đồng thời tái sử dụng sức mạnh của bảng `outbox_jobs` hiện có.

---

## 1. Tổng Quan Kiến Trúc (Architecture Overview)

* **Supabase Database (`outbox_jobs`):** Tái sử dụng bảng `outbox_jobs` với `job_type = 'print_job'`. Hoạt động như Source of Truth và hệ thống Retry (tận dụng `attempt_count`, `next_attempt_at`).
* **Atomic RPC:** Việc insert lệnh in vào `outbox_jobs` được thực hiện **cùng chung một Transaction** trong RPC đặt món (vd: `command_submit_order`), đảm bảo tính Atomic (không có lệnh in rác nếu order thất bại).
* **Supabase Realtime Trigger:** Trigger gắn trên bảng `outbox_jobs` sẽ tự động `realtime.send` vào topic `print_jobs:{branch_id}` khi có job in mới.
* **PerSever (Mini Server Node.js):** 
  * Xác thực an toàn bằng `SUPABASE_SERVICE_ROLE_KEY` (vì đây là server nội bộ tin cậy, giúp bypass RLS cho việc query nếu cần).
  * Subscribe topic `print_jobs:{branch_id}` để nhận event in ấn ngay lập tức.
  * Phân loại lệnh in theo `station_id` (trích xuất từ payload) và đẩy vào **Local Queue**.
  * Chạy tính năng Recovery bằng cách gọi RPC `query_pending_print_jobs` để fetch các job bị kẹt mà không vi phạm nguyên tắc truy xuất API trực tiếp từ Client.
* **Local Print Queue (trong PerSever):** Mỗi máy in vật lý có 1 hàng đợi riêng (FIFO). Xử lý tuần tự bằng Mutex, chống tràn bộ đệm phần cứng và giải quyết race condition triệt để.

---

## 2. Thiết Kế Database (Tái sử dụng Schema & RPC)

### 2.1 Trigger Broadcast trên bảng `outbox_jobs`

Bảng `outbox_jobs` đã có sẵn. Ta chỉ cần thêm Trigger để bắn Realtime khi có dòng mới mang `job_type = 'print_job'`.

```sql
CREATE OR REPLACE FUNCTION notify_new_print_job()
RETURNS trigger AS $$
DECLARE
    topic_name TEXT;
    station_id TEXT;
    ws_payload JSONB;
BEGIN
    -- Chỉ xử lý nếu job_type là print_job
    IF NEW.job_type = 'print_job' THEN
        -- Trích xuất station_id từ payload (vd: 'hot_kitchen')
        station_id := NEW.payload->>'station_id';
        
        -- Định tuyến Topic theo Branch
        topic_name := 'print_jobs:' || NEW.branch_id;
        
        -- Xây dựng payload cho WebSocket
        ws_payload := jsonb_build_object(
            'type', 'broadcast',
            'event', 'new_job',
            'payload', jsonb_build_object(
                'job_id', NEW.id,
                'station_id', station_id,
                'content', NEW.payload->'content'
            )
        );

        -- Gửi sự kiện Broadcast qua Supabase Realtime
        PERFORM realtime.send(ws_payload, topic_name);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_print_job
AFTER INSERT ON public.outbox_jobs
FOR EACH ROW
EXECUTE FUNCTION notify_new_print_job();
```

### 2.2 Đảm bảo tính Atomic trong RPC Đặt món

Không gọi API insert print job tách rời từ client. Mọi thứ xử lý trong 1 RPC duy nhất, giống pattern `commandRecordPaymentAttempt`.

```sql
CREATE OR REPLACE FUNCTION command_submit_order(p_branch_id UUID, p_session_id UUID, p_items JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER -- Thực thi dưới quyền admin
AS $$
DECLARE
    v_order_id UUID;
    -- ... các biến khác
BEGIN
    -- 1. Insert/Update bảng orders và order_details
    -- (Tạo order, gán kitchen_status = 'sent', ...)
    
    -- 2. Đưa lệnh in vào outbox_jobs ngay trong transaction này (Tính Atomic)
    INSERT INTO public.outbox_jobs (
        branch_id, 
        job_type, 
        payload, 
        status
    ) VALUES (
        p_branch_id,
        'print_job',
        jsonb_build_object(
            'station_id', 'hot_kitchen',
            'content', p_items -- Thông tin các món cần in
        ),
        'pending'
    );
    
    RETURN jsonb_build_object('success', true, 'order_id', v_order_id);
END;
$$;
```

### 2.3 RPC Lấy danh sách phiếu in bị kẹt (Recovery)

Để PerSever lấy được dữ liệu mà không vướng RLS, đồng thời tuân thủ nguyên tắc RPC-only, ta cung cấp RPC riêng:

```sql
CREATE OR REPLACE FUNCTION query_pending_print_jobs(p_branch_id UUID)
RETURNS TABLE (
    id UUID,
    payload JSONB,
    attempt_count INT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY 
    SELECT o.id, o.payload, o.attempt_count 
    FROM public.outbox_jobs o
    WHERE o.branch_id = p_branch_id
      AND o.job_type = 'print_job'
      AND o.status = 'pending'
      -- Chỉ lấy các job đến thời điểm cần thử lại (dành cho retry backoff)
      AND (o.next_attempt_at IS NULL OR o.next_attempt_at <= NOW())
    ORDER BY o.created_at ASC;
END;
$$;
```

---

## 3. Mã Nguồn PerSever (Node.js/TypeScript)

Bản cập nhật sử dụng `SUPABASE_SERVICE_ROLE_KEY` và tận dụng cơ chế Retry.

### 3.1 Cấu trúc Local Queue & Retry Logic

Tích hợp `attempt_count` và xử lý backoff (đẩy lùi thời gian thử lại) nếu in thất bại.

```typescript
// file: src/PrintQueue.ts
import { Mutex } from 'async-mutex';
import { supabase } from './supabaseClient'; // Khởi tạo với SERVICE_ROLE_KEY

export class PrintQueue {
  private queue: any[] = [];
  private isProcessing = false;
  private mutex = new Mutex();
  private stationId: string;

  constructor(stationId: string) {
    this.stationId = stationId;
  }

  public async addJob(job: any) {
    await this.mutex.runExclusive(() => {
      this.queue.push(job);
    });
    this.processQueue();
  }

  private async processQueue() {
    if (this.isProcessing) return;
    this.isProcessing = true;

    while (this.queue.length > 0) {
      let job;
      await this.mutex.runExclusive(() => {
        job = this.queue.shift();
      });

      if (job) {
        try {
          await this.printPhysically(job);
          await this.markJobCompleted(job.job_id);
        } catch (error) {
          console.error(`[${this.stationId}] Lỗi in job ${job.job_id}:`, error);
          await this.markJobFailed(job.job_id, job.attempt_count || 0);
        }
      }
    }
    this.isProcessing = false;
  }

  private async printPhysically(job: any) {
    console.log(`🖨️ [${this.stationId}] Đang in phiếu:`, job.job_id);
    await new Promise(resolve => setTimeout(resolve, 500)); 
  }

  // Update trạng thái thành công qua RPC hoặc Supabase Client với Service Role
  private async markJobCompleted(jobId: string) {
    await supabase.rpc('command_update_outbox_status', { 
      p_job_id: jobId, 
      p_status: 'completed' 
    });
  }

  // Cập nhật lỗi, tính toán backoff và tăng attempt_count
  private async markJobFailed(jobId: string, currentAttempts: number) {
    const nextAttempt = new Date(Date.now() + 5000 * Math.pow(2, currentAttempts)); // Exponential backoff (5s, 10s, 20s...)
    await supabase.rpc('command_fail_outbox_job', { 
      p_job_id: jobId, 
      p_next_attempt_at: nextAttempt.toISOString()
    });
  }
}
```

### 3.2 Main Listener (Kết nối & Recovery bằng RPC)

```typescript
// file: src/index.ts
import { createClient } from '@supabase/supabase-js';
import { PrintQueue } from './PrintQueue';

const SUPABASE_URL = process.env.SUPABASE_URL!;
// SỬ DỤNG SERVICE_ROLE_KEY ĐỂ BYPASS RLS AN TOÀN CHO INTERNAL SERVER
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const BRANCH_ID = process.env.BRANCH_ID!; 

// Xuất supabase client cấu hình sẵn
export const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const queues: Record<string, PrintQueue> = {
  'hot_kitchen': new PrintQueue('hot_kitchen'),
  'meat_kitchen': new PrintQueue('meat_kitchen'),
  'cashier': new PrintQueue('cashier'),
};

function getQueue(stationId: string): PrintQueue {
  if (!queues[stationId]) {
    queues[stationId] = new PrintQueue(stationId);
  }
  return queues[stationId];
}

// 1. Phục hồi dữ liệu bằng RPC (Tuân thủ RPC-only, không query bảng trực tiếp)
async function fetchPendingJobs() {
  console.log('🔄 Đang kiểm tra các lệnh in bị sót qua RPC...');
  
  const { data, error } = await supabase.rpc('query_pending_print_jobs', {
    p_branch_id: BRANCH_ID
  });

  if (error) {
    console.error('Lỗi khi fetch pending jobs:', error);
    return;
  }

  if (data && data.length > 0) {
    console.log(`Tìm thấy ${data.length} phiếu chưa in. Bắt đầu đẩy vào queue...`);
    for (const row of data) {
      const stationId = row.payload?.station_id || 'unknown';
      const queue = getQueue(stationId);
      queue.addJob({ 
        job_id: row.id, 
        content: row.payload?.content,
        attempt_count: row.attempt_count 
      });
    }
  }
}

// 2. Thiết lập Realtime Subscriber
function startRealtimeSubscription() {
  const topic = `print_jobs:${BRANCH_ID}`;
  console.log(`🚀 Đang subscribe vào topic: ${topic}`);

  const channel = supabase.channel(topic);

  channel
    .on('broadcast', { event: 'new_job' }, (msg) => {
      const payload = msg.payload;
      console.log(`🔔 Nhận job in mới (Station: ${payload.station_id})`);
      
      const queue = getQueue(payload.station_id);
      queue.addJob(payload);
    })
    .subscribe(async (status) => {
      if (status === 'SUBSCRIBED') {
        console.log('✅ Đã kết nối Supabase Realtime thành công!');
        // Quét lấy các pending job mỗi khi kết nối được phục hồi
        await fetchPendingJobs();
      }
    });
}

// Khởi động PerSever
startRealtimeSubscription();
```
