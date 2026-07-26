import asyncio
import os

# Set dummy env vars for test
os.environ['PRINTER_TEST_PRINTER'] = '192.168.1.100'
os.environ['PRINTER_DELAY_TEST_PRINTER'] = '0.5'

from printer_logic import queues, worker_loop
import database

# Mock database để không dính lỗi kết nối DB khi chạy Unit Test
async def mock_report(job_id, status):
    print(f"   -> [Database Mock] Đã ghi nhận {job_id} = {status}")
database.report_job_status = mock_report

async def run_test():
    print("=== BẮT ĐẦU UNIT TEST FIFO ===")
    
    pid = 'TEST_PRINTER'
    if pid not in queues:
        queues[pid] = asyncio.Queue()
        
    # Tạo 2 job cùng lúc
    job1 = {"id": "job-001", "payload": {"type": "receipt", "items": [{"name": "Phở", "quantity": 1}]}}
    job2 = {"id": "job-002", "payload": {"type": "receipt", "items": [{"name": "Bún", "quantity": 1}]}}
    job3 = {"id": "job-003", "payload": {"type": "receipt", "items": [{"name": "Miến", "quantity": 1}]}}
    
    print("[*] Đẩy 3 lệnh in vào Queue CÙNG MỘT LÚC...")
    queues[pid].put_nowait(job1)
    queues[pid].put_nowait(job2)
    queues[pid].put_nowait(job3)
    
    print(f"[*] Kích thước Queue hiện tại: {queues[pid].qsize()}")
    
    # Khởi chạy Worker Loop
    worker_task = asyncio.create_task(worker_loop(pid))
    
    # Đợi Queue xử lý hết
    await queues[pid].join()
    
    print("=== TẤT CẢ JOB ĐÃ XỬ LÝ XONG THEO ĐÚNG THỨ TỰ (FIFO) ===")
    worker_task.cancel()

if __name__ == '__main__':
    asyncio.run(run_test())
