#!/bin/bash
if [[ -f "/workspace/jupyter_server_config.json" ]]; then
  cp /workspace/jupyter_server_config.json /home/root/.jupyter/jupyter_server_config.json
  echo "copy host jupyter_server_config.json to /home/root/.jupyter allow set token."
else
  echo "/workspace/jupyter_server_config.json does not exist. Will not copy to home directory." 
fi
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root