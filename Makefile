.PHONY: up down build logs shell ps clean deploy rollback monitoring

COMPOSE         := docker compose
COMPOSE_PROD    := docker compose -f docker-compose.prod.yml
COMPOSE_MON     := docker compose -f docker-compose.monitoring.yml

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

build:
	$(COMPOSE) build --no-cache

logs:
	$(COMPOSE) logs -f

shell:
	$(COMPOSE) exec app sh

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down -v --remove-orphans
	docker system prune -f

deploy:
	@bash scripts/deploy.sh deploy

rollback:
	@bash scripts/deploy.sh rollback $(TAG)

monitoring:
	$(COMPOSE_MON) up -d

monitoring-down:
	$(COMPOSE_MON) down
