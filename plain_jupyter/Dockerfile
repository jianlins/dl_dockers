ARG BASE_IMAGE="ubuntu:22.04"
FROM ${BASE_IMAGE}


# Pin python version here, or set it to "default"
ARG PYTHON_VERSION=3.10

# make the working dir shorter so that it's easier type when mapping volumns or operating files.
ARG WORK_DIR="/workspace"
ARG HOME='/home/root'


#sets the user context for subsequent instructions in the Dockerfile to the "root" user.
USER root

# It specifies that the shell to be used is "/bin/bash" and includes the options "-o pipefail -c".
# Here's a breakdown of the options:
# -o pipefail: This option is used in Bash to set the pipefail option, which makes a pipeline of commands fail if any command in the pipeline fails. By default, only the exit status of the last command in the pipeline is considered. With pipefail enabled, the pipeline fails if any command within the pipeline fails, allowing better error handling in scripts.
# -c: This option is used to specify that the subsequent command or commands should be executed by the shell. It allows you to provide a command or script to be executed by the shell, rather than directly executing a file.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]


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
    WORK_DIR="${WORK_DIR}"

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

RUN mamba install -c conda-forge jupyterlab
# -a, --all	Remove index cache, lock files, unused cache packages, and tarballs
# -f, --force-pkgs-dirs	Remove all writable package caches
# -y, --yes	Do not ask for confirmation
RUN mamba clean --all -f -y 

EXPOSE $JUPYTER_PORT

# Configure container startup
# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]



# Currently need to have both jupyter_notebook_config and jupyter_server_config to support classic and lab
# COPY jupyter_server_config.py docker_healthcheck.py /etc/jupyter/
COPY jupyter_server_config.py /etc/jupyter/


# Legacy for Jupyter Notebook Server, see: [#1205](https://github.com/jupyter/docker-stacks/issues/1205)
RUN sed -re "s/c.ServerApp/c.NotebookApp/g" \
    /etc/jupyter/jupyter_server_config.py > /etc/jupyter/jupyter_notebook_config.py && \
    chmod -R 775 /etc/jupyter/

# HEALTHCHECK documentation: https://docs.docker.com/engine/reference/builder/#healthcheck
# This healtcheck works well for `lab`, `notebook`, `nbclassic`, `server` and `retro` jupyter commands
# https://github.com/jupyter/docker-stacks/issues/915#issuecomment-1068528799
# HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
#     CMD /etc/jupyter/docker_healthcheck.py || exit 1

WORKDIR "${WORK_DIR}"
CMD ["[ -f /workspace/jupyter_server_config.json ]","&&","cp /workspace/jupyter_server_config.json /home/root/.jupyter/jupyter_server_config.json"]
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]





