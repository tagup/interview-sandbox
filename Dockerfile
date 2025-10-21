FROM mcr.microsoft.com/devcontainers/universal:2-linux

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends libpq-dev postgresql-client

ENV DEB_PYTHON_INSTALL_LAYOUT=deb_system
COPY ./pyproject.toml ./pyproject.toml
RUN pip install hatch && hatch env create
