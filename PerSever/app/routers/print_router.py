from fastapi import APIRouter, HTTPException
from ..models.schemas import ReceiptPayload, KitchenPayload
from ..services.printer_service import print_receipt, print_kitchen_slip

router = APIRouter()

@router.post("/receipt")
def api_print_receipt(payload: ReceiptPayload):
    try:
        result = print_receipt(payload)
        return {"success": True, "message": "Receipt printed successfully", "details": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/kitchen")
def api_print_kitchen(payload: KitchenPayload):
    try:
        result = print_kitchen_slip(payload)
        return {"success": True, "message": "Kitchen slip printed successfully", "details": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
