import asyncio
from fastapi import FastAPI
from fastapi.responses import FileResponse
from printer_logic import queues, worker_loop, PRINTER_MAP
import database
from models import PrintJob
import dotenv
from pydantic import BaseModel

class PrinterConfig(BaseModel):
    id: str
    ip: str

async def check_printer_online(ip: str, port: int = 9100) -> bool:
    try:
        reader, writer = await asyncio.wait_for(asyncio.open_connection(ip, port), timeout=1.0)
        writer.close()
        await writer.wait_closed()
        return True
    except Exception:
        return False

app = FastAPI(title="F2TECH Local Print Server")

@app.on_event("startup")
async def startup_event():
    # 0. Khởi tạo Supabase Client (Thay thế cho DB Pool cũ)
    await database.init_supabase_client()
    
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
    return FileResponse("index.html")

@app.get("/status")
async def get_status():
    """
    Xem tình trạng hàng đợi hiện tại của các máy in
    """
    status = {}
    tasks = []
    pids = list(queues.keys())
    for pid in pids:
        ip = PRINTER_MAP.get(pid)
        tasks.append(check_printer_online(ip))
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    for i, pid in enumerate(pids):
        is_online = results[i] == True
        status[pid] = {
            "pending_jobs": queues[pid].qsize(),
            "ip": PRINTER_MAP.get(pid),
            "status": "online" if is_online else "offline"
        }
    return status

@app.get("/api/printers")
async def get_printers():
    return [{"id": pid, "ip": ip} for pid, ip in PRINTER_MAP.items()]

@app.post("/api/printers")
async def add_printer(config: PrinterConfig):
    pid = config.id.upper()
    PRINTER_MAP[pid] = config.ip
    dotenv.set_key(".env", f"PRINTER_{pid}", config.ip)
    
    if pid not in queues:
        queues[pid] = asyncio.Queue()
        asyncio.create_task(worker_loop(pid))
        
    return {"message": "Printer saved successfully"}

@app.delete("/api/printers/{pid}")
async def delete_printer(pid: str):
    pid = pid.upper()
    if pid in PRINTER_MAP:
        del PRINTER_MAP[pid]
        dotenv.unset_key(".env", f"PRINTER_{pid}")
        # Not deleting the queue to avoid breaking running workers immediately, but stopping them is complex.
    return {"message": "Printer deleted successfully"}

@app.post("/test-print/{ip}")
async def test_print(ip: str):
    """
    API nội bộ để Test bắn thử 1 lệnh in khống vào Queue
    """
    if ip not in queues:
        return {"error": "Unknown IP"}
        
    dummy_job = {
        "id": "test-123",
        "printer_ip": ip,
        "payload": {
            "type": "kitchen",
            "items": [{"name": "Test Mon Nuong", "quantity": 1}]
        }
    }
    
    await queues[ip].put(dummy_job)
    return {"message": f"Added test job to queue {ip}"}

@app.post("/print/receipt")
async def print_receipt(job: PrintJob):
    """
    Receives payload JSON Bill from POS Cloud -> prints Cashier invoice
    """
    if job.printer_id not in queues:
        return {"error": f"Unknown printer_id: {job.printer_id}"}
        
    job.payload.type = "receipt"
    await queues[job.printer_id].put(job.dict())
    return {"message": f"Added receipt job {job.id} to queue {job.printer_id}"}

@app.post("/print/kitchen")
async def print_kitchen(job: PrintJob):
    """
    Receives payload JSON Order/Void -> Prints Kitchen slip
    """
    if job.printer_id not in queues:
        return {"error": f"Unknown printer_id: {job.printer_id}"}
        
    job.payload.type = "kitchen"
    await queues[job.printer_id].put(job.dict())
    return {"message": f"Added kitchen job {job.id} to queue {job.printer_id}"}
