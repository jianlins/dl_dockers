# Use a slim Docker image with Python
FROM python:3.9-slim
LABEL maintainer="VA"

RUN apt-get update
#RUN apt-get install -y build-essential python-dev git  

RUN pip3 install --upgrade --yes pip 

RUN pip3 install -U -y 'spacy[cuda11x,transformers,lookups]'
RUN python -m spacy download en_core_web_trf
RUN python -m pip3 install spacy-llm
RUN pip3 install -U -y notebook

CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8881", "--no-browser", "--allow-root"]





