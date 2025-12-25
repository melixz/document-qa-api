import os
from datetime import datetime

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

from app.storage.documents import questions_store, documents_store


llm_service = None


class LLMService:
    def __init__(self):
        self.provider = os.getenv("LLM_PROVIDER", "google").lower()
        self.api_key = os.getenv("API_KEY")
        self.llm_base_url = os.getenv("LLM_BASE_URL", "http://localhost:11434/v1")
        self.model_name = os.getenv("LLM_MODEL_NAME", "gemini-2.5-flash")

        self.llm = self._initialize_llm()

        if self.llm:
            self.prompt = ChatPromptTemplate.from_template(
                """Answer the question based ONLY on the following context.
Provide the answer in PLAIN TEXT format without any markdown formatting (no asterisks, no bullet points, no bold text).
Use simple text with line breaks for lists if needed.

Context:
{context}

Question:
{question}

Answer:"""
            )
            self.chain = self.prompt | self.llm | StrOutputParser()
        else:
            self.chain = None

    def _initialize_llm(self):
        if self.provider == "google":
            if not self.api_key:
                return None
            return ChatGoogleGenerativeAI(
                model=self.model_name,
                google_api_key=self.api_key,
                temperature=0.3,
            )
        elif self.provider == "qwen":
            api_key = self.api_key if self.api_key else "dummy-key"

            return ChatOpenAI(
                model=self.model_name,
                openai_api_key=api_key,
                openai_api_base=self.llm_base_url,
                temperature=0.3,
            )
        else:
            print(f"Unknown provider LLM: {self.provider}")
            return None

    async def process_question(self, question_id: str):
        try:
            question_data = questions_store.get(question_id)
            if not question_data:
                return

            if not self.chain:
                raise ValueError("LLM not initialized. Check API_KEY.")

            file_id = question_data["file_id"]
            document_data = documents_store.get(file_id)

            if not document_data:
                raise ValueError("Document not found")

            context = document_data["text"]
            question = question_data["question"]

            start_time = datetime.now()
            question_data["status"] = "processing"
            question_data["start_time"] = start_time

            answer = await self.chain.ainvoke(
                {"context": context, "question": question}
            )

            end_time = datetime.now()
            processing_time = (end_time - start_time).total_seconds() * 1000

            question_data["answer"] = answer
            question_data["status"] = "completed"
            question_data["completed_at"] = end_time
            question_data["processing_time_ms"] = processing_time

        except Exception as e:
            question_data["status"] = "error"
            question_data["error"] = str(e)
            question_data["completed_at"] = datetime.now()


llm_service = LLMService()
