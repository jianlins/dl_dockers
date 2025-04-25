ARG UBUNTU_VERSION=22.04
# This needs to generally match the container host's environment.
ARG CUDA_VERSION=12.8.0
# check the available versions here: https://hub.docker.com/r/nvidia/cuda/
# Target the CUDA build image
ARG BASE_CUDA_DEV_CONTAINER=nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}
# Target the CUDA runtime image
ARG BASE_CUDA_RUN_CONTAINER=nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}

FROM ${BASE_CUDA_DEV_CONTAINER} AS build

# CUDA architecture to build for (defaults to all supported archs)
ARG CUDA_DOCKER_ARCH=default

RUN apt-get update && \
    apt-get install -y build-essential git cmake libcurl4-openssl-dev wget curl unzip p7zip jq

WORKDIR /app

https://github.com/ggml-org/llama.cpp/archive/refs/tags/b5191.zip

COPY . .
# Use explicit if conditions to target only the source code zip
RUN echo "Attempting to download source code zip from GitHub API..." && \
    if curl -sL --connect-timeout 10 https://api.github.com/repos/ggerganov/llama.cpp/releases/latest -o release.json; then \
        echo "Successfully contacted GitHub API"; \
        # Look specifically for the source code zip (typically the last zip_url in assets)
        if source_url=$(jq -r '.assets[] | select(.name | test("*refs/tags*zip$")) | .browser_download_url' release.json) && [ -n "$source_url" ] && [ "$source_url" != "null" ]; then \
            echo "Found source code URL: $source_url"; \
            if wget -O llamacpp.zip "$source_url"; then \
                echo "Successfully downloaded source code archive"; \
                unzip llamacpp.zip && \
                rm *.zip && \
                # The directory name may be different, so check what we got
                mv llama* llamacpp && \
                echo "Successfully extracted llama.cpp source code"; \
            else \
                echo "Failed to download source code archive, falling back to git clone"; \
                git clone --depth 1 https://github.com/ggml-org/llama.cpp.git llamacpp; \
            fi; \
        else \
            echo "Could not find source code zip in release assets, falling back to git clone"; \
            git clone --depth 1 https://github.com/ggml-org/llama.cpp.git llamacpp; \
        fi; \
    else \
        echo "Failed to contact GitHub API, falling back to git clone"; \
        git clone --depth 1 https://github.com/ggml-org/llama.cpp.git llamacpp; \
    fi && \
    rm -f release.json && \
    cp -r llamacpp/. /app && cd /app

RUN ls /app

# build full 
RUN if [ "${CUDA_DOCKER_ARCH}" != "default" ]; then \
        export CMAKE_ARGS="-DCMAKE_CUDA_ARCHITECTURES=${CUDA_DOCKER_ARCH}"; \
    fi && \
    cmake -B build -DGGML_NATIVE=OFF -DGGML_CUDA=ON -DLLAMA_CURL=ON ${CMAKE_ARGS} -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined . && \
    cmake --build build --config Release -j$(nproc) && \
    mkdir /llamacpp && \
    cp -a build/. /llamacpp && \
    cp build/bin/* .  
    
RUN find /app/build -name "*.so" -exec cp {} /llamacpp \;

# 1. **Search**: It searches the `build` directory and all its subdirectories for files with a `.so` extension.
# 2. **Execute**: For each `.so` file found, it executes the `cp` (copy) command to copy that file to the `/llamacpp` directory.

RUN pwd && ls

FROM ${BASE_CUDA_RUN_CONTAINER} AS runtime

RUN apt-get update && \
    apt-get install -y libcurl4-openssl-dev libgomp1 curl

COPY --from=build /app /app
COPY --from=build /llamacpp /llamacpp
COPY --from=build /app/build/bin/. /llamacpp
# COPY --from=build /llamacpp/*.so /
# COPY --from=build /app/build/bin/llama-server /llama-server
# COPY --from=build /app/build/bin/llama-cli /llama-cli

ENV PATH="/llamacpp:${PATH}"

# Must be set to 0.0.0.0 so it can listen to requests from host machine
ENV LLAMA_ARG_HOST=0.0.0.0

HEALTHCHECK CMD [ "curl", "-f", "http://localhost:8080/health" ]

CMD ["/llamacpp/llama-server"]