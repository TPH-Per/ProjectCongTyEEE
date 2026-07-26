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
    table_name: Optional[str] = None

class PrintJob(BaseModel):
    id: str
    order_id: Optional[str] = None
    branch_id: Optional[str] = None
    printer_id: str
    payload: PrintPayload
