# Python 3.11 사용 (3.9 버전 문제 해결)
FROM python:3.11-slim

# 시간대 설정 (한국 시간 KST)
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 작업 디렉토리 설정
WORKDIR /app

# 라이브러리 먼저 설치 (캐시 활용)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 코드 복사
COPY alert_handler.py .
COPY sample.log .           
# 테스트 용 로그파일 

# 8000번 포트 열기
EXPOSE 8000

# 서버 실행
CMD ["uvicorn", "alert_handler:app", "--host", "0.0.0.0", "--port", "8000"]