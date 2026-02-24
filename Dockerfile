# Use NVIDIA CUDA base
FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04

USER root

# Set your working directory
WORKDIR /tf

# Install Python and essential tools. Upgrade pip as recommended
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    git \
    build-essential \
    graphviz \
    swig \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --upgrade pip

# Install TF with CUDA support and Jupyter without keeping the installer files
RUN pip3 install --no-cache-dir "tensorflow[and-cuda]" jupyterlab ipywidgets joblib matplotlib nbdime nltk pandas \
pydot scikit-learn scipy statsmodels keras-tuner tensorboard-plugin-profile tensorflow-datasets tensorflow-hub tensorflow-serving-api transformers \
urlextract "gymnasium[classic_control,atari,accept-rom-license]" google-cloud-aiplatform google-cloud-storage xgboost box2d-py

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

