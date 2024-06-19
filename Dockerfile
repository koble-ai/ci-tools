FROM python:3.10-bullseye

ARG AWSCLI_ARCH="linux-aarch64"
ARG NVM_VERSION="0.39.7"
ARG NODE_VERSION="18.19.0"
ARG NPM_VERSION="10.2.5"

RUN echo "Starting Javascript..." && \
    git clone https://github.com/nvm-sh/nvm.git /root/.nvm && cd /root/.nvm && git checkout v${NVM_VERSION} && \
    . /root/.nvm/nvm.sh && \
    nvm install ${NODE_VERSION} && nvm alias default ${NODE_VERSION} && \
    ln -s "/root/.nvm/versions/node/v${NODE_VERSION}/bin/node" "/usr/local/bin/node" && \
    ln -s "/root/.nvm/versions/node/v${NODE_VERSION}/bin/npm" "/usr/local/bin/npm" && \
    ln -s "/root/.nvm/versions/node/v${NODE_VERSION}/bin/npx" "/usr/local/bin/npx" && \
    npm install -g npm@${NPM_VERSION} && \
    curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install yarn --no-install-recommends && \
    echo "Done JS!" && \
    echo "Starting AWS" && \
    curl https://awscli.amazonaws.com/awscli-exe-${AWSCLI_ARCH}.zip -o awscliv2.zip && \
  unzip -q awscliv2.zip && \
    ./aws/install && \
  rm -f awscliv2.zip && rm -rf aws && \
    echo "Done installing AWS"