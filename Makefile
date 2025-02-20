
.PHONY: setup up
setup:
	pip install hatch && hatch env create && docker-compose up -d
up:
	docker compose up -d
