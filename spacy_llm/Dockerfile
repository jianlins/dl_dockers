FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
LABEL maintainer="VA"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -y git libsndfile1-dev tesseract-ocr espeak-ng python3 python3-pip ffmpeg
RUN python3 -m pip install --no-cache-dir --upgrade pip
RUN pip install -U  setuptools wheel


# If set to nothing, will install the latest version
# RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

ARG PYTORCH='2.2.1'
ARG TORCH_VISION=''
ARG TORCH_AUDIO=''
# Example: `cu102`, `cu113`, etc.
ARG CUDA='cu118'

COPY jupyter_server_config.py /etc/jupyter/
COPY start.sh /usr/local/bin/
RUN chmod 775 /usr/local/bin/*.sh


RUN [ ${#PYTORCH} -gt 0 ] && VERSION='torch=='$PYTORCH'.*' ||  VERSION='torch'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA
RUN [ ${#TORCH_VISION} -gt 0 ] && VERSION='torchvision=='TORCH_VISION'.*' ||  VERSION='torchvision'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA
RUN [ ${#TORCH_AUDIO} -gt 0 ] && VERSION='torchaudio=='TORCH_AUDIO'.*' ||  VERSION='torchaudio'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA

ARG REF=v4.38.1
RUN git clone https://github.com/huggingface/transformers && cd transformers && git checkout $REF
RUN python3 -m pip install --no-cache-dir -e ./transformers[dev-torch,testing,video]

RUN pip install -U 'spacy[cuda11x]'
RUN python3 -m spacy download en_core_web_trf
RUN pip install spacy-llm

RUN  pip install -U  notebook pandas jupyterlab


RUN nvcc --version
RUN which nvcc
RUN python3 --version
WORKDIR /workspace
CMD ["start.sh"]





