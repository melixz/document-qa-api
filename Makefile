.PHONY: up down test clean

up:
	docker compose up -d --build

down:
	docker compose down

test: up
	@echo "Waiting for API to start..."
	@sleep 10
	@if [ ! -f contract.docx ]; then \
		echo "Downloading contract.docx..."; \
		curl -s -L -o contract.docx "https://docs.google.com/document/d/1UNolMwDcRGwlBaTFPzQxnNrtuOx12DF8/export?format=docx"; \
	fi
	@echo "Uploading document..."
	@FILE_ID=$$(curl -s -X POST -F "file=@contract.docx" http://localhost:8000/upload | grep -o '"file_id":"[^"]*"' | cut -d'"' -f4); \
	if [ -z "$$FILE_ID" ]; then \
		echo "Error: Failed to upload document."; \
		exit 1; \
	fi; \
	echo "File ID: $$FILE_ID"; \
	echo "\nAsking questions..."; \
	Q1_ID=$$(curl -s -X POST -H "Content-Type: application/json" -d "{\"file_id\": \"$$FILE_ID\", \"question\": \"Укажи предмет договора\"}" http://localhost:8000/ask | grep -o '"question_id":"[^"]*"' | cut -d'"' -f4); \
	Q2_ID=$$(curl -s -X POST -H "Content-Type: application/json" -d "{\"file_id\": \"$$FILE_ID\", \"question\": \"Какой номер и дата у этого договора?\"}" http://localhost:8000/ask | grep -o '"question_id":"[^"]*"' | cut -d'"' -f4); \
	Q3_ID=$$(curl -s -X POST -H "Content-Type: application/json" -d "{\"file_id\": \"$$FILE_ID\", \"question\": \"Какие штрафные санкции предусматривает этот договор в отношении поставщика?\"}" http://localhost:8000/ask | grep -o '"question_id":"[^"]*"' | cut -d'"' -f4); \
	Q4_ID=$$(curl -s -X POST -H "Content-Type: application/json" -d "{\"file_id\": \"$$FILE_ID\", \"question\": \"Какие штрафные санкции предусматривает этот договор в отношении покупателя?\"}" http://localhost:8000/ask | grep -o '"question_id":"[^"]*"' | cut -d'"' -f4); \
	echo "Waiting for answers (10s)...\n"; \
	sleep 10; \
	echo "=== Answer 1 ==="; \
	curl -s http://localhost:8000/answer/$$Q1_ID | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('answer') or 'No answer')"; \
	echo "\n=== Answer 2 ==="; \
	curl -s http://localhost:8000/answer/$$Q2_ID | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('answer') or 'No answer')"; \
	echo "\n=== Answer 3 ==="; \
	curl -s http://localhost:8000/answer/$$Q3_ID | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('answer') or 'No answer')"; \
	echo "\n=== Answer 4 ==="; \
	curl -s http://localhost:8000/answer/$$Q4_ID | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('answer') or 'No answer')"; \
	echo "\nDone!"

clean:
	docker compose down -v

