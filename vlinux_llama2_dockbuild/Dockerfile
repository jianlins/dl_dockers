ARG BASE_IMAGE="nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04"
FROM ${BASE_IMAGE}


# Pin python version here, or set it to "default"
ARG PYTHON_VERSION=3.8
ARG ENVS_DIR='/home/vhaslcshij/workspace'
ARG ENV_NAME='vlinux_llama2'
ARG USER_NAME='vhaslcshij'
ARG USER_ID=10000
ARG spark_version="3.5.1"


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


# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${USER_NAME}"

# This port number does't need to be changed, as it's container's own port, only visible inside containers. 
# From outside access, change the port using "-p 0.0.0.0:{desired port nuber}:8888" when starting the container.
ENV JUPYTER_PORT=8888    



# Enable prompt color in the skeleton .bashrc 
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc



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
COPY initial-condarc "${CONDA_DIR}/.condarc"
COPY environment.yml /tmp/environment.yml
WORKDIR /tmp

RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        arch="64"; \
    fi && \
    wget -qO /tmp/micromamba.tar.bz2 \
        "https://micromamba.snakepit.net/api/micromamba/linux-${arch}/latest" && \
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2 && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    # Install the packages
    ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        "${PYTHON_SPECIFIER}" \
        'mamba' && \
    rm micromamba && \
    # Pin major.minor version of python
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    mamba clean --all -f -y && \
    which mamba && \
    chmod -R 775 "${CONDA_DIR}" 


RUN mamba env create -f environment.yml -p ${ENVS_DIR}/${ENV_NAME}    

RUN mamba clean --all -f -y 

RUN mamba init && source ~/.bashrc && mamba activate ${ENVS_DIR}/${ENV_NAME}  &&\
    python3 -m spacy download en_core_web_sm && \
    python3 -m spacy download en_core_web_md && \
    python -c "from pyspark.sql import SparkSession; spark = SparkSession.builder.appName('Spark NLP').master('local[*]').config('spark.jars.ivy', '${ENVS_DIR}/ivy').config('spark.jars.packages', 'com.johnsnowlabs.nlp:spark-nlp-gpu_2.12:${spark_version}').getOrCreate(); spark.stop();"

RUN 7z a -t7z -v400m ${ENV_NAME}.7z ${ENVS_DIR}/${ENV_NAME}

RUN ls -l /tmp