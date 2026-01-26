FROM mcr.microsoft.com/devcontainers/universal:2-linux

RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -  && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends libpq-dev postgresql-client
