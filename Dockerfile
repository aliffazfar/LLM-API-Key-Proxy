# Build stage
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Set PATH for user-installed packages in builder stage
ENV PATH=/root/.local/bin:$PATH

# Copy requirements first for better caching
COPY requirements.txt .

# Copy the local rotator_library for editable install
COPY src/rotator_library ./src/rotator_library

# Install dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy the entire application code first
COPY . .

# Install Python dependencies (excluding the local editable package)
# Then install the local rotator_library package
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn \
    python-dotenv \
    litellm \
    filelock \
    httpx \
    aiofiles \
    aiohttp \
    colorlog \
    rich \
    && pip install --no-cache-dir -e src/rotator_library \
    && rm -rf ~/.cache/pip

# Create directories for persistent data
RUN mkdir -p /app/logs /app/oauth_creds /app/cache

# Expose the default port
EXPOSE 8000

# Set environment variables for low-memory operation
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV MALLOC_ARENA_MAX=2

# Run with single worker for low-memory VPS
CMD ["uvicorn", "src.proxy_app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
