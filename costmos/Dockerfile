FROM nvcr.io/nvidia/pytorch:23.04-py3
LABEL maintainer="VA"
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN python3 -m pip install --no-cache-dir --upgrade pip
# ARG REF=v4.28.1
# RUN git clone https://github.com/huggingface/transformers && cd transformers && git checkout $REF
# RUN python3 -m pip install --no-cache-dir -e ./transformers[dev-torch,testing,video]
# If set to nothing, will install the latest version
# ARG PYTORCH='2.0.0'
# Example: `cu102`, `cu113`, etc.
# ARG CUDA='cu118'
# RUN [ ${#PYTORCH} -gt 0 ] && VERSION='torch=='$PYTORCH'.*' ||  VERSION='torch'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA
#RUN [ ${#TORCH_VISION} -gt 0 ] && VERSION='torchvision=='TORCH_VISION'.*' ||  VERSION='torchvision'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA
#RUN [ ${#TORCH_AUDIO} -gt 0 ] && VERSION='torchaudio=='TORCH_AUDIO'.*' ||  VERSION='torchaudio'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA
RUN /bin/sh -c pip install -U "itsdangerous<2.1.0"
RUN /bin/sh -c pip install transformers
# When installing in editable mode, `transformers` is not recognized as a package.
# this line must be added in order for python to be aware of transformers.
# RUN cd transformers && python3 setup.py develop
RUN /bin/sh -c pip install -U "accelerate==0.18.0"
RUN /bin/sh -c pip install -U "bitsandbytes==0.38.1"
RUN /bin/sh -c pip install -U setuptools wheel jupyterlab Cython simpletransformers lightning nltk bioc torchinfo imbalanced-learn medspacy medspacy_io scikit-learn jupytext pandas tqdm tensorboard pytest

# Set up spark. Revised from https://github.com/jupyter/docker-stacks/blob/main/pyspark-notebook/Dockerfile
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Spark dependencies
# Default values can be overridden at build time
# (ARGS are in lower case to distinguish them from ENV)
ARG spark_version="3.4.0"
ARG hadoop_version="3"
ARG scala_version
ARG spark_checksum="67bc912e9192ef2159540cb480820e5466dfd91e907c97c5a4787587e3020be042b76c40c51854f2a5dbeb8c3775fe12d9021c1200c4704463ec644132243a69"
ARG openjdk_version="17"

#https://github.com/Calipsoplus/jupyterhub-kubernetes/blob/master/jupyter-notebook-debian-base/Dockerfile
ADD costmos/fix-permissions /usr/local/bin/fix-permissions

ENV APACHE_SPARK_VERSION="${spark_version}" \
    HADOOP_VERSION="${hadoop_version}"

# RUN apt-get update --yes && \
#     apt-get install --yes --no-install-recommends \
#     "openjdk-${openjdk_version}-jre-headless" \
#     ca-certificates-java && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*

# install Corretto jdk8
RUN /bin/sh -c pip install -U install-jdk
RUN python3 -c "import jdk;jdk.install('17', vendor='Corretto');"

# Spark installation
WORKDIR /tmp

# You need to use https://archive.apache.org/dist/ website if you want to download old Spark versions
# But it seems to be slower, that's why we use recommended site for download
RUN if [ -z "${scala_version}" ]; then \
    wget -qO "spark.tgz" "https://dlcdn.apache.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"; \
  else \
    wget -qO "spark.tgz" "https://dlcdn.apache.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}-scala${scala_version}.tgz"; \
  fi && \
  echo "${spark_checksum} *spark.tgz" | sha512sum -c - && \
  tar xzf "spark.tgz" -C /usr/local --owner root --group root --no-same-owner && \
  rm "spark.tgz"

# Configure Spark
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx8192M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH="${PATH}:${SPARK_HOME}/bin"

RUN if [ -z "${scala_version}" ]; then \
    ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" "${SPARK_HOME}"; \
  else \
    ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}-scala${scala_version}" "${SPARK_HOME}"; \
  fi && \
  # Add a link in the before_notebook hook in order to source automatically PYTHONPATH && \
  mkdir -p /usr/local/bin/before-notebook.d && \
  ln -s "${SPARK_HOME}/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh

# Configure IPython system-wide
COPY ipython_kernel_config.py "/etc/ipython/"
RUN fix-permissions "/etc/ipython/"

USER ${NB_UID}

# Install pyarrow
RUN mamba install --yes \
    'pyarrow' && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

WORKDIR "${HOME}"
EXPOSE 4040

