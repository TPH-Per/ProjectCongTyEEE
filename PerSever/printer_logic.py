import asyncio
import os
from dotenv import load_dotenv
try:
    from escpos.printer import Network
except ImportError:
    Network = None

load_dotenv()

# Tạo Queue động (Config-driven): Quét file .env, 
# Cứ biến nào bắt đầu bằng PRINTER_ thì lấy làm ID và cấp cho nó 1 Queue
PRINTER_MAP = {}
PRINTER_DELAYS = {}
queues = {}

# Idempotency Cache: Lưu 1000 ID gần nhất đã xử lý để tránh in đúp (Double print)
from collections import deque
processed_jobs_cache = deque(maxlen=1000)

for key, ip in os.environ.items():
    if key.startswith("PRINTER_") and not key.startswith("PRINTER_DELAY_"):
        # Cắt chữ "PRINTER_" đi, chỉ giữ lại phần ID (VD: KITCHEN_HOT)
        printer_id = key.replace("PRINTER_", "") 
        PRINTER_MAP[printer_id] = ip
        # Đọc cấu hình Delay tương ứng, mặc định 2s nếu không cấu hình
        delay = float(os.getenv(f"PRINTER_DELAY_{printer_id}", 2.0))
        PRINTER_DELAYS[printer_id] = delay
        
        queues[printer_id] = asyncio.Queue()

print(f"[*] Da load {len(queues)} may in tu Config:")
for pid in queues.keys():
    print(f"    - {pid}: IP={PRINTER_MAP[pid]} | Delay={PRINTER_DELAYS[pid]}s")

def print_to_hardware(printer_id: str, payload: dict):
    """
    TCP Client: Kết nối Socket tới Port 9100 của máy in Zywell/XPrinter
    Sử dụng giao thức ESC/POS để ra lệnh in vật lý.
    """
    ip = PRINTER_MAP.get(printer_id)
    if not ip:
        raise Exception(f"Không tìm thấy cấu hình IP cho máy in {printer_id}")
        
    try:
        # 1. Mở kết nối TCP (Socket) tới Port 9100. Timeout 5s để không treo hệ thống
        # profile="TM-T88V" là profile chuẩn tương thích hầu hết máy in nhiệt
        printer = Network(host=ip, port=9100, timeout=5, profile="TM-T88V")
        
        # 2. Xử lý Encoding Tiếng Việt (Rất quan trọng)
        # Đa số máy in nhiệt Tàu cần set codepage để in ra tiếng Việt không bị lỗi font
        # Tùy máy in mà có thể là cp1258, vni, hoặc hỗ trợ UTF-8 native.
        # Ở đây em ví dụ chuẩn Unicode chung:
        printer.charcode(code='AUTO') 
        
        job_type = payload.get('type', 'kitchen')
        
        # 3. In Header (Tiêu đề)
        printer.set(align='center', bold=True, double_height=True, double_width=True)
        if job_type == 'kitchen':
            printer.text("== PHIEU CHE BIEN ==\n\n")
        else:
            printer.text("== F2TECH RESTAURANT ==\n")
            printer.set(align='center', bold=False, double_height=False, double_width=False)
            printer.text("123 Nguyen Van Linh, Da Nang\n\n")
            printer.set(align='center', bold=True, double_height=True, double_width=True)
            printer.text("HOA DON THANH TOAN\n\n")
            
        # 4. In thông tin Order / Bàn (nếu có)
        printer.set(align='left', bold=True, normal=True)
        # Giả sử Frontend có truyền table_name xuống
        if payload.get('table_name'):
            printer.text(f"BAN: {payload['table_name']}\n")
        
        # 5. In dải phân cách
        printer.set(align='left', bold=False, normal=True)
        printer.text("-" * 32 + "\n")
        
        # 6. Lặp qua từng Item và in
        items = payload.get('items', [])
        
        if job_type == 'kitchen':
            parent_groups = {} 
            standalone_items = []
            
            for item in items:
                poc = item.get('part_of_combo')
                if poc:
                    if poc not in parent_groups:
                        parent_groups[poc] = []
                    parent_groups[poc].append(item)
                else:
                    standalone_items.append(item)
                    
            for poc, children in parent_groups.items():
                parent_item = None
                for i, item in enumerate(standalone_items):
                    if item.get('name') == poc:
                        parent_item = standalone_items.pop(i)
                        break
                        
                if parent_item:
                    p_qty = parent_item.get('quantity', 1)
                    p_note = parent_item.get('note', '')
                    printer.set(bold=True, double_height=True)
                    printer.text(f"{p_qty} x {poc}\n")
                    printer.set(bold=False, double_height=False)
                    if p_note:
                        printer.text(f"   LUU Y: *{p_note}*\n")
                else:
                    printer.set(bold=True, double_height=True)
                    printer.text(f"[BUFFET] {poc}\n")
                    printer.set(bold=False, double_height=False)
                
                for child in children:
                    try:
                        c_qty = int(child.get('quantity', 1))
                    except (ValueError, TypeError):
                        c_qty = 1
                    c_name = child.get('name', 'Unknown')
                    c_note = child.get('note', '')
                    
                    if c_qty > 0:
                        for _ in range(c_qty):
                            printer.set(bold=True)
                            printer.text(f"  - 1 x {c_name}\n")
                            printer.set(bold=False)
                            if c_note:
                                printer.text(f"      *{c_note}*\n")
                            
            for item in standalone_items:
                qty = item.get('quantity', 1)
                name = item.get('name', 'Unknown')
                note = item.get('note', '')
                printer.set(bold=True, double_height=True)
                printer.text(f"{qty} x {name}\n")
                printer.set(bold=False, double_height=False)
                if note:
                    printer.text(f"   LUU Y: *{note}*\n")
                    
        else:
            for item in items:
                qty = item.get('quantity', 1)
                name = item.get('name', 'Unknown')
                note = item.get('note', '')
                part_of_combo = item.get('part_of_combo', None)
                price = item.get('price', 0)
                
                line = f"{qty} x {name}"
                price_str = f"{price:,.0f}d"
                padding = 48 - len(line) - len(price_str)
                if padding > 0:
                    printer.text(f"{line}{' ' * padding}{price_str}\n")
                else:
                    printer.text(f"{line}\n{price_str:>48}\n")
                    
                if part_of_combo:
                    printer.text(f"   (Phan cua Combo: {part_of_combo})\n")
                if note:
                    printer.text(f"   LUU Y: *{note}*\n")
                
        printer.text("-" * 32 + "\n\n")
        
        # 7. Lệnh phần cứng đặc biệt
        if job_type == 'receipt':
            # Nếu là bill thanh toán -> Đá két đựng tiền (Kick Cash Drawer)
            printer.cashdraw(2)
        
        # Cắt giấy (Cut paper) và đóng kết nối TCP
        printer.cut()
        printer.close()
        
    except Exception as e:
        print(f"[LỖI KẾT NỐI MÁY IN - {printer_id} - IP: {ip}] {str(e)}")
        # Bắn Exception để vòng lặp Worker_loop catch được và bắt đầu đếm Retry
        raise e

async def worker_loop(printer_id: str):
    """
    FIFO Consumer: Hàng đợi First-In First-Out. Ai vào trước in trước.
    Mỗi máy in có 1 Worker Loop độc lập chạy ngầm vòng đời vô tận.
    """
    # Import locally để tránh Circular Import
    import database
    
    ip = PRINTER_MAP.get(printer_id)
    delay = PRINTER_DELAYS.get(printer_id, 2.0)
    print(f"[*] Started FIFO Consumer for {printer_id} ({ip}) - Delay: {delay}s")
    
    while True:
        job = await queues[printer_id].get()
        job_id = job.get('id')
        
        # [Phase 4] Idempotency check: Tránh in đúp
        if job_id in processed_jobs_cache:
            print(f"[{printer_id}] Bỏ qua job {job_id} vì đã in rồi (Idempotency Check).")
            queues[printer_id].task_done()
            continue
            
        print(f"[{printer_id}] Processing Job: {job_id}")
        
        retry_count = 0
        max_retries = 3
        success = False
        
        while retry_count < max_retries and not success:
            try:
                # 2. [PROCESS] - Đẩy lệnh xuống máy in vật lý
                # print_to_hardware(printer_id, job['payload']) # Bỏ comment khi có máy in thật
                
                print(f"[{printer_id}] Đang in... (Giả lập delay cắt giấy {delay}s)")
                await asyncio.sleep(delay) # Delay cấu hình theo model máy in
                
                success = True
                print(f"[{printer_id}] ✅ IN THÀNH CÔNG: {job_id}")
                
                # Ghi nhận cache và update DB
                processed_jobs_cache.append(job_id)
                await database.report_job_status(job_id, 'completed')
                
            except Exception as e:
                retry_count += 1
                print(f"[{printer_id}] ❌ Lỗi in ấn (Thử lại {retry_count}/{max_retries}): {e}")
                await asyncio.sleep(3) 
                
        if not success:
            print(f"[{printer_id}] ☠️ BỎ QUA JOB {job_id} SAU {max_retries} LẦN THẤT BẠI. (Dead-letter)")
            processed_jobs_cache.append(job_id)
            await database.report_job_status(job_id, 'failed')
            
        queues[printer_id].task_done()
