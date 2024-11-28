param($location)
# This is a simple bash script that prints a message and the current date

# use my precompiled (with cuda enabled) wheel file
Invoke-WebRequest -Uri https://github.com/jianlins/llama-cpp-python/releases/download/main-cu118/llama_cpp_python-0.3.2-cp310-cp310-win_amd64.whl  -OutFile ".\llama_cpp_python.whl"
pwd
ls
pip install "llama_cpp_python.whl" --verbose
pip install "llama_cpp_python.whl[server]" --verbose