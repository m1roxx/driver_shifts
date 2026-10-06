# syntax=docker/dockerfile:1

# Built from the repository root, which holds data/trips.json: docker build -f backend/Dockerfile .

FROM python:3.14-slim-trixie AS build

COPY --from=ghcr.io/astral-sh/uv:0.12.23 /uv /bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=backend/pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=backend/uv.lock,target=uv.lock \
    --mount=type=bind,source=backend/.python-version,target=.python-version \
    uv sync --locked --no-dev --no-install-project


FROM python:3.14-slim-trixie

RUN useradd --system --no-create-home app

WORKDIR /app

COPY --from=build /app/.venv .venv
COPY backend/pyproject.toml ./
COPY backend/app app
COPY data/trips.json data/trips.json

# An empty PYTHONTZPATH makes zoneinfo read only the tzdata package pinned in uv.lock,
# not whatever time zone database the base image happens to ship.
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONTZPATH="" \
    TRIPS_FILE=/app/data/trips.json

USER app

EXPOSE 8000

CMD ["fastapi", "run"]
