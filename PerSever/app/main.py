from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import print_router
import os
from dotenv import load_dotenv
import logging

logging.basicConfig(level=logging.INFO)
load_dotenv()

app = FastAPI(title="F2TECH Local Print Server", version="1.0.0")

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For local network access
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(print_router.router, prefix="/print", tags=["Printer"])

@app.get("/")
def read_root():
    return {"status": "ok", "message": "F2TECH Print Server is running"}

if __name__ == "__main__":
    import uvicorn
    # Start the server on static IP or 0.0.0.0 port 8000
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
