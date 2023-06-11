Add jupyter notebook/lab into nvidia cuda image.

## installed locations: 
mamba: /opt/conda

> From https://blog.hpc.qmul.ac.uk/mamba.html:
> Anaconda has traditionally used conda as its package manager, but over time it has become quite slow at resolving dependencies when installing packages. mamba is a re-implementation of conda written in C++ offering the following benefits:
> * parallel downloading of repository data and package files using multi-threading
> * libsolv for much faster dependency solving, a state of the art library used in the RPM package manager of Red Hat, Fedora and OpenSUSE
> * core parts of mamba are implemented in C++ for maximum efficiency
> At the same time, mamba utilises the same command line parser, package installation code and transaction verification routines as conda to stay as compatible as possible.

This Dockfile tries to aggregate several layers of images provided by jupyter to make it easier to revise in one place. 

## working directory:  /workspace
mapping a volumn of external directory to /workspace is recommended.


## Change default values of configurable arguments. The following arguments can be configured when running "docker build"
ARG PYTHON_VERSION=3.8
ARG BASE_IMAGE="nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04"
ARG WORK_DIR="/workspace"
To change the value using the following format, e.g.: 
```docker build --build-arg PYTHON_VERSION=10 .```
A corresponding workflow file will be created later for easier use. N
Note: Even BASE_IMAGE is configurable, try use ubuntu based images only, for some of commands in the Dockerfile only work in Ubuntu distributions.


## Externalize conda environment configuration
If you only need to change some of the python packages, just edit the environment.yml if you are familiar with conda. Very minimal knowledge about docker is needed.
Note: in this Dockerfile configuration, all the packages will be installed to base environment for simplifying downstream executions. If you prefer not to run under base environment, you will be revise the Dockerfile accordingly.
