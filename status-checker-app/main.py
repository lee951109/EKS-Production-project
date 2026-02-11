from fastapi import FastAPI
import os
import socket
import datetime

app = FastAPI()

@app.get("/")
def read_root():
    # 1. 호스트네임 (현재 입이 돌아가는 Pod의 이름)
    pod_name = socket.gethostname()
    # 2. 현재 시간
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    return {
        "message": "Cloud-Native Status Checker is Running",
        "pod_name": pod_name,
        "timestamp": now,
        "status": "Healthy"
    }

@app.get("/health")
def health_check():
    # 쿠버네티스가 이 앱이 살아있는지 확인할 때 사용
    return {"status": "UP"}

app.get("/env")
def read_env():
    # 환경 변수가 잘 주입되었는지 확인하는 기능 (보안상 중요한 건 제외)
    project_name = os.getenv("PROJECT_NAME", "Unknown")
    return {
        "project_name": project_name,
        "environment": os.getenv("APP_ENV", "Development")
    }

