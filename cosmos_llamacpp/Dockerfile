# previous configuration was adopted from main branch which original using CUDA 12. Although it built succesfully, however, it seems not using gpu.
# This version start from https://github.com/ggerganov/llama.cpp/blob/a77feb5d71831c61e455541e8a655b9f0337ea8c/.devops/llama-server-cuda.Dockerfile which original use cuda11.7.1
ARG UBUNTU_VERSION=22.04
# This needs to generally match the container host's environment.
ARG CUDA_VERSION=11.8.0
# Target the CUDA build image
ARG BASE_CUDA_DEV_CONTAINER=nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}
# Target the CUDA runtime image
ARG BASE_CUDA_RUN_CONTAINER=nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}

FROM ${BASE_CUDA_DEV_CONTAINER} AS build

# Unless otherwise specified, we make a fat build.
ARG CUDA_DOCKER_ARCH=all

RUN apt-get update && \
    apt-get install -y build-essential git cmake libcurl4-openssl-dev wget curl unzip

WORKDIR /app

COPY . .
# git clone llama cpp repo
RUN wget https://github.com/ggerganov/llama.cpp/archive/refs/tags/b4153.zip -O llamacpp.zip && ls && unzip llamacpp.zip && rm *.zip && ls &&  mv llama.cpp* llamacpp
RUN cp -R llamacpp/* /app/* && cd /app

RUN ls /app


# Set nvcc architecture
ENV CUDA_DOCKER_ARCH=${CUDA_DOCKER_ARCH}
# Enable CUDA
ENV GGML_CUDA=1
# Enable cURL
ENV LLAMA_CURL=1
# Must be set to 0.0.0.0 so it can listen to requests from host machine
ENV LLAMA_ARG_HOST=0.0.0.0

RUN make -j$(nproc) llama-server

FROM ${BASE_CUDA_RUN_CONTAINER} AS runtime

RUN apt-get update && \
    apt-get install -y libcurl4-openssl-dev libgomp1 curl

COPY --from=build /app/llama-server /llama-server

HEALTHCHECK CMD [ "curl", "-f", "http://localhost:8080/health" ]

CMD [ "/llama-server" ]

# Use the default CUDA archs if not specified
# RUN if [ "${CUDA_DOCKER_ARCH}" != "default" ]; then \
#         export CMAKE_ARGS="-DCMAKE_CUDA_ARCHITECTURES=${CUDA_DOCKER_ARCH}"; \
#     fi && \
#     cmake -B build -DGGML_CUDA=ON -DLLAMA_CURL=ON ${CMAKE_ARGS} -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined . && \
#     cmake --build build --config Release --target llama-server -j$(nproc)

# RUN pwd && ls

# FROM ${BASE_CUDA_RUN_CONTAINER} AS runtime

# RUN apt-get update && \
#     apt-get install -y libcurl4-openssl-dev libgomp1 curl

# COPY --from=build /app/build/ggml/src/libggml.so /libggml.so
# COPY --from=build /app/build/src/libllama.so /libllama.so
# COPY --from=build /app/build/bin/llama-server /llama-server

# # Must be set to 0.0.0.0 so it can listen to requests from host machine
# ENV LLAMA_ARG_HOST=0.0.0.0

# HEALTHCHECK CMD [ "curl", "-f", "http://localhost:8080/health" ]

# CMD [ "/llama-server" ]