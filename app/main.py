import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, UploadFile, File, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from app.models import (
    DocumentResponse,
    QuestionRequest,
    QuestionResponse,
    AnswerResponse,
)
from app.services.document_service import DocumentService
from app.services.llm_service import llm_service
from app.storage.documents import documents_store, questions_store

load_dotenv()


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="Document QA API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/upload", response_model=DocumentResponse)
async def upload_document(file: UploadFile = File(...)):
    file_id = await DocumentService.upload_document(file)
    return DocumentResponse(
        file_id=file_id, filename=file.filename, message="File uploaded successfully"
    )


@app.post("/ask", response_model=QuestionResponse)
async def ask_question(request: QuestionRequest, background_tasks: BackgroundTasks):
    if request.file_id not in documents_store:
        raise HTTPException(status_code=404, detail="File not found")

    question_id = str(uuid.uuid4())
    questions_store[question_id] = {
        "question_id": question_id,
        "file_id": request.file_id,
        "question": request.question,
        "status": "queued",
        "answer": None,
    }

    background_tasks.add_task(llm_service.process_question, question_id)

    return QuestionResponse(
        question_id=question_id,
        file_id=request.file_id,
        question=request.question,
        status="queued",
    )


@app.get("/answer/{question_id}", response_model=AnswerResponse)
async def get_answer(question_id: str):
    if question_id not in questions_store:
        raise HTTPException(status_code=404, detail="Question not found")

    data = questions_store[question_id]

    return AnswerResponse(
        question_id=question_id,
        status=data["status"],
        question=data["question"],
        answer=data.get("answer"),
        processing_time_ms=data.get("processing_time_ms"),
        error=data.get("error"),
    )


@app.get("/")
async def root():
    return {"message": "Document QA API is running"}
