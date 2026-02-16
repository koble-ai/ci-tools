FROM python:3.11.12-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    NVM_DIR=/root/.nvm \
    POETRY_HOME=/opt/poetry \
    PATH=/root/.nvm/versions/node/current/bin:/opt/google-cloud-sdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/poetry/bin

ARG NODE_VERSION=22
ARG NPM_VERSION=11.3.0
ARG NVM_VERSION=0.40.2
ARG MODD_VERSION=0.5
ARG TASKFILE_VERSION=3.2.2
ARG POETRY_VERSION=1.8.5
ARG TARGETARCH

# ---------- 1. System packages (single layer) ----------
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      bzip2 \
      ca-certificates \
      curl \
      g++ \
      gcc \
      git \
      gnupg \
      groff \
      jq \
      less \
      libmcrypt-dev \
      libreadline-dev \
      libssl-dev \
      make \
      openssh-client \
      ruby \
      ruby-dev \
      unzip \
    && rm -rf /var/lib/apt/lists/*

# ---------- 2. Tool installations (single layer) ----------
RUN set -ex && \
    # --- AWS CLI --- \
    if [ "$TARGETARCH" = "amd64" ]; then \
      curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip; \
    else \
      curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o awscliv2.zip; \
    fi && \
    unzip -q awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip && \
    # --- pip tools --- \
    pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir pipenv boto3 uv keyring keyrings.codeartifact && \
    # --- Poetry --- \
    curl -sSL https://install.python-poetry.org | python3 - && \
    # --- Ruby gems --- \
    gem install --no-document rb-inotify:'~> 0.11.1' sass && \
    gem install --no-document scss_lint:'~> 0.59.0' && \
    rm -rf /var/lib/gems/*/cache/*.gem && \
    # --- modd --- \
    if [ "$TARGETARCH" = "amd64" ]; then \
      curl -fsSL "https://github.com/cortesi/modd/releases/download/v${MODD_VERSION}/modd-${MODD_VERSION}-linux64.tgz" \
        | tar -xOzf - "modd-${MODD_VERSION}-linux64/modd" > /usr/bin/modd; \
    else \
      curl -fsSL "https://github.com/cortesi/modd/releases/download/v${MODD_VERSION}/modd-${MODD_VERSION}-linuxARM.tgz" \
        | tar -xOzf - "modd-${MODD_VERSION}-linuxARM/modd" > /usr/bin/modd; \
    fi && \
    chmod 755 /usr/bin/modd && \
    # --- Taskfile --- \
    curl -fsSL https://taskfile.dev/install.sh | sh -s v${TASKFILE_VERSION} && \
    # --- NVM / Node / npm / yarn --- \
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash && \
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
    nvm install ${NODE_VERSION} && \
    nvm alias default ${NODE_VERSION} && \
    ln -s "/root/.nvm/versions/node/$(nvm version ${NODE_VERSION})" /root/.nvm/versions/node/current && \
    npm install -g npm@${NPM_VERSION} && \
    npm install -g pyright pyright-to-gitlab-ci && \
    npm cache clean --force && \
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y --no-install-recommends yarn && \
    # --- Docker --- \
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm -f get-docker.sh && \
    # --- kubectl --- \
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' > /etc/apt/sources.list.d/kubernetes.list && \
    chmod 644 /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update -y && apt-get install -y kubectl && \
    # --- gcloud (standalone installer — avoids apt python3>=3.10 dep on bullseye) --- \
    curl -fsSL https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.tar.gz | tar -xz -C /opt && \
    /opt/google-cloud-sdk/install.sh --quiet --path-update=false && \
    /opt/google-cloud-sdk/bin/gcloud components install gke-gcloud-auth-plugin --quiet && \
    rm -rf /opt/google-cloud-sdk/.install/.backup && \
    # --- Final cleanup --- \
    apt-get -qq -y autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache

# ---------- 3. Verification ----------
RUN poetry --version && \
    uv --version && \
    pyright --version && \
    gcloud --version && \
    aws --version && \
    gke-gcloud-auth-plugin --version && \
    node --version && \
    yarn --version
