from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI(title="api", docs_url="/docs")


@app.get("/health")
async def health():
    return JSONResponse({"status": "ok"})


@app.get("/")
async def root():
    return {"message": "hello"}
