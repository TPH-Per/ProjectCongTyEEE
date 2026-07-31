from pydantic import BaseModel
from typing import List, Optional

class ReceiptItem(BaseModel):
    name: str
    quantity: float
    price: int
    total: int

class ReceiptPayload(BaseModel):
    order_number: str
    table_name: str
    cashier_name: str
    items: List[ReceiptItem]
    subtotal: int
    discount: int
    total: int
    created_at: str

class KitchenItem(BaseModel):
    name: str
    quantity: float
    note: Optional[str] = ""
    is_buffet_package: bool = False
    parent_package_name: Optional[str] = None

class KitchenPayload(BaseModel):
    order_number: str
    table_name: str
    items: List[KitchenItem]
    is_void: bool = False
    reason: Optional[str] = ""
