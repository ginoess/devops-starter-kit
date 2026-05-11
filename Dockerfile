FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app


FROM base AS builder

COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt


FROM base AS development

COPY --from=builder /install /usr/local
COPY . .

EXPOSE 3000
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "3000", "--reload"]


FROM base AS production

RUN groupadd --system app && useradd --system --gid app app

COPY --from=builder /install /usr/local
COPY --chown=app:app . .

USER app

EXPOSE 3000
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "3000", "--workers", "4"]
