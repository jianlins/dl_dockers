# Use the latest version of PyTorch Lightning GPU as the base image
FROM pytorchlightning/pytorch_lightning:base-cuda-py3.8-torch2.0-cuda11.7.1

# Install JupyterLab and its dependencies
RUN pip install setuptools wheel jupyterlab Cython simpletransformers nltk bioc torchinfo imbalanced-learn medspacy medspacy_io scikit-learn jupytext pandas tqdm tensorboard pytest

# Set the default working directory to /app
WORKDIR /app

# Copy the content of the current directory into the container at /app
COPY . /app

# Expose port 8888 for JupyterLab
EXPOSE 8888

# Launch JupyterLab when the container starts
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--allow-root"]