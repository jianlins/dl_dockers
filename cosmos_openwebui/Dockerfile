FROM ghcr.io/open-webui/open-webui:main
ENV HF_HOME="/app/onnx"
RUN mkdir -p /root/.cache/chroma/onnx_models/all-MiniLM-L6-v2
RUN python -c "import os; from sentence_transformers import SentenceTransformer; SentenceTransformer(os.environ['RAG_EMBEDDING_MODEL'], device='cpu')" && \
    python -c "import os; from faster_whisper import WhisperModel; WhisperModel(os.environ['WHISPER_MODEL'], device='cpu', compute_type='int8', download_root=os.environ['WHISPER_MODEL_DIR'])"; \
    python -c "import os; import tiktoken; tiktoken.get_encoding(os.environ['TIKTOKEN_ENCODING_NAME'])"; \    
    chown -R $UID:$GID /app/backend/data/

RUN ls /app/onnx

# copy embedding weight from build
