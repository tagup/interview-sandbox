FROM mcr.microsoft.com/devcontainers/universal:3-linux

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends libpq-dev postgresql-client
