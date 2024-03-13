FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
LABEL maintainer="VA"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -y git libsndfile1-dev tesseract-ocr espeak-ng python3 python3-pip ffmpeg
RUN python3 -m pip install --no-cache-dir --upgrade pip
RUN pip install -U  setuptools wheel

# If set to nothing, will install the latest version
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# ARG PYTORCH='2.0.0'
# ARG TORCH_VISION=''
# ARG TORCH_AUDIO=''
# # Example: `cu102`, `cu113`, etc.
# ARG CUDA='cu118'

# RUN [ ${#PYTORCH} -gt 0 ] && VERSION='torch=='$PYTORCH'.*' ||  VERSION='torch'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA
# RUN [ ${#TORCH_VISION} -gt 0 ] && VERSION='torchvision=='TORCH_VISION'.*' ||  VERSION='torchvision'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA
# RUN [ ${#TORCH_AUDIO} -gt 0 ] && VERSION='torchaudio=='TORCH_AUDIO'.*' ||  VERSION='torchaudio'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA


RUN pip install -U 'spacy[cuda11x]'
RUN python3 -m spacy download en_core_web_trf
RUN pip install spacy-llm

RUN  pip install -U  notebook pandas


#CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
RUN nvcc --version
RUN which nvcc
RUN python3 --version




