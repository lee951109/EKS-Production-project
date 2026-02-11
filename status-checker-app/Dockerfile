
# 1. 베이스 이미지
FROM python:3.11-slim

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. 필요한 라이버리 목록 복사 및 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. 소스 코드 복사
COPY . .

# 5. 앱 실행 (8000 port)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]