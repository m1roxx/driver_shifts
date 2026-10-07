.PHONY: up smoke gen gate gate-backend gate-app apk

FLUTTER ?= fvm flutter
DART ?= fvm dart
RELEASE_ENV ?= app/env/prod.json

up:
	docker compose up --build

smoke:
	scripts/smoke.sh

gen:
	cd app && $(DART) run build_runner build --delete-conflicting-outputs

gate: gate-backend gate-app

gate-backend:
	@if [ ! -d backend ]; then echo "gate-backend: no backend/ yet, skipped"; exit 0; fi; \
	cd backend && \
	uv run ruff format --check . && \
	uv run ruff check . && \
	uv run mypy . && \
	uv run lint-imports && \
	uv run pytest

gate-app:
	@if [ ! -d app ]; then echo "gate-app: no app/ yet, skipped"; exit 0; fi; \
	cd app && \
	find lib test -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' ! -name '*.config.dart' -print0 \
		| xargs -0 $(DART) format --output=none --set-exit-if-changed && \
	$(FLUTTER) analyze && \
	TZ=America/New_York $(FLUTTER) test

apk:
	scripts/check-release-env.sh $(RELEASE_ENV)
	cd app && $(FLUTTER) build apk --release --dart-define-from-file=$(abspath $(RELEASE_ENV))
