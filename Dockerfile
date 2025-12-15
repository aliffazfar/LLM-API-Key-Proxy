FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

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
    && pip install -e src/rotator_library

# Create directories for persistent data
RUN mkdir -p /app/logs /app/oauth_creds /app/cache

# Expose the default port
EXPOSE 8000

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Run the proxy server
CMD ["uvicorn", "src.proxy_app.main:app", "--host", "0.0.0.0", "--port", "8000"]