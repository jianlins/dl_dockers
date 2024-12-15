param($location)
# This is a simple bash script that prints a message and the current date

echo 'done'
Write-Output "conda activate location: $location"
conda activate $location
nvcc --version
$cudaHome = "$location\Library"
$cudaInclude ="$cudaHome\include"
[System.Environment]::SetEnvironmentVariable('CUDA_HOME', $cudaHome, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('CUDAToolkit_ROOT', $cudaInclude, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('CUDAToolkit_INCLUDE_DIRECTORIES', $cudaInclude, [System.EnvironmentVariableTarget]::User)

$currentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User)
$newPath = "$currentPath;$location\Library\bin;$location\bin"
[System.Environment]::SetEnvironmentVariable('Path', $newPath, [System.EnvironmentVariableTarget]::User)

Write-Output "CUDA_HOME has been set to: $cudaHome"
Write-Output "CUDAToolkit_ROOT has been set to: $cudaHome"
Write-Output "CUDAToolkit_INCLUDE_DIRECTORIES has been set to: $cudaInclude"
Write-Output "Updated PATH: $newPath"

# use my precompiled (with cuda enabled) wheel file
# Invoke-WebRequest -Uri https://github.com/jianlins/llama-cpp-python/releases/download/main-cu118/llama_cpp_python-0.3.2-cp310-cp310-win_amd64.whl  -OutFile ".\llama_cpp_python-0.3.2-cp310-cp310-win_amd64.whl"
# pwd
# ls
# [System.Environment]::SetEnvironmentVariable('DGGML_BLAS', 'ON', [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('DGGML_CUDA', 'on', [System.EnvironmentVariableTarget]::User)
pip install "llama_cpp_python[server]" --verbose
python -c "import llama_cpp; print(llama_cpp.__version__);"