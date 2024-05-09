ARG BASE_IMAGE="ubuntu:latest"
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
RUN mkdir -p ${ENVS_DIR}/${ENV_NAME}
RUN mkdir -p ${ENVS_DIR}/ivy


WORKDIR /tmp

# https://github.com/conda-forge/miniforge-images/blob/master/ubuntu/Dockerfile
# https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
RUN rm -rf /var/lib/apt/lists/* && \
    wget --no-hsts --quiet https://github.com/conda-forge/miniforge/releases/latest/download/${MINIFORGE_VERSION}/${MINIFORGE_NAME}-Linux-$(uname -m).sh -O /tmp/miniforge.sh && \
    /bin/bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniforge.sh && \
    conda clean --tarballs --index-cache --packages --yes && \
    find ${CONDA_DIR} -follow -type f -name '*.a' -delete && \
    find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete && \
    conda clean --force-pkgs-dirs --all --yes  && \
    echo ". ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate base" >> /etc/skel/.bashrc && \
    echo ". ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate base" >> ~/.bashrc




RUN /bin/bash -c "ls  ${ENVS_DIR}"

RUN mamba init bash \
    && . ~/.bashrc \
    && mamba env create -p ${ENVS_DIR}/${ENV_NAME} python=3.8 && mamba clean --all -f -y 

RUN 7z a -t7z -v400m /tmp/${ENV_NAME}.7z ${ENVS_DIR} && ls /tmp
RUN echo 'zipped'

# RUN 7z a -t7z -v400m ${ENV_NAME}.7z ${ENVS_DIR}

RUN ls ${ENVS_DIR}

ENTRYPOINT ["/bin/bash", "-c", "ls /tmp"]
# RUN ls -l /tmp
# ENTRYPOINT ["/bin/bash", "-c", "7z a -t7z -v400m /tmp/${ENV_NAME}.7z ${ENVS_DIR}"]
# /bin/bash -c "7z a -t7z -v400m /tmp/${{ github.event.inputs.ENV_NAME }}.7z ${{ github.event.inputs.ENVS_DIR }}"