from pydantic import BaseModel


class DocumentResponse(BaseModel):
    file_id: str
    filename: str
    message: str


class QuestionRequest(BaseModel):
    file_id: str
    question: str


class QuestionResponse(BaseModel):
    question_id: str
    file_id: str
    question: str
    status: str


class AnswerResponse(BaseModel):
    question_id: str
    status: str
    question: str
    answer: str | None = None
    processing_time_ms: float | None = None
    message: str | None = None
    error: str | None = None
