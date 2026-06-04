from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base, sessionmaker
from fastapi.staticfiles import StaticFiles

app = FastAPI()

# static 설정  (Nginx static 먼저 처리할 경우 / fastApi 에서 이중으로 적용되지않음)
# 로컬(개발)환경 uvicorn 테스트를 위해 적용 이중으로 적용되지 않음)
app.mount("/static", StaticFiles(directory="static"), name="static")

# PostgreSQL 연결정보
#DATABASE_URL = "postgresql://eventuser:1234@localhost:5432/eventdb"
DATABASE_URL = "postgresql://eventuser:1234@172.16.8.201:5432/eventdb"

# DB 엔진 생성
engine = create_engine(DATABASE_URL)

# 세션 생성
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# ORM Base 
Base = declarative_base()

# 테이블 모델
class EventData(Base):
    __tablename__ = "event_data"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    receipt_no = Column(String(100), unique=True, nullable=False)
    result = Column(String(50), nullable=False)




# HTML Template 설정
templates = Jinja2Templates(directory="templates")
# 메인 페이지
@app.get("/")
async def home(request: Request):
    return templates.TemplateResponse(
        request=request,
        name="main_index.html"
    )


# 당첨조회 (비동기 조회 API)
@app.post("/check")
async def check_winner(data: dict):
    name = data.get("name")
    receipt_no = data.get("receipt_no")

    db = SessionLocal()

    try:
        user = db.query(EventData).filter(
            EventData.name == name,
            EventData.receipt_no == receipt_no
        ).first()

        if user:
            return {
                "success": True,
                "name": user.name,
                "receipt_no": user.receipt_no,
                "result": user.result
            }

        return {
            "success": False,
            "message": "조회 결과가 없습니다."
        }

    finally:
        db.close()