# =============================================
# alert_handler.py
# AIOps 장애 탐지 및 옵션 추천 파이프라인
# =============================================

from fastapi import FastAPI, Request
from fastapi.concurrency import run_in_threadpool
from datetime import datetime
from google import genai
from collections import deque
from psycopg2 import pool as pg_pool
import os, re, json, requests, psycopg2, asyncio, sys

app = FastAPI()

# =============================================
# 환경변수 설정
# =============================================
GEMINI_API_KEY      = os.getenv("GEMINI_API_KEY")
DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")          # TODO [2] : 실제 프로젝트 적용 시 팀 Discord 알림 채널 웹훅 URL로 변경

# TODO [1] : 실제 프로젝트 적용 시
# docker-compose.yml volumes 에서
# EC2 실제 로그 파일 경로로 변경
# 예) /var/log/nginx/error.log:/app/nginx.log
LOG_FILE = "/app/sample.log"   # 현재: 테스트용 가짜 로그

# 서버 시작 시 환경변수 체크
if not GEMINI_API_KEY:
    print(" 오류: GEMINI_API_KEY 환경변수가 설정되지 않았습니다.")
    sys.exit(1)

if not DISCORD_WEBHOOK_URL:
    print(" 오류: DISCORD_WEBHOOK_URL 환경변수가 설정되지 않았습니다.")
    sys.exit(1)

# Gemini 연결
GEMINI_MODEL = "gemini-2.5-flash"

client = genai.Client(api_key=GEMINI_API_KEY)

# =============================================
# DB 설정
# TODO [3] : 실제 프로젝트 적용 시
# VM2 실제 IP, DB 이름, 계정 정보로 변경
# =============================================
DB_CONFIG = {
    "host":     "172.16.8.230",  # TODO: VM2 실제 IP로 변경
    "port":     "5432",
    "dbname":   "logsdb",        # TODO: 팀 DB 이름으로 변경
    "user":     "loguser",       # TODO: 실제 DB 계정으로 변경
    "password": "password"       # TODO: 실제 DB 비밀번호로 변경
}

db_connection_pool = None

# =============================================
# DB 초기화 함수
# 서버 시작 시 테이블 자동 생성
# CREATE TABLE IF NOT EXISTS → 이미 있으면 그냥 넘어감
# 성공 시 True, 실패 시 False 반환
# =============================================
def init_db():
    global db_connection_pool
    try:
        db_connection_pool = pg_pool.SimpleConnectionPool(
            minconn=1,
            maxconn=5,
            **DB_CONFIG
        )
        print(" DB 연결 풀 생성 완료 (최소 1개, 최대 5개)")

        conn = db_connection_pool.getconn()
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS aiops_logs (
                    id             SERIAL PRIMARY KEY,
                    alert_name     TEXT,
                    instance       TEXT,
                    cause          TEXT,
                    severity       TEXT,
                    recommendation TEXT,
                    runbook        TEXT,
                    created_at     TIMESTAMP DEFAULT NOW()
                )
            """)
        conn.commit()
        db_connection_pool.putconn(conn)
        print("✅ DB 테이블 확인 완료")
        return True

    except Exception as e:
        print(f" DB 초기화 실패 (DB 연결 안 됨): {e}")
        print(" DB 없이 서버 계속 실행합니다.")
        db_connection_pool = None
        return False

# =============================================
# DB 재연결 백그라운드 태스크
# DB 없이 시작 시 30초마다 재시도
# 연결 성공하면 자동 종료
# =============================================
async def retry_db_connection():
    while db_connection_pool is None:
        print(" DB 재연결 시도 중... (30초 대기)")
        await asyncio.sleep(30)
        success = await run_in_threadpool(init_db)
        if success:
            print("✅ DB 재연결 성공!")
            break

# =============================================
# FastAPI 시작 시 자동 실행
# 서버 켜지면 init_db() 자동 호출
# DB 없으면 백그라운드에서 계속 재시도
# =============================================
@app.on_event("startup")
async def startup_event():
    print(" 서버 시작 중...")
    success = await run_in_threadpool(init_db)
    if not success:
        print(" DB 없이 시작 → 백그라운드에서 계속 재시도")
        asyncio.create_task(retry_db_connection())
    print(" 서버 준비 완료")

# =============================================
# 1. 로그 수집 함수
# deque 사용: 대용량 파일도 메모리 안전하게 처리
# =============================================
def get_logs():
    try:
        with open(LOG_FILE, "r") as f:
            last_100 = deque(f, maxlen=100)
            return "".join(last_100)
    except FileNotFoundError:
        return "로그 파일 없음"

# =============================================
# 2. 마스킹 함수
# =============================================
def mask_pii(text: str) -> str:
    # IP 주소
    text = re.sub(
        r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b',
        '[MASKED_IP]', text
    )
    # 이메일
    text = re.sub(
        r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
        '[MASKED_EMAIL]', text
    )
    # 패스워드
    text = re.sub(
        r'(?i)(password|passwd|pwd)\s*=\s*\S+',
        r'\1=[MASKED]', text
    )
    # API 키
    text = re.sub(
        r'(?i)(api_key|apikey|gemini_api_key|aws_access_key|secret_key)\s*=\s*\S+',
        r'\1=[MASKED]', text
    )
    # DB 접속정보
    text = re.sub(
        r'(postgresql|mysql|mongodb)://[^\s]+',
        r'\1://[MASKED]', text
    )
    # AWS 키
    text = re.sub(
        r'AKIA[0-9A-Z]{16}',
        '[MASKED_AWS_KEY]', text
    )
    # JWT 토큰
    text = re.sub(
        r'eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+',
        '[MASKED_JWT]', text
    )
    return text

# =============================================
# 3. Gemini 분석 함수
# =============================================
async def analyze_with_gemini(masked_log: str, alerts_summary: str) -> dict:

    # TODO [4] : 실제 프로젝트 적용 시
    # 팀에서 확정된 런북 파일명으로 변경
    runbook_list = """
- runbook-scale-out.yml   : CPU/메모리 과부하, 트래픽 폭증 시 EC2 추가
- runbook-db-restart.yml  : DB 연결 실패, DB 오류 발생 시 DB 재시작
- runbook-rollback.yml    : 배포 후 에러 급증 시 이전 버전으로 롤백
"""

    prompt = f"""
당신은 클라우드 인프라 장애 분석 전문가입니다.

[발생한 알람 목록]
{alerts_summary}

[서버 에러 로그]
{masked_log}

[사용 가능한 런북 목록]
{runbook_list}

위 내용을 종합 분석하고 런북 목록 중 하나를 선택해서
반드시 아래 JSON 형식으로만 답변하세요.
다른 말은 절대 하지 마세요. JSON만 출력하세요.

{{
  "cause": "장애 원인 한 줄 요약",
  "severity": "낮음 또는 중간 또는 높음",
  "recommendation": "A 또는 B 또는 C",
  "recommendation_reason": "추천 이유 한 줄",
  "actions": ["즉시 조치 1", "즉시 조치 2", "즉시 조치 3"],
  "runbook": "런북 목록에서 선택한 파일명"
}}

스케일링 옵션:
A = 현상유지
B = 보수적 (인스턴스 1대 추가)
C = 공격적 (최대치 즉시 확장)
"""

    max_retry    = 5
    wait_seconds = 15

    for attempt in range(max_retry):
        try:
            print(f"   Gemini 요청 중... (시도 {attempt + 1}/{max_retry})")

            response = client.models.generate_content(
                model=GEMINI_MODEL,
                contents=prompt
            )

            raw = response.text.strip()
            raw = raw.replace("```json", "").replace("```", "").strip()

            try:
                return json.loads(raw)
            except json.JSONDecodeError:
                return {
                    "cause": raw,
                    "severity": "알 수 없음",
                    "recommendation": "알 수 없음",
                    "runbook": "알 수 없음",
                    "actions": [],
                    "recommendation_reason": ""
                }

        except Exception as e:
            print(f"   ⚠️ Gemini 오류: {e}")
            if attempt < max_retry - 1:
                print(f"   {wait_seconds}초 후 재시도...")
                await asyncio.sleep(wait_seconds)
                wait_seconds *= 2
            else:
                print("    최대 재시도 횟수 초과")
                return {
                    "cause": "Gemini 분석 실패 (서버 오류)",
                    "severity": "알 수 없음",
                    "recommendation": "알 수 없음",
                    "runbook": "알 수 없음",
                    "actions": ["수동으로 로그 확인 필요"],
                    "recommendation_reason": "AI 분석 불가"
                }

# =============================================
# 4. Discord 전송 함수
# TODO [5] : 실제 프로젝트 적용 시
# 팀 Discord 알림 채널 웹훅 URL로 변경
# 현재: 개인 테스트 채널
# =============================================
def send_discord(result: dict, alert_names: str, instances: str):

    color_map = {"높음": 0xFF0000, "중간": 0xFF8C00, "낮음": 0x00FF00}
    color = color_map.get(result.get("severity", ""), 0x5865F2)
    now   = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    actions_text = "\n".join(
        [f"{i+1}. {a}" for i, a in enumerate(result.get("actions", []))]
    )

    payload = {
        "username": "AIOps 분석 봇 🤖",
        "embeds": [{
            "title": f"⚠️ 장애 감지 — {alert_names}",
            "color": color,
            "fields": [
                {"name": "서버",      "value": instances,                               "inline": True},
                {"name": "감지 시각", "value": now,                                     "inline": True},
                {"name": "장애 원인", "value": result.get("cause", "알 수 없음"),       "inline": False},
                {"name": "심각도",    "value": result.get("severity", ""),              "inline": True},
                {"name": "추천 대응", "value": result.get("recommendation", ""),        "inline": True},
                {"name": "추천 이유", "value": result.get("recommendation_reason", ""), "inline": False},
                {"name": "즉시 조치", "value": actions_text,                            "inline": False},
                {"name": "추천 런북", "value": result.get("runbook", ""),               "inline": False},
            ],
            "footer": {"text": "Privacy AIOps · 로그는 마스킹 처리 후 AI 분석됨"}
        }]
    }

    res = requests.post(DISCORD_WEBHOOK_URL, json=payload)
    if res.status_code == 204:
        print("✅ Discord 전송 성공")
    else:
        print(f"❌ Discord 전송 실패: {res.status_code}")

# =============================================
# 5. DB 저장 함수
# 연결 풀 사용 + finally로 반납 보장
# run_in_threadpool: 동기 psycopg2를 비동기로 실행
# =============================================
def save_to_db(result: dict, alert_name: str, instance: str):
    if db_connection_pool is None:
        print("⚠️ DB 연결 풀 없음 - 저장 건너뜀")
        return

    conn = None
    try:
        conn = db_connection_pool.getconn()
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO aiops_logs (
                    alert_name, instance, cause,
                    severity, recommendation, runbook, created_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, NOW())
            """, (
                alert_name,
                instance,
                result.get("cause", ""),
                result.get("severity", ""),
                result.get("recommendation", ""),
                result.get("runbook", "")
            ))
        conn.commit()
        print("✅ DB 저장 완료")
    except Exception as e:
        print(f"❌ DB 저장 실패: {e}")
    finally:
        if conn:
            db_connection_pool.putconn(conn)

# =============================================
# 6. 메인 엔드포인트
# TODO [6] : 실제 프로젝트 적용 시
# AlertManager 설정에 아래 URL 등록 필요
# url: "http://VM1_IP:8000/alert"
# alertmanager.yml 에 추가
# =============================================
@app.post("/alert")
async def receive_alert(request: Request):

    data = await request.json()
    now  = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    print("\n" + "="*50)
    print(f"[{now}] 알림 수신!")
    print("="*50)

    alerts = data.get("alerts", [])

    if not alerts:
        return {"status": "no alerts", "count": 0}

    alert_names    = ", ".join([a["labels"].get("alertname", "unknown") for a in alerts])
    instances      = ", ".join([a["labels"].get("instance",   "unknown") for a in alerts])
    alerts_summary = "\n".join([
        f"- {a['labels'].get('alertname')} | {a['labels'].get('instance')} | {a['annotations'].get('summary', '')}"
        for a in alerts
    ])

    # =============================================
    # 우선순위 결정
    # AlertManager severity 기준으로 처리 방식 분기
    # critical → Gemini + Discord + DB
    # warning  → Discord + DB
    # 기타     → DB만
    # =============================================
    severities = [a["labels"].get("severity", "unknown").lower() for a in alerts]

    if "critical" in severities:
        priority = "critical"
    elif "warning" in severities:
        priority = "warning"
    else:
        priority = "low"

    print(f"장애 수  : {len(alerts)}건")
    print(f"장애명   : {alert_names}")
    print(f"서버     : {instances}")
    print(f"우선순위 : {priority}")
    print("-"*50)

    # 1. 로그 수집
    print("① 로그 수집 중...")
    raw_logs = get_logs()

    # 2. 마스킹
    print("② 마스킹 중...")
    masked_logs = mask_pii(raw_logs)

    # =============================================
    # 우선순위별 처리
    # =============================================
    if priority == "critical":
        # CRITICAL → Gemini 분석 + Discord + DB
        print("③ Gemini 분석 중... (CRITICAL 알람)")
        result = await analyze_with_gemini(masked_logs, alerts_summary)
        print(f"   장애 원인 : {result.get('cause')}")
        print(f"   심각도    : {result.get('severity')}")
        print(f"   추천 런북 : {result.get('runbook')}")

        print("④ Discord 전송 중...")
        send_discord(result, alert_names, instances)

        print("⑤ DB 저장 중...")
        await run_in_threadpool(save_to_db, result, alert_names, instances)

    elif priority == "warning":
        # WARNING → Discord + DB (Gemini 호출 안 함)
        print("③ Gemini 생략 (WARNING 알람)")
        result = {
            "cause": "WARNING 수준 알람 - 상세 분석 생략",
            "severity": "중간",
            "recommendation": "B",
            "recommendation_reason": "WARNING 알람 모니터링 필요",
            "actions": ["로그 확인", "모니터링 강화", "추이 관찰"],
            "runbook": "없음"
        }

        print("④ Discord 전송 중...")
        send_discord(result, alert_names, instances)

        print("⑤ DB 저장 중...")
        await run_in_threadpool(save_to_db, result, alert_names, instances)

    else:
        # 기타 → DB만 저장
        print("③ Gemini 생략 (낮은 우선순위)")
        print("④ Discord 생략 (낮은 우선순위)")
        result = {
            "cause": "낮은 우선순위 알람",
            "severity": "낮음",
            "recommendation": "A",
            "recommendation_reason": "모니터링만 필요",
            "actions": ["로그 확인"],
            "runbook": "없음"
        }
        print("⑤ DB 저장 중...")
        await run_in_threadpool(save_to_db, result, alert_names, instances)

    print("="*50)

    return {"status": "received", "count": len(alerts), "priority": priority}