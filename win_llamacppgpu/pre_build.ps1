param($location)
# This is a simple bash script that prints a message and the current date

# use my precompiled (with cuda enabled) wheel file
echo "pre build script tested"
# Invoke-WebRequest -Uri https://github.com/jianlins/llama-cpp-python/releases/download/main-cu118/llama_cpp_python-0.3.2-cp310-cp310-win_amd64.whl  -OutFile ".\llama_cpp_python-0.3.2-cp310-cp310-win_amd64.whl"
# pwd
# ls
# pip install "llama_cpp_python-0.3.2-cp310-cp310-win_amd64.whl" --verbose
# pip install -I "llama_cpp_python-0.3.2-cp310-cp310-win_amd64.whl[server]" --verbose