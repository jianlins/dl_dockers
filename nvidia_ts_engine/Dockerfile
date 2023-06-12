ARG BASE_IMAGE="nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04"
FROM ${BASE_IMAGE}


ARG PYTHON_VERSION=3.8

# make the working dir shorter so that it's easier type when mapping volumns or operating files.
ARG WORK_DIR="/workspace"



#sets the user context for subsequent instructions in the Dockerfile to the "root" user.
USER root

# It specifies that the shell to be used is "/bin/bash" and includes the options "-o pipefail -c".
# Here's a breakdown of the options:
# -o pipefail: This option is used in Bash to set the pipefail option, which makes a pipeline of commands fail if any command in the pipeline fails. By default, only the exit status of the last command in the pipeline is considered. With pipefail enabled, the pipeline fails if any command within the pipeline fails, allowing better error handling in scripts.
# -c: This option is used to specify that the subsequent command or commands should be executed by the shell. It allows you to provide a command or script to be executed by the shell, rather than directly executing a file.
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]


RUN nvcc --version
RUN which nvcc