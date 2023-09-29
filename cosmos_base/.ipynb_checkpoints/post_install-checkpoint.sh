#!/bin/bash
# need devel image, which results over size error atm, 
# pip install git+https://github.com/NVIDIA/TransformerEngine.git@stable
# install python packages or models that not included when doing pip install or conda/mamaba install
python3 -c "import nltk; nltk.download('punkt');"
python3 -m spacy download en_core_web_sm

