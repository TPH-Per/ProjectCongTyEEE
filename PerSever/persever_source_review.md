# BÁO CÁO THẨM ĐỊNH MÃ NGUỒN (SOURCE CODE REVIEW)
**Dự án:** PerSever - Hỗ trợ in ấn bếp/hoá đơn nội bộ F2TECH Restaurant (Cloud-to-Local Print Bridge)
**Mô tả:** Máy chủ cầu nối (Local Print Server) lắng nghe sự kiện từ Supabase PostgreSQL qua kênh Pub/Sub (LISTEN/NOTIFY), phân loại theo hàng đợi (FIFO Queues) và gửi lệnh ESC/POS qua kết nối TCP xuống máy in vật lý mạng LAN (port 9100).

---

## 1. CẤU TRÚC DỮ LIỆU & TRIGGER TẠI CLOUD (Supabase)
**File:** `POS\supabase\migrations\20260715151200_setup_print_jobs.sql`
```sql
-- BƯỚC 1: TẠO BẢNG PRINT_JOBS
CREATE TABLE public.print_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID, -- Không dùng Foreign Key để giữ trạng thái Snapshot, nhưng dùng để index tra cứu
    printer_id VARCHAR(50) NOT NULL, -- Ví dụ: 'KITCHEN_HOT', 'KITCHEN_COLD', 'BAR', 'RECEIPT'
    payload JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'completed', 'failed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- Tối ưu tốc độ tra cứu lịch sử in ấn theo đơn hàng (VD: Tái in lại toàn bộ bill của Bàn X)
CREATE INDEX idx_print_jobs_order_id ON public.print_jobs (order_id);

-- BƯỚC 2: TẠO HÀM PG_NOTIFY
CREATE OR REPLACE FUNCTION notify_print_job()
RETURNS trigger AS $$
BEGIN
  -- Chỉ bắn thông báo khi có bill mới ở trạng thái 'pending'
  IF NEW.status = 'pending' THEN
    PERFORM pg_notify(
      'printer_channel',
      json_build_object(
        'id', NEW.id,
        'order_id', NEW.order_id,
        'printer_id', NEW.printer_id,
        'payload', NEW.payload
      )::text
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- BƯỚC 3: GẮN TRIGGER VÀO BẢNG
CREATE TRIGGER trg_print_jobs_insert
AFTER INSERT ON public.print_jobs
FOR EACH ROW
EXECUTE FUNCTION notify_print_job();
```

---

## 2. CẤU HÌNH MÔI TRƯỜNG BẢO MẬT (Environment Variables)
**File:** `PerSever\.env`
```env
# Mật khẩu database Supabase (Phải đổi thành password thật)
# Chú ý: Đã cấu hình username theo Project ID lấy từ dự án POS (zjtnmrcczkbcoxjlndva)
DATABASE_URL=postgresql://postgres.zjtnmrcczkbcoxjlndva:[PASSWORD]@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres

# Cấu hình IP Máy in tương ứng với Printer ID
PRINTER_KITCHEN_HOT=192.168.1.201
PRINTER_KITCHEN_COLD=192.168.1.202
PRINTER_BAR=192.168.1.203
PRINTER_RECEIPT=192.168.1.200

# Tuỳ biến Delay (chờ cắt giấy) tuỳ theo cấu hình dòng máy (giây) - Load động trong logic
# PRINTER_DELAY_KITCHEN_HOT=2.0
```

---

## 3. MODELS (Pydantic Schema Validation)
**File:** `PerSever\models.py`
```python
from pydantic import BaseModel
from typing import List, Optional

class PrintItem(BaseModel):
    name: str
    quantity: int
    note: Optional[str] = None
    price: Optional[float] = None
    part_of_combo: Optional[str] = None # Thêm trường lưu context của Combo

class PrintPayload(BaseModel):
    type: str # 'kitchen' | 'receipt'
    items: List[PrintItem]
    total_amount: Optional[float] = None

class PrintJob(BaseModel):
    id: str
    order_id: Optional[str] = None
    printer_id: str
    payload: PrintPayload
```

---

## 4. ENTRYPOINT (API & Lifecycle Management)
**File:** `PerSever\main.py`
```python
import asyncio
from fastapi import FastAPI
from printer_logic import queues, worker_loop
import database

app = FastAPI(title="F2TECH Local Print Server")

@app.on_event("startup")
async def startup_event():
    # 0. Khởi tạo DB Pool (Cần thiết cho Recovery và Batch Update)
    await database.init_db_pool()
    
    # 0.5 Load lại pending jobs cũ (Nếu server vừa bị sập rồi restart)
    await database.startup_recovery()
    
    # 1. Khởi chạy 4 Workers cho 4 máy in
    for ip in queues.keys():
        asyncio.create_task(worker_loop(ip))
        
    # 2. Khởi chạy Resilient Listener nghe ngóng từ Supabase
    asyncio.create_task(database.resilient_listener())
    
    # 3. Khởi chạy Batch Updater ngầm
    asyncio.create_task(database.batch_updater_daemon())
    
    print("[*] Server Started! All Workers, Listeners, and Daemons are running.")

@app.get("/")
async def root():
    return {"message": "F2TECH Print Server is running!"}

@app.get("/status")
async def get_status():
    """
    Xem tình trạng hàng đợi hiện tại của các máy in
    """
    status = {}
    for ip, q in queues.items():
        status[ip] = {"pending_jobs": q.qsize()}
    return status
```

---

## 5. BỘ XỬ LÝ DATABASE (Pub/Sub & Resilience & Optimization)
**File:** `PerSever\database.py`
```python
import asyncio
import asyncpg
import json
import os
from printer_logic import queues

# Batch Updater State
_status_batch = []
_batch_lock = asyncio.Lock()
_pool = None

async def init_db_pool():
    global _pool
    db_url = os.getenv('DATABASE_URL')
    if db_url and "PASSWORD" not in db_url:
        _pool = await asyncpg.create_pool(db_url, min_size=1, max_size=5)
        print("[*] Database Pool Initialized.")
        return True
    return False

async def report_job_status(job_id: str, status: str):
    """
    Thêm job_id vào mẻ (batch) để update status. Gom theo N job hoặc 30s.
    """
    async with _batch_lock:
        _status_batch.append((job_id, status))
        print(f"[Batcher] Added job {job_id} ({status}) to batch. Queue size: {len(_status_batch)}")
        if len(_status_batch) >= 10:
            asyncio.create_task(flush_status_batch())

async def batch_updater_daemon():
    """
    Chạy ngầm cứ mỗi 30s sẽ flush một mẻ update xuống DB (Cost Optimization)
    """
    while True:
        await asyncio.sleep(30)
        await flush_status_batch()

async def flush_status_batch():
    """
    Thực thi 1 câu lệnh SQL duy nhất để update n row.
    """
    global _status_batch
    async with _batch_lock:
        if not _status_batch:
            return
            
        batch_to_process = _status_batch.copy()
        _status_batch.clear()
        
    if not _pool:
        return
        
    completed_ids = [j[0] for j in batch_to_process if j[1] == 'completed']
    failed_ids = [j[0] for j in batch_to_process if j[1] == 'failed']
    
    try:
        async with _pool.acquire() as conn:
            # Update Completed
            if completed_ids:
                await conn.execute("UPDATE print_jobs SET status = 'completed' WHERE id = ANY($1::uuid[])", completed_ids)
            # Update Failed
            if failed_ids:
                await conn.execute("UPDATE print_jobs SET status = 'failed' WHERE id = ANY($1::uuid[])", failed_ids)
                
        print(f"[*] [Cost Optimization] Flushed {len(batch_to_process)} status updates to DB in 1 request.")
    except Exception as e:
        print(f"[!] Error flushing batch: {e}")
        # Đẩy lại vào batch nếu lỗi (Retry)
        async with _batch_lock:
            _status_batch.extend(batch_to_process)

async def startup_recovery():
    """
    [Phase 3] Load lại pending jobs khi Mini Server bị tắt đột ngột (restart).
    """
    if not _pool:
        return
        
    try:
        async with _pool.acquire() as conn:
            rows = await conn.fetch("SELECT id, printer_id, payload FROM print_jobs WHERE status = 'pending' ORDER BY created_at ASC")
            count = 0
            for row in rows:
                printer_id = row['printer_id']
                if printer_id in queues:
                    job = {
                        "id": str(row['id']),
                        "printer_id": printer_id,
                        "payload": json.loads(row['payload']) if isinstance(row['payload'], str) else row['payload']
                    }
                    queues[printer_id].put_nowait(job)
                    count += 1
            if count > 0:
                print(f"[*] [Recovery] Đã vớt {count} pending jobs từ Database nạp vào Queue.")
    except Exception as e:
        print(f"[!] Startup Recovery Error: {e}")

async def resilient_listener():
    """
    [Phase 3] Listener có khả năng tự động reconnect nếu đứt mạng và heartbeat.
    """
    db_url = os.getenv('DATABASE_URL')
    if not db_url or "PASSWORD" in db_url:
        print("[!] Chú ý: Cần setup DATABASE_URL thực tế trong file .env để lắng nghe DB")
        return
        
    while True:
        try:
            conn = await asyncpg.connect(db_url)
            print("[*] Successfully connected to Postgres. Listening for Print Jobs...")

            def handle_notification(connection, pid, channel, payload):
                try:
                    job = json.loads(payload)
                    printer_id = job.get('printer_id')
                    
                    if printer_id in queues:
                        queues[printer_id].put_nowait(job)
                except Exception as e:
                    print(f"Error parsing notification payload: {e}")

            await conn.add_listener('printer_channel', handle_notification)
            
            # Heartbeat loop (1 phút gửi 1 lệnh SELECT 1)
            while True:
                await asyncio.sleep(60)
                await conn.execute("SELECT 1")
                
        except (asyncpg.exceptions.ConnectionDoesNotExistError, ConnectionError, OSError) as e:
            print(f"[!] Rớt mạng hoặc đứt kết nối DB: {e}. Đang thử kết nối lại sau 5s...")
            await asyncio.sleep(5)
        except Exception as e:
            print(f"[!] Lỗi không xác định ở Listener: {e}. Retry sau 5s...")
            await asyncio.sleep(5)
```

---

## 6. LÕI HÀNG ĐỢI (Queue) & GIAO TIẾP PHẦN CỨNG ESC/POS (TCP Client)
**File:** `PerSever\printer_logic.py`
```python
import asyncio
import os
from dotenv import load_dotenv
try:
    from escpos.printer import Network
except ImportError:
    Network = None

load_dotenv()

# Tạo Queue động (Config-driven)
PRINTER_MAP = {}
PRINTER_DELAYS = {}
queues = {}

# Idempotency Cache: Tránh in đúp (Double print)
from collections import deque
processed_jobs_cache = deque(maxlen=1000)

for key, ip in os.environ.items():
    if key.startswith("PRINTER_") and not key.startswith("PRINTER_DELAY_"):
        printer_id = key.replace("PRINTER_", "") 
        PRINTER_MAP[printer_id] = ip
        delay = float(os.getenv(f"PRINTER_DELAY_{printer_id}", 2.0))
        PRINTER_DELAYS[printer_id] = delay
        queues[printer_id] = asyncio.Queue()

def print_to_hardware(printer_id: str, payload: dict):
    """
    TCP Client: Giao thức ESC/POS - Kết nối Socket tới Port 9100.
    """
    ip = PRINTER_MAP.get(printer_id)
    if not ip:
        raise Exception(f"Không tìm thấy cấu hình IP cho máy in {printer_id}")
        
    try:
        # 1. TCP Socket, timeout 5s. Profile chống lỗi buffer.
        printer = Network(host=ip, port=9100, timeout=5, profile="TM-T88V")
        
        # 2. Encoding cho Tiếng Việt
        printer.charcode(code='AUTO') 
        
        job_type = payload.get('type', 'kitchen')
        
        # 3. Header
        printer.set(align='center', bold=True, double_height=True, double_width=True)
        if job_type == 'kitchen':
            printer.text("== PHIEU CHE BIEN ==\n\n")
        else:
            printer.text("== F2TECH RESTAURANT ==\n")
            printer.set(align='center', bold=False, double_height=False, double_width=False)
            printer.text("123 Nguyen Van Linh, Da Nang\n\n")
            printer.set(align='center', bold=True, double_height=True, double_width=True)
            printer.text("HOA DON THANH TOAN\n\n")
            
        printer.set(align='left', bold=True, normal=True)
        if payload.get('table_name'):
            printer.text(f"BAN: {payload['table_name']}\n")
        
        printer.set(align='left', bold=False, normal=True)
        printer.text("-" * 32 + "\n")
        
        # 4. In Items
        for item in payload.get('items', []):
            qty = item.get('quantity', 1)
            name = item.get('name', 'Unknown')
            note = item.get('note', '')
            part_of_combo = item.get('part_of_combo', None)
            price = item.get('price', 0)
            
            if job_type == 'receipt':
                # Căn lề tự động cho giá tiền (Padding space calculation)
                line = f"{qty} x {name}"
                price_str = f"{price:,.0f}d"
                padding = 48 - len(line) - len(price_str)
                if padding > 0:
                    printer.text(f"{line}{' ' * padding}{price_str}\n")
                else:
                    printer.text(f"{line}\n{price_str:>48}\n")
            else:
                printer.set(bold=True)
                printer.text(f"{qty} x {name}\n")
                printer.set(bold=False)
                
            if part_of_combo:
                printer.text(f"   (Phan cua Combo: {part_of_combo})\n")
            if note:
                printer.text(f"   LUU Y: *{note}*\n")
                
        printer.text("-" * 32 + "\n\n")
        
        # 5. Kích két sắt và Cắt giấy
        if job_type == 'receipt':
            printer.cashdraw(2)
        
        printer.cut()
        printer.close()
        
    except Exception as e:
        print(f"[LỖI KẾT NỐI MÁY IN - {printer_id} - IP: {ip}] {str(e)}")
        raise e

async def worker_loop(printer_id: str):
    """
    FIFO Consumer loop. Tự động retry và update batch trạng thái (Dead-letter queue support)
    """
    import database
    
    ip = PRINTER_MAP.get(printer_id)
    delay = PRINTER_DELAYS.get(printer_id, 2.0)
    
    while True:
        job = await queues[printer_id].get()
        job_id = job.get('id')
        
        # Chống In Đúp (Idempotency Check)
        if job_id in processed_jobs_cache:
            queues[printer_id].task_done()
            continue
            
        retry_count = 0
        max_retries = 3
        success = False
        
        while retry_count < max_retries and not success:
            try:
                # print_to_hardware(printer_id, job['payload']) # Bỏ comment khi deploy thật
                
                await asyncio.sleep(delay) # Đệm giải phóng bộ nhớ máy in
                
                success = True
                processed_jobs_cache.append(job_id)
                await database.report_job_status(job_id, 'completed')
                
            except Exception as e:
                retry_count += 1
                await asyncio.sleep(3) 
                
        if not success:
            processed_jobs_cache.append(job_id)
            await database.report_job_status(job_id, 'failed')
            
        queues[printer_id].task_done()
```
