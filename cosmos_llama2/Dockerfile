FROM brokenjade/cosmos_base
LABEL maintainer="VA"

# need build essential for some pip installs (only source code available.)
RUN apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
    
COPY environment.yml /tmp/environment.yml

# RUN mamba env update --file /tmp/environment.yml && mamba clean --all -f -y 

RUN pip install git+https://github.com/facebookresearch/llama.git
# The following line does work for torch gpu
# RUN pip install --extra-index-url https://download.pytorch.org/whl/test/cu118 llama-recipes
RUN pip install git+https://github.com/facebookresearch/llama-recipes.git & pip cache purge

RUN mamba install -c conda-forge faiss-gpu && mamba clean --all -f -y 



