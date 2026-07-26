import asyncio
import os
import json
from printer_logic import queues

# Khởi tạo Supabase client (Lazy init)
supabase = None
_status_batch = []
_batch_lock = asyncio.Lock()

async def init_supabase_client():
    """
    Khởi tạo Supabase Client (thay vì asyncpg)
    """
    global supabase
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_KEY")
    
    if url and key:
        try:
            # Import bên trong để tránh crash nếu chưa cài package
            from supabase import acreate_client
            supabase = await acreate_client(url, key)
            print("[*] Supabase Realtime Client Initialized.")
            return True
        except ImportError:
            print("[!] Lỗi: Chưa cài đặt thư viện 'supabase'. Chạy lệnh: poetry add supabase")
            return False
    else:
        print("[!] Thiếu SUPABASE_URL hoặc SUPABASE_KEY trong file .env")
        return False

async def report_job_status(job_id: str, status: str):
    """
    Thêm job_id vào mẻ (batch) để update status.
    """
    async with _batch_lock:
        _status_batch.append((job_id, status))
        print(f"[Batcher] Added job {job_id} ({status}) to batch. Queue size: {len(_status_batch)}")
        if len(_status_batch) >= 10:
            asyncio.create_task(flush_status_batch())

async def batch_updater_daemon():
    """
    Chạy ngầm cứ mỗi 30s sẽ flush một mẻ update xuống DB qua API
    """
    while True:
        await asyncio.sleep(30)
        await flush_status_batch()

async def flush_status_batch():
    """
    Thực thi 1 câu lệnh API duy nhất để update n row.
    """
    global _status_batch
    async with _batch_lock:
        if not _status_batch:
            return
            
        batch_to_process = _status_batch.copy()
        _status_batch.clear()
        
    if not supabase:
        return
        
    completed_ids = [j[0] for j in batch_to_process if j[1] == 'completed']
    failed_ids = [j[0] for j in batch_to_process if j[1] == 'failed']
    
    try:
        # Update Completed
        if completed_ids:
            await supabase.table('print_jobs').update({"status": "completed"}).in_("id", completed_ids).execute()
        # Update Failed
        if failed_ids:
            await supabase.table('print_jobs').update({"status": "failed"}).in_("id", failed_ids).execute()
                
        print(f"[*] [Cost Optimization] Flushed {len(batch_to_process)} status updates to Supabase API.")
    except Exception as e:
        print(f"[!] Error flushing batch: {e}")
        # Đẩy lại vào batch nếu lỗi (Retry)
        async with _batch_lock:
            _status_batch.extend(batch_to_process)

async def startup_recovery():
    """
    [Phase 3] Load lại pending jobs khi Mini Server bị tắt đột ngột (restart).
    """
    if not supabase:
        return
        
    branch_id = os.environ.get("BRANCH_ID")
    if not branch_id:
        print("[!] Không có BRANCH_ID, bỏ qua Recovery.")
        return
        
    try:
        # Kéo 100 jobs đang pending của branch này
        response = await supabase.table('print_jobs').select("*").eq("status", "pending").eq("branch_id", branch_id).order("created_at").limit(100).execute()
        count = 0
        
        for row in response.data:
            printer_id = row.get('printer_id')
            if printer_id in queues:
                job = {
                    "id": str(row['id']),
                    "printer_id": printer_id,
                    "payload": row['payload'] # API trả về dict chuẩn, không cần json.loads
                }
                queues[printer_id].put_nowait(job)
                count += 1
                
        if count > 0:
            print(f"[*] [Recovery] Đã vớt {count} pending jobs từ Database nạp vào Queue.")
    except Exception as e:
        print(f"[!] Startup Recovery Error: {e}")

async def resilient_listener():
    """
    Sử dụng Supabase Realtime thay vì pg_notify để tối ưu kết nối và scale Multi-tenant.
    """
    if not supabase:
        return
        
    branch_id = os.environ.get("BRANCH_ID")
    if not branch_id:
        print("[!] Chú ý: Cần setup BRANCH_ID trong file .env để lắng nghe.")
        return
        
    while True:
        try:
            print(f"[*] Connecting to Supabase Realtime for branch {branch_id}...")
            
            # Khởi tạo kênh giao tiếp (Room)
            channel = supabase.channel(f"branch_{branch_id}_printers")
            
            def handle_insert(payload):
                try:
                    row = payload.get('record', {})
                    printer_id = row.get('printer_id')
                    
                    if printer_id in queues:
                        job = {
                            "id": str(row['id']),
                            "printer_id": printer_id,
                            "payload": row['payload']
                        }
                        queues[printer_id].put_nowait(job)
                except Exception as e:
                    print(f"[!] Error parsing realtime payload: {e}")

            # Đăng ký lắng nghe sự kiện INSERT trên bảng print_jobs và LỌC theo branch_id
            channel.on(
                "postgres_changes",
                {
                    "event": "INSERT",
                    "schema": "public",
                    "table": "print_jobs",
                    "filter": f"branch_id=eq.{branch_id}"
                },
                handle_insert
            ).subscribe()
            
            print("[*] Successfully subscribed to Realtime. Waiting for Print Jobs...")
            
            # Duy trì kết nối mãi mãi
            await asyncio.Future()
                
        except Exception as e:
            print(f"[!] Lỗi mất kết nối Realtime: {e}. Retry sau 5s...")
            await asyncio.sleep(5)
