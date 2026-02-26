# syntax=docker/dockerfile:1
# Use NVIDIA CUDA base
FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

USER root

# Set your working directory
WORKDIR /tf

# Install Python and essential tools. Upgrade pip as recommended
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    git \
    ffmpeg \
    build-essential \
    graphviz \
    libgraphviz-dev \
    pkg-config \
    swig \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --upgrade pip

# Using a bind mount to install requirements from requirements.txt
# Install libraries without keeping the installer files
RUN --mount=type=bind,source=requirements.txt,target=requirements.txt \
    pip3 install --no-cache-dir -r requirements.txt

# Link NVIDIA libraries using standard cd instead of bash-specific pushd from https://www.tensorflow.org/install/pip
# FROM https://www.tensorflow.org/install/pip ---> Corrected ptxas link for global installation (no venv)
# Perform all linking in one step
RUN TF_PATH=$(python3 -c 'import os; import tensorflow as tf; print(os.path.dirname(tf.__file__))') && \
    cd "$TF_PATH" && \
    ln -svf ../nvidia/*/lib/*.so* . && \
    ln -sf $(find $(dirname $(dirname $(python3 -c "import nvidia.cuda_nvcc; print(nvidia.cuda_nvcc.__file__)"))/*/bin/) -name ptxas -print -quit) /usr/local/bin/ptxas

# Add this to ensure the OS knows where the NVIDIA libraries are. This uses wildcards so it works regardless of the Python version
ENV LD_LIBRARY_PATH="/usr/local/lib/python*/dist-packages/nvidia/cudnn/lib:/usr/local/lib/python*/dist-packages/nvidia/cuda_runtime/lib:$LD_LIBRARY_PATH"

EXPOSE 8888
# this is the correct way. the EXPOSE map[8888/tcp:{}] does not work in Dockerfile

# Corrected CMD with commas from the original in https://hub.docker.com/layers/tensorflow/tensorflow/latest-gpu-jupyter/images
CMD ["bash", "-c", "source /etc/bash.bashrc && jupyter lab --notebook-dir=/tf --ip 0.0.0.0 --no-browser --allow-root"]

