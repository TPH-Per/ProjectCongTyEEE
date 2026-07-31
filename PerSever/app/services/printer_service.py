import os
from escpos.printer import Network
from ..models.schemas import ReceiptPayload, KitchenPayload
import logging

logger = logging.getLogger(__name__)

import sys

# Fallback dummy printer for testing without real hardware
class DummyPrinter:
    def __init__(self, ip):
        self.ip = ip
        logger.info(f"DummyPrinter initialized for IP: {ip}")
    def hw(self, cmd):
        pass
    def set(self, **kwargs):
        pass
    def text(self, txt):
        sys.stdout.buffer.write(txt.encode('utf-8', errors='replace'))
        sys.stdout.buffer.flush()
    def cut(self):
        sys.stdout.buffer.write("\n--- CUT ---\n".encode('utf-8'))
        sys.stdout.buffer.flush()

def get_printer(ip_env_var: str):
    ip = os.getenv(ip_env_var)
    if not ip:
        raise ValueError(f"Printer IP not configured for {ip_env_var}")
    
    use_dummy = os.getenv("USE_DUMMY_PRINTER", "False").lower() == "true"
    if use_dummy:
        logger.info(f"Using DummyPrinter for {ip} as requested by USE_DUMMY_PRINTER")
        return DummyPrinter(ip)
    
    try:
        # 9100 is the default port for thermal printers
        return Network(ip, timeout=2)
    except Exception as e:
        logger.warning(f"Could not connect to printer at {ip}: {e}. Using DummyPrinter.")
        return DummyPrinter(ip)

def print_receipt(payload: ReceiptPayload):
    printer = get_printer("PRINTER_RECEIPT")
    
    printer.hw("INIT")
    printer.set(align='center', bold=True, double_height=True, double_width=True)
    printer.text("F2TECH RESTAURANT\n")
    printer.set(align='center', bold=False, double_height=False, double_width=False)
    printer.text("Receipt\n")
    printer.text("--------------------------------\n")
    
    printer.set(align='left')
    printer.text(f"Table: {payload.table_name}\n")
    printer.text(f"Order: {payload.order_number}\n")
    printer.text(f"Cashier: {payload.cashier_name}\n")
    printer.text(f"Date: {payload.created_at}\n")
    printer.text("--------------------------------\n")
    
    for item in payload.items:
        printer.text(f"{item.name}\n")
        printer.text(f"  {item.quantity} x {item.price:,} = {item.total:,}\n")
        
    printer.text("--------------------------------\n")
    printer.set(align='right')
    printer.text(f"Subtotal: {payload.subtotal:,}\n")
    if payload.discount > 0:
        printer.text(f"Discount: -{payload.discount:,}\n")
    printer.set(bold=True)
    printer.text(f"TOTAL: {payload.total:,} VND\n")
    
    printer.cut()
    return {"status": "success", "printer": os.getenv("PRINTER_RECEIPT")}

def print_kitchen_slip(payload: KitchenPayload):
    printer = get_printer("PRINTER_KITCHEN_HOT")
    
    printer.hw("INIT")
    if payload.is_void:
        printer.set(align='center', bold=True, double_height=True, double_width=True)
        printer.text("*** VOID / CANCEL ***\n")
        if payload.reason:
            printer.set(align='center', bold=False, double_height=False, double_width=False)
            printer.text(f"Reason: {payload.reason}\n")
    
    printer.set(align='center', bold=True, double_height=True, double_width=False)
    printer.text(f"TABLE: {payload.table_name}\n")
    printer.set(align='center', bold=False, double_height=False)
    printer.text(f"Order: {payload.order_number}\n")
    printer.text("--------------------------------\n")
    
    printer.set(align='left')
    
    for item in payload.items:
        if item.parent_package_name:
            printer.set(bold=True)
            printer.text(f"[{item.parent_package_name}]\n")
            printer.set(bold=False)
        
        if item.is_buffet_package:
            # Bold for buffet package
            printer.set(bold=True, double_height=True)
            printer.text(f"{item.quantity} x {item.name}\n")
            printer.set(bold=False, double_height=False)
        else:
            printer.text(f"{item.quantity} x {item.name}\n")
            
        if item.note:
            printer.text(f"  **Note: {item.note}\n")
            
    # Beeper
    printer.text("\x1B\x42\x05\x02") # ESC B 5 2 (beep 5 times)
    printer.cut()
    
    return {"status": "success", "printer": os.getenv("PRINTER_KITCHEN_HOT")}
