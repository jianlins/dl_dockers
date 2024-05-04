ARG BASE_IMAGE="nvcr.io/nvidia/cuda:11.4.3-base-ubuntu20.04"
FROM ${BASE_IMAGE}
# Base on here, sparknlp need cuda 11.3
# https://sparknlp.org/docs/en/hardware_acceleration#:~:text=1%20and%20the%20following%20NVIDIA,CUDA%C2%AE%20Toolkit%2011.2

ARG WORK_DIR="/workspace"
ARG HOME='/home/root'
ARG PYTHON_VERSION=3.8
ARG openjdk_version=8

ENV HOME="${HOME}" \
    WORK_DIR="${WORK_DIR}"

ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3

USER root

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
    sudo \
    # - tini is installed as a helpful container entrypoint that reaps zombie
    #   processes and such of the actual executable we want to start, see
    #   https://github.com/krallin/tini#why-tini for details.
    tini \
    # - run-one - a wrapper script that runs no more
    #   than one unique  instance  of  some  command with a unique set of arguments,
    #   we use `run-one-constantly` to support `RESTARTABLE` option
    run-one \
    build-essential \
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
    HOME="${HOME}" \
    WORK_DIR="${WORK_DIR}" \    
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${CONDA_DIR}/lib"

# This port number does't need to be changed, as it's container's own port, only visible inside containers. 
# From outside access, change the port using "-p 0.0.0.0:{desired port nuber}:8888" when starting the container.
ENV JUPYTER_PORT=8888    



# Enable prompt color in the skeleton .bashrc 
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc



# set up working directory
RUN mkdir ${WORK_DIR}
# set up home directory /home/root by default
RUN mkdir ${HOME}


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
COPY post_install.sh /tmp/post_install.sh

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


# Install Corretto JDK 8 due to TRM requirement
RUN wget -q https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.tar.gz
RUN tar xzf amazon-corretto-${openjdk_version}-x64-linux-jdk.tar.gz
RUN rm amazon-corretto-${openjdk_version}-x64-linux-jdk.tar.gz
RUN [ ! -d /usr/lib/jvm ] && mkdir /usr/lib/jvm
RUN mv amazon-corretto-${openjdk_version}.* /usr/lib/jvm/corretto

# Set Java environment variables
ENV JAVA_HOME=/usr/lib/jvm/corretto
ENV PATH=$PATH:$JAVA_HOME/bin

RUN echo "export JAVA_HOME=/usr/lib/jvm/corretto/" >> ~/.bashrc

# split a large layer
RUN mamba init
RUN mamba install nvidia/label/cuda-11.4.1::cuda-toolkit conda-forge:cudnn=8.1.0 && mamba clean --all -f -y

RUN mamba env update --file environment.yml

# add sparknlp pyspark jars
RUN [ -d /root/.ivy2/jars ] || mkdir -p /root/.ivy2/jars

RUN wget -q -P /root/.ivy2/jars/ https://s3.amazonaws.com/auxdata.johnsnowlabs.com/public/jars/spark-nlp-gpu-assembly-5.3.3.jar

#  download models.
RUN chmod 770 /tmp/post_install.sh && \
    /tmp/post_install.sh

RUN mamba clean --all -f -y 
RUN pip cache purge

# check environ variables.
RUN echo $LD_LIBRARY_PATH
RUN echo $CONDA_DIR
RUN echo $PATH
RUN cat ~/.bashrc

# clean tmp
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN ls -l -a /tmp


COPY jupyter_server_config.py /etc/jupyter/
COPY start.sh /usr/local/bin/
RUN chmod 775 /usr/local/bin/*.sh

# Legacy for Jupyter Notebook Server, see: [#1205](https://github.com/jupyter/docker-stacks/issues/1205)
RUN chmod -R 775 /etc/jupyter/
RUN mkdir /home/root/.jupyter
WORKDIR "${WORK_DIR}"

EXPOSE $JUPYTER_PORT
EXPOSE 4040
EXPOSE 22
EXPOSE 18080
EXPOSE 8081
EXPOSE 8080
ENTRYPOINT ["tini", "-g", "--"]

# Specify the default command to run
CMD ["start.sh"]
