This Dockefile was originally developed by HDAP team. Revised for VINCI NLP use on cosmos
This image inherent from [nvidia_jupyter](https://hub.docker.com/r/brokenjade/nvidia_jupyter): 
* has mamba installed
* externalize the package configuration in [environment.yml](https://github.com/jianlins/dl_dockers/blob/main/cosmos/environment.yml)
* download nlp models specified in [post_install.sh](https://github.com/jianlins/dl_dockers/blob/main/cosmos/post_install.sh)

The published image is here:  [[https://hub.docker.com/r/brokenjade/cosmos_base](https://hub.docker.com/r/brokenjade/cosmos_base)


## Updates from v1
upgrade pyspark to 3.5.0
add spark-nlp, gensim
add openssh-server --- will see if we can set vs code dev container directly connected.



Original Dockerfile:

```
FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu20.04
LABEL maintainer="VA"
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install -y git libsndfile1-dev tesseract-ocr espeak-ng python3 python3-pip ffmpeg
RUN python3 -m pip install --no-cache-dir --upgrade pip
ARG REF=v4.28.1
RUN git clone https://github.com/huggingface/transformers && cd transformers && git checkout $REF
RUN python3 -m pip install --no-cache-dir -e ./transformers[dev-torch,testing,video]
# If set to nothing, will install the latest version
ARG PYTORCH='2.0.0'
ARG TORCH_VISION=''
ARG TORCH_AUDIO=''
# Example: `cu102`, `cu113`, etc.
ARG CUDA='cu117'
RUN [ ${#PYTORCH} -gt 0 ] && VERSION='torch=='$PYTORCH'.*' ||  VERSION='torch'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA
RUN [ ${#TORCH_VISION} -gt 0 ] && VERSION='torchvision=='TORCH_VISION'.*' ||  VERSION='torchvision'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA
RUN [ ${#TORCH_AUDIO} -gt 0 ] && VERSION='torchaudio=='TORCH_AUDIO'.*' ||  VERSION='torchaudio'; python3 -m pip install --no-cache-dir -U $VERSION --extra-index-url https://download.pytorch.org/whl/$CUDA
RUN python3 -m pip uninstall -y tensorflow flax
RUN python3 -m pip install --no-cache-dir git+https://github.com/facebookresearch/detectron2.git pytesseract
RUN python3 -m pip install -U "itsdangerous<2.1.0"
# When installing in editable mode, `transformers` is not recognized as a package.
# this line must be added in order for python to be aware of transformers.
RUN cd transformers && python3 setup.py develop
RUN python3 -m pip install -U "accelerate==0.18.0"
RUN python3 -m pip install -U "bitsandbytes==0.38.1"
```

Because image size will affect successful push to and pull from docker hub. Set the base Dl env as cosmos_base. Turn other dependencies into other decedent images.