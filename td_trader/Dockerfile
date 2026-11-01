# TD TRADER - Production Docker Container
FROM python:3.13-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy complete project
COPY . /app/td_trader/

ENV PYTHONPATH=/app
ENV TD_SECRET_KEY="td-trader-production-docker-secret-key-32-chars-min!"

EXPOSE 8000 5555 5556

CMD ["python3", "td_trader/infrastructure/scripts/start_server.py"]

