from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
import numpy as np
import cv2
from ocr_engine import OCREngine

app = FastAPI()

# Initialize the engine once
ocr = OCREngine()

# --- ADD THIS NEW BLOCK ---
@app.get("/")
def home():
    return {"message": "Server is running! Use /scan endpoint to upload images."}
# --------------------------~~

@app.post("/scan")
async def scan(file: UploadFile = File(...)):
    # --- FIX STARTS HERE ---
    
    # 1. Read the raw bytes from the uploaded file
    file_bytes = await file.read()
    
    # 2. Convert bytes to a NumPy array (this is the buffer)
    nparr = np.frombuffer(file_bytes, np.uint8)
    
    # 3. Decode the NumPy array into an actual image (THIS defines numpy_image)
    numpy_image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # --- FIX ENDS HERE ---

    # Now 'numpy_image' actually exists and can be passed to the engine
    result = ocr.scan_image(numpy_image)
    
    return JSONResponse(content=result["data"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)