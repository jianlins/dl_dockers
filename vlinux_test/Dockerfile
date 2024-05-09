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


RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

   
WORKDIR /tmp

COPY initial-condarc "${CONDA_DIR}/.condarc"
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


SHELL ["/bin/bash", "-c"] 

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