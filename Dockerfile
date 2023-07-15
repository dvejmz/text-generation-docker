# Stage 1: Base
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as base

ARG VERSION=v1.1.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash

# Create workspace working directory
WORKDIR /workspace

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        software-properties-common \
        python3.10-venv \
        python3-tk \
        bash \
        git \
        ncdu \
        nginx  \
        net-tools \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        zip \
        unzip \
        htop \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 libtcmalloc-minimal4 \
        apt-transport-https ca-certificates && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set Python and pip
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    curl https://bootstrap.pypa.io/get-pip.py | python && \
    rm -f get-pip.py

# Stage 2: Install Web UI and python modules
FROM base as setup

# Install Torch
RUN python3 -m venv /venv && \
    source /venv/bin/activate && \
    pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip3 install --no-cache-dir xformers && \
    deactivate

# Clone the git repo of Text Generation Web UI and set version
WORKDIR /
RUN git clone https://github.com/oobabooga/text-generation-webui && \
    cd /text-generation-webui && \
    git checkout ${VERSION}

# Install the dependencies for Text Generation Web UI
WORKDIR /text-generation-webui
RUN source /venv/bin/activate && \
    pip3 install -r requirements.txt && \
    deactivate

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Install Jupyter
RUN pip3 install -U --no-cache-dir jupyterlab \
        jupyterlab_widgets \
        ipykernel \
        ipywidgets \
        gdown

# NGINX Proxy
COPY nginx.conf /etc/nginx/nginx.conf
COPY api.html 502.html /usr/share/nginx/html/

# Copy the template-readme.md
COPY template-readme.md /usr/share/nginx/html/README.md

# Copy startup scripts for text-generation
COPY start_chatbot_server.sh start_textgen_server.sh /text-generation-webui/

# Set up the container startup script
WORKDIR /
COPY pre_start.sh start.sh fix_venv.sh ./
RUN chmod +x /start.sh && \
    chmod +x /pre_start.sh && \
    chmod +x /fix_venv.sh && \
    chmod a+x /text-generation-webui/start_chatbot_server.sh && \
    chmod a+x /text-generation-webui/start_textgen_server.sh

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]