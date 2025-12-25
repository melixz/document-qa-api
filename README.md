# document-qa-api

Сервис для ответов на вопросы по DOCX-документам на FastAPI. Поддерживает Google Gemini и локальные модели (Qwen).

## Особенности

- **DOCX**: извлечение текста из документов.
- **LLM**: поддержка Google Gemini и локального Qwen (через Ollama).
- **Асинхронность**: фоновая обработка вопросов.
- **Интерфейс**: REST API (JSON).

## Быстрый старт

### Требования

- Docker и Docker Compose
- API ключ Google Gemini (для `google`)

### Запуск через Docker

1. Настройте `.env` (см. `.env.example`).
2. Запустите сервисы:
   ```bash
   make up
   ```
   *Примечание: Сервис `ollama` запустится только если `LLM_PROVIDER=qwen`.*
3. Если используется `qwen`, скачайте модель:
   ```bash
   make setup-model
   ```

После старта:
- API: `http://localhost:8000`
- Swagger UI: `http://localhost:8000/docs`

## Автоматическое тестирование

Запуск сценария (загрузка файла и 4 вопроса):
```bash
make test
```

## Конфигурация (.env)

- `API_KEY` — Ключ Google или OpenAI.
- `LLM_PROVIDER` — `google` или `qwen`.
- `LLM_MODEL_NAME` — Имя модели.
- `LLM_BASE_URL` — Эндпоинт Ollama (`http://ollama:11434/v1`).

## Структура проекта

```text
app/
├── main.py                  # Точка входа
├── models.py                # Pydantic схемы
├── services/
│   ├── document_service.py  # Обработка DOCX
│   └── llm_service.py       # Провайдеры LLM
└── storage/
    └── documents.py         # Временное хранилище
```

## API Методы

- `POST /upload` — Загрузка DOCX.
- `POST /ask` — Отправить вопрос.
- `GET /answer/{id}` — Получить ответ.
