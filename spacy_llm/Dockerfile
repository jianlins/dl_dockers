# Use a slim Docker image with Python
FROM python:3.9-slim
LABEL maintainer="VA"

RUN apt-get update
#RUN apt-get install -y build-essential python-dev git  

RUN pip install --upgrade  pip 

RUN pip install -U pip setuptools wheel
RUN pip install -U 'spacy[cuda11x]'
RUN python -m spacy download en_core_web_trf
RUN python -m pip install spacy-llm

RUN pip install -U  notebook

#CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]





