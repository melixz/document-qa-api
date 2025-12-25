include .env
export $(shell sed 's/=.*//' .env)

PROFILE_FLAG =
ifeq ($(LLM_PROVIDER), qwen)
	PROFILE_FLAG = --profile qwen
endif

up:
	docker compose $(PROFILE_FLAG) up -d --build
	@if [ "$(LLM_PROVIDER)" = "qwen" ]; then \
		echo "Сервисы запущены с профилем qwen. Не забудьте выполнить: make setup-model"; \
	else \
		echo "Сервисы запущены (провайдер: $(LLM_PROVIDER))"; \
	fi

down:
	docker compose $(PROFILE_FLAG) down

.PHONY: up down test clean setup-model

test: up
	@echo "Ожидание запуска API..."
	@sleep 10
	@if [ ! -f contract.docx ]; then \
		echo "Загрузка contract.docx..."; \
		curl -s -L -o contract.docx "https://docs.google.com/document/d/1UNolMwDcRGwlBaTFPzQxnNrtuOx12DF8/export?format=docx"; \
	fi
	@echo "Загрузка документа в API..."
	@FILE_ID=$$(curl -s -X POST -F "file=@contract.docx" http://localhost:8000/upload | grep -o '"file_id":"[^"]*"' | cut -d'"' -f4); \
	if [ -z "$$FILE_ID" ]; then \
		echo "Ошибка: Не удалось загрузить документ."; \
		exit 1; \
	fi; \
	echo "ID файла: $$FILE_ID"; \
	echo "\nОтправка вопросов..."; \
	Q1_ID=$$(curl -s -X POST -H "Content-Type: application/json" -d "{\"file_id\": \"$$FILE_ID\", \"question\": \"Укажи предмет договора\"}" http://localhost:8000/ask | grep -o '"question_id":"[^"]*"' | cut -d'"' -f4); \
	Q2_ID=$$(curl -s -X POST -H "Content-Type: application/json" -d "{\"file_id\": \"$$FILE_ID\", \"question\": \"Какой номер и дата у этого договора?\"}" http://localhost:8000/ask | grep -o '"question_id":"[^"]*"' | cut -d'"' -f4); \
	Q3_ID=$$(curl -s -X POST -H "Content-Type: application/json" -d "{\"file_id\": \"$$FILE_ID\", \"question\": \"Какие штрафные санкции предусматривает этот договор в отношении поставщика?\"}" http://localhost:8000/ask | grep -o '"question_id":"[^"]*"' | cut -d'"' -f4); \
	Q4_ID=$$(curl -s -X POST -H "Content-Type: application/json" -d "{\"file_id\": \"$$FILE_ID\", \"question\": \"Какие штрафные санкции предусматривает этот договор в отношении покупателя?\"}" http://localhost:8000/ask | grep -o '"question_id":"[^"]*"' | cut -d'"' -f4); \
	echo "Ожидание ответов (10с)...\n"; \
	sleep 10; \
	echo "=== Ответ 1 ==="; \
	curl -s http://localhost:8000/answer/$$Q1_ID | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('answer') or 'Нет ответа')"; \
	echo "\n=== Ответ 2 ==="; \
	curl -s http://localhost:8000/answer/$$Q2_ID | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('answer') or 'Нет ответа')"; \
	echo "\n=== Ответ 3 ==="; \
	curl -s http://localhost:8000/answer/$$Q3_ID | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('answer') or 'Нет ответа')"; \
	echo "\n=== Ответ 4 ==="; \
	curl -s http://localhost:8000/answer/$$Q4_ID | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('answer') or 'Нет ответа')"; \
	echo "\nГотово!"

setup-model:
	docker compose $(PROFILE_FLAG) exec ollama ollama run qwen2.5:7b

clean:
	docker compose $(PROFILE_FLAG) down -v

