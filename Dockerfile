FROM python:3.12-slim

WORKDIR /app

# Install gcc for any C-extension packages
RUN apt-get update && apt-get install -y --no-install-recommends gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY src/ ./src/
COPY app.py .
COPY startup.sh .

RUN chmod +x startup.sh

EXPOSE 8000

CMD ["gunicorn", "--bind=0.0.0.0:8000", "--workers=2", "--threads=4", "--timeout=120", "src.app:app"]
