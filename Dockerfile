# TD TRADER - 24/7 Cloud Trading Engine Container
# Copyright (c) 2026 TechDaddy. All rights reserved.

FROM python:3.11-slim

WORKDIR /app

# Install system utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Python requirements
COPY td_trader/requirements.txt /app/td_trader/requirements.txt
RUN pip install --no-cache-dir -r /app/td_trader/requirements.txt

# Copy source code
COPY td_trader /app/td_trader

ENV PORT=8000
ENV PYTHONPATH=/app

EXPOSE 8000

# Run uvicorn on cloud port
CMD ["sh", "-c", "python3 -m uvicorn td_trader.backend.app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
