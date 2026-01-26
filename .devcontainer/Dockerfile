FROM mcr.microsoft.com/devcontainers/universal:2-linux

RUN sudo mkdir -p /usr/share/keyrings && curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/yarn-archive-keyring.gpg && echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends libpq-dev postgresql-client
