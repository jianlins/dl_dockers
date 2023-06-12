#!/bin/bash
# https://docs.nvidia.com/deeplearning/transformer-engine/user-guide/installation.html
NVTE_FRAMEWORK=pytorch pip install git+https://github.com/NVIDIA/TransformerEngine.git@stable
# install python packages or models that not included when doing pip install or conda/mamaba install
python3 -c "import nltk; nltk.download('punkt');"
python3 -m spacy download en_core_web_sm
python3 -c "import jdk;jdk.install('17', vendor='Corretto');"

