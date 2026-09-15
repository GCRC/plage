# Build frontend assets
FROM node:20-slim AS frontend

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY scripts/ ./scripts/
COPY tailwind.config.js ./
COPY src/plage/static/ ./src/plage/static/
COPY src/plage/templates/ ./src/plage/templates/

RUN npm run build


# Python runtime
FROM python:3.12-slim

WORKDIR /app

# Install uv for fast dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy project files
COPY pyproject.toml ./
COPY src/ ./src/

# Copy built frontend assets
COPY --from=frontend /app/src/plage/static/css/ ./src/plage/static/css/
COPY --from=frontend /app/src/plage/static/vendor/ ./src/plage/static/vendor/

# Install Python dependencies
RUN uv pip install --system --no-cache .

# Default environment
ENV PLAGE_HOST=0.0.0.0
ENV PLAGE_PORT=8100

EXPOSE 8100

# Run without reload in production
CMD ["python", "-c", "import uvicorn; uvicorn.run('plage.main:app', host='0.0.0.0', port=int(__import__('os').environ.get('PLAGE_PORT', '8100')))"]
