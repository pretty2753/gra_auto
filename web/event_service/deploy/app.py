from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base, sessionmaker

app = FastAPI()

# SQLite 설정
DATABASE_URL = "sqlite:///./event.db"

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(bind=engine)

Base = declarative_base()

# DB 모델
class Winner(Base):
    __tablename__ = "winners"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    receipt_no = Column(String, nullable=False, unique=True)
    result = Column(String, nullable=False)

# 테이블 생성
Base.metadata.create_all(bind=engine)

# 샘플 데이터 삽입
def init_data():
    db = SessionLocal()

    if db.query(Winner).count() == 0:
        sample_data = [
            Winner(name="홍길동", receipt_no="A001", result="당첨"),
            Winner(name="김철수", receipt_no="A002", result="미당첨"),
            Winner(name="이영희", receipt_no="A003", result="당첨"),
        ]

        db.add_all(sample_data)
        db.commit()

    db.close()

init_data()

templates = Jinja2Templates(directory="templates")

# 메인 페이지
@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    return templates.TemplateResponse(
        "index.html",
        {"request": request}
    )

# 비동기 조회 API
@app.post("/check")
async def check_winner(data: dict):
    name = data.get("name")
    receipt_no = data.get("receipt_no")

    db = SessionLocal()

    user = db.query(Winner).filter(
        Winner.name == name,
        Winner.receipt_no == receipt_no
    ).first()

    db.close()

    if user:
        return JSONResponse({
            "success": True,
            "name": user.name,
            "receipt_no": user.receipt_no,
            "result": user.result
        })

    return JSONResponse({
        "success": False,
        "message": "조회 결과가 없습니다."
    })