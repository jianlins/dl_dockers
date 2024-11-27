param($location)
# This is a simple bash script that prints a message and the current date

echo 'done'
Write-Output "conda activate location: $location"
conda activate $location
nvcc --version

$cudaHome = "$envPath\Library"
[System.Environment]::SetEnvironmentVariable('CUDA_HOME', $cudaHome, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('CUDAToolkit_ROOT', $cudaHome, [System.EnvironmentVariableTarget]::User)


$currentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User)
$newPath = "$currentPath;$location\Library\bin"
[System.Environment]::SetEnvironmentVariable('Path', $newPath, [System.EnvironmentVariableTarget]::User)

Write-Output "CUDA_HOME has been set to: $cudaHome"
Write-Output "CUDAToolkit_ROOT has been set to: $cudaHome"
Write-Output "Updated PATH: $newPath"

$env:CMAKE_ARGS="-DGGML_CUDA=on"
pip install llama-cpp-python[server]