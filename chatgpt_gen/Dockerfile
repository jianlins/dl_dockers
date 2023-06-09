# Base image with CUDA 11.2 and cuDNN 8
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Python and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install PyTorch 2.0.0 with CUDA 11.8 support
#RUN pip3 install torch==2.0.0+cu118 torchvision==0.10.0+cu118 torchaudio==0.10.0 -f https://download.pytorch.org/whl/torch_stable.html
RUN pip3 install torch --index-url https://download.pytorch.org/whl/cu118

# Install Spark
RUN curl -O https://archive.apache.org/dist/spark/spark-3.4.0/spark-3.4.0-bin-hadoop3.tgz  && \
    tar xzf spark-3.4.0-bin-hadoop3.tgz  && \
    mv spark-3.4.0-bin-hadoop3 /opt/spark && \
    rm spark-3.4.0-bin-hadoop3.tgz 

# Set environment variables for Spark
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin
ENV PYSPARK_PYTHON=python3

# Install PySpark
RUN pip3 install pyspark==3.4.0

# Install JupyterLab
RUN pip3 install jupyterlab

# Expose JupyterLab port
EXPOSE 8888

# Set the default command to run JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]