
.PHONY: setup
setup:
	pip install hatch && hatch env create && docker-compose up -d
