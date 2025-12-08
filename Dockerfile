FROM python:3.11-slim

WORKDIR /app

# Install runtime dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy the scanner
COPY scanner.py /app/scanner.py

# Create a non-root user for safer container runtime
RUN useradd --create-home --shell /bin/bash appuser || true
USER appuser

ENTRYPOINT ["python3", "scanner.py"]
