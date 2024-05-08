ARG BASE_IMAGE="nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04"
FROM ${BASE_IMAGE}


# Pin python version here, or set it to "default"
ARG ENVS_DIR='/home/vhaslcshij/workspace'
ARG ENV_NAME='vlinux_llama2'
ARG USER_NAME='vhaslcshij'
ARG USER_ID=10000
ARG spark_version="3.5.1"

ARG MINIFORGE_NAME=Miniforge3

ENV CONDA_DIR=/opt/conda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH=${CONDA_DIR}/bin:${PATH}

# Configure environment
ENV SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

ENV HOME="/home/${USER_NAME}"

#sets the user context for subsequent instructions in the Dockerfile to the "root" user.
USER root

# It specifies that the shell to be used is "/bin/bash" and includes the options "-o pipefail -c".
# Here's a breakdown of the options:
# -o pipefail: This option is used in Bash to set the pipefail option, which makes a pipeline of commands fail if any command in the pipeline fails. By default, only the exit status of the last command in the pipeline is considered. With pipefail enabled, the pipeline fails if any command within the pipeline fails, allowing better error handling in scripts.
# -c: This option is used to specify that the subsequent command or commands should be executed by the shell. It allows you to provide a command or script to be executed by the shell, rather than directly executing a file.
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]



RUN apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    # - pandoc is used to convert notebooks to html files
    #   it's not present in aarch64 ubuntu image, so we install it here
    pandoc \
    # - bzip2 is necessary to extract the micromamba executable.
    bzip2 \
    ca-certificates \
    locales \
    p7zip-full \
    p7zip-rar \
    sudo \
    # - tini is installed as a helpful container entrypoint that reaps zombie
    #   processes and such of the actual executable we want to start, see
    #   https://github.com/krallin/tini#why-tini for details.
    tini \
    # - run-one - a wrapper script that runs no more
    #   than one unique  instance  of  some  command with a unique set of arguments,
    #   we use `run-one-constantly` to support `RESTARTABLE` option
    run-one \
    git \
    wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen





# set up home directory /home/root by default
RUN mkdir -p ${HOME}
RUN mkdir -p ${ENVS_DIR}
RUN mkdir -p ${ENVS_DIR}/ivy


# Download and install Micromamba, and initialize Conda prefix.
#   <https://github.com/mamba-org/mamba#micromamba>
#   Similar projects using Micromamba:
#     - Micromamba-Docker: <https://github.com/mamba-org/micromamba-docker>
#     - repo2docker: <https://github.com/jupyterhub/repo2docker>
# Install Python, Mamba and jupyter_core
# Cleanup temporary files and remove Micromamba
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
COPY environment.yml /tmp/environment.yml
WORKDIR /tmp

# https://github.com/conda-forge/miniforge-images/blob/master/ubuntu/Dockerfile
# https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
RUN apt-get update > /dev/null && \
    apt-get install --no-install-recommends --yes \
        wget bzip2 ca-certificates \
        git \
        tini \
        > /dev/null && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    wget --no-hsts --quiet https://github.com/conda-forge/miniforge/releases/latest/download/${MINIFORGE_VERSION}/${MINIFORGE_NAME}-Linux-$(uname -m).sh -O /tmp/miniforge.sh && \
    /bin/bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniforge.sh && \
    conda clean --tarballs --index-cache --packages --yes && \
    find ${CONDA_DIR} -follow -type f -name '*.a' -delete && \
    find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete && \
    conda clean --force-pkgs-dirs --all --yes  && \
    echo ". ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate base" >> /etc/skel/.bashrc && \
    echo ". ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate base" >> ~/.bashrc


SHELL ["/bin/bash", "-c"] 


RUN mamba init bash \
    && . ~/.bashrc \
    && mamba env create -f environment.yml -p ${ENVS_DIR}/${ENV_NAME} && mamba clean --all -f -y 

RUN mamba init bash \
    && . ~/.bashrc \
    &&  mamba activate ${ENVS_DIR}/${ENV_NAME}  &&\
    python3 -m spacy download en_core_web_sm
    # python3 -m spacy download en_core_web_md 
    # python -c "from pyspark.sql import SparkSession; spark = SparkSession.builder.appName('Spark NLP').master('local[*]').config('spark.jars.ivy', '${ENVS_DIR}/ivy').config('spark.jars.packages', 'com.johnsnowlabs.nlp:spark-nlp-gpu_2.12:${spark_version}').getOrCreate(); spark.stop();"

RUN useradd -u ${USER_ID} ${USER_NAME} -p 111111 && \
    chown -R ${USER_NAME}:${USER_NAME} ${ENVS_DIR} && \
    chmod 777 -R ${ENVS_DIR}

# RUN 7z a -t7z -v400m ${ENV_NAME}.7z ${ENVS_DIR}

RUN ls ${ENVS_DIR}

# RUN ls -l /tmp
# ENTRYPOINT ["/bin/bash", "-c", "7z a -t7z -v400m /tmp/${ENV_NAME}.7z ${ENVS_DIR}"]
# /bin/bash -c "7z a -t7z -v400m /tmp/${{ github.event.inputs.ENV_NAME }}.7z ${{ github.event.inputs.ENVS_DIR }}"