import asyncio
import asyncpg
import json
import os
import uuid
from dotenv import load_dotenv

load_dotenv()

async def test_insert():
    db_url = os.getenv('DATABASE_URL')
    
    # Kết nối Database
    conn = await asyncpg.connect(db_url)
    
    # Dữ liệu giả lập - Tái hiện việc Frontend tách Combo "Set Lau 2 Nguoi"
    printer_id = 'KITCHEN_HOT'
    order_id = str(uuid.uuid4())
    payload = {
        "type": "kitchen",
        "items": [
            {
                "name": "Lau Thai Tom Yum", 
                "quantity": 1, 
                "part_of_combo": "Set Lau 2 Nguoi",
                "note": "Khong cay"
            }
        ]
    }
    
    print(f"[*] Đang Insert bill mới vào Supabase cho {printer_id} (Order: {order_id})...")
    
    # Insert 1 row vào bảng print_jobs với order_id được tách riêng
    await conn.execute('''
        INSERT INTO print_jobs (order_id, printer_id, payload)
        VALUES ($1, $2, $3)
    ''', order_id, printer_id, json.dumps(payload))
    
    print("[+] Đã Insert thành công! Vui lòng kiểm tra màn hình log của FastAPI Server xem nó có nhận được LISTEN không.")
    
    await conn.close()

if __name__ == "__main__":
    asyncio.run(test_insert())
