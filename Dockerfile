ARG BASE_IMAGE
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash \
    PATH="/usr/local/cuda/bin:${PATH}"

# Install oobabooga
ARG INDEX_URL
ARG TORCH_VERSION
ARG OOBABOOGA_COMMIT
ENV INDEX_URL=${INDEX_URL}
ENV TORCH_VERSION=${TORCH_VERSION}
ENV OOBABOOGA_COMMIT=${OOBABOOGA_COMMIT}
#COPY oobabooga/requirements* ./
COPY --chmod=755 build/install.sh /install.sh
RUN /install.sh && rm /install.sh

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/api.html /usr/share/nginx/html/

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# Copy startup script for Oobabooba Web UI
COPY --chmod=755 scripts/start_textgen_server.sh /text-generation-webui/

# Copy scripts to download models
COPY fetch_model.py /text-generation-webui/
COPY download_model.py /text-generation-webui/

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Set the venv path
ARG VENV_PATH
ENV VENV_PATH=${VENV_PATH}

# Copy the scripts
WORKDIR /
COPY --chmod=755 scripts/* ./

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN source ~/.nvm/nvm.sh && nvm install --lts && nvm use --lts

RUN git clone https://github.com/SillyTavern/SillyTavern -b staging

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
