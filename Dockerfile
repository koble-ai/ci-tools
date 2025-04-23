FROM python:3.11.12-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    NVM_DIR=/root/.nvm \
    # BASH_ENV=/root/.bash_env \
    POETRY_HOME=/opt/poetry \
    PATH=/root/.nvm/versions/node/current/bin:usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/poetry/bin

ARG NODE_VERSION=22
ARG NPM_VERSION=11.3.0
ARG NVM_VERSION=0.40.2
ARG MODD_VERSION=0.5
ARG TASKFILE_VERSION=3.2.2
ARG POETRY_VERSION=1.8.5
ARG TARGETARCH


ENV DIND_COMMIT=65cfcc28ab37cb75e1560e4b4738719c07c6618e

# Install system dependencies for python and pip
RUN apt-get update -y
RUN apt-get install unzip groff less jq -y
RUN apt-get install curl -y
RUN pip install -U pip
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    else \
      curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    fi
RUN unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf aws && \
    rm -f awscliv2.zip && \
    # Install basics Python tools
    pip install pipenv boto3 && \
    apt-get -qq -y autoremove && \
    apt-get -qq clean && apt-get -qq purge && \
    rm -rf /var/lib/apt/lists/* /var/lib/dpkg/*-old && \
    # Install Poetry
    curl -sSL https://install.python-poetry.org | python3 -
RUN apt-get update -y && apt-get install g++ gcc -y
RUN echo "Starting ..." && \
    apt-get -qq clean && apt-get -qq update && \
    apt-get -qq -y install libssl-dev curl git imagemagick apt-transport-https ca-certificates gnupg make gnupg \
      libmcrypt-dev libreadline-dev ruby-full openssh-client ocaml libelf-dev bzip2 jq
RUN gem install rb-inotify:'~> 0.11.1' sass --verbose && \
    gem install scss_lint:'~> 0.59.0' --verbose && \
    echo "Done base install!"
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      curl -sSL https://github.com/cortesi/modd/releases/download/v${MODD_VERSION}/modd-${MODD_VERSION}-linux64.tgz | tar -xOvzf - modd-${MODD_VERSION}-linux64/modd > /usr/bin/modd; \
    else \
      curl -sSL https://github.com/cortesi/modd/releases/download/v${MODD_VERSION}/modd-${MODD_VERSION}-linuxARM.tgz | tar -xOvzf - modd-${MODD_VERSION}-linuxARM/modd > /usr/bin/modd; \
    fi
RUN chmod 755 /usr/bin/modd && \
    echo "Done Install Modd" && \
    echo "Install Taskfile" && \
    curl -sSL https://taskfile.dev/install.sh | sh -s v${TASKFILE_VERSION} && \
    echo "Done Install Taskfile" && \
    echo "Starting Javascript..."
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash && \
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
    nvm install ${NODE_VERSION} && \
    nvm alias default ${NODE_VERSION} && \
    ln -s /root/.nvm/versions/node/$(nvm version ${NODE_VERSION}) /root/.nvm/versions/node/current && \
    npm install -g npm@${NPM_VERSION} && \
    curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install yarn --no-install-recommends && \
    echo "Done JS!" && \
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
RUN echo "Starting kubectl..." && \
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \
    chmod 644 /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update -y && \
    apt-get install kubectl -y

RUN echo "Starting gcloud..." && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update -y && \
    apt-get install google-cloud-cli google-cloud-sdk-gke-gcloud-auth-plugin -y

RUN poetry --version
RUN gcloud --version
RUN aws --version
RUN gke-gcloud-auth-plugin --version
RUN node --version
RUN yarn --version

#   RUN set -eux; \
#	curl "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -o /usr/local/bin/dind && \
#	chmod +x /usr/local/bin/dind