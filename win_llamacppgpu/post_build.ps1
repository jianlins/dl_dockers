# This is a simple bash script that prints a message and the current date
echo 'done'
echo "conda activate $args[0]"
conda activate $args[0]
$env:CMAKE_ARGS="-DGGML_CUDA=on"
pip install llama-cpp-python[server]
# git clone --recursive https://github.com/microsoft/T-MAC.git
# cd T-MAC
# pip install --no-input -r requirements.txt
# cd 3rdparty\tvm
# mkdir build
# cp cmake\config.cmake build
# cd build
# cmake .. -A x64
# cmake --build . --config Release -- /m
# cd ..\..\..\  # back to project root directory
# pwd
# ls
# $env:MANUAL_BUILD = "1"
# $env:PYTHONPATH = "$pwd\3rdparty\tvm\python"
# pip install . -v  # or pip install -e . -v