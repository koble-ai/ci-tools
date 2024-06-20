FROM node:18

ARG AWSCLI_ARCH="linux-aarch64"
ARG NVM_VERSION="0.39.7"
ARG NODE_VERSION="18.19.0"
ARG NPM_VERSION="10.2.5"

RUN apt update && \
    apt install python3-pip -y && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    echo "Starting AWS" && \
    curl https://awscli.amazonaws.com/awscli-exe-${AWSCLI_ARCH}.zip -o awscliv2.zip && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -f awscliv2.zip && rm -rf aws && \
    echo "Done installing AWS" && \
    pip --version && \
    python --version && \
    node --version && \
    aws --version

