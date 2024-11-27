param($location)
# This is a simple bash script that prints a message and the current date

echo 'done'
echo "conda activate location:" $location
conda activate $location

[System.Environment]::SetEnvironmentVariable('CUDA_HOME', '$location\Library', [System.EnvironmentVariableTarget]::User)
$currentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User)
$newPath = "$currentPath;$location\Library\bin"
[System.Environment]::SetEnvironmentVariable('Path', $newPath, [System.EnvironmentVariableTarget]::User)

Write-Output "CUDA_HOME has been set to: $env:CUDA_HOME"
Write-Output "Updated Path: $env:Path"

$env:CMAKE_ARGS="-DGGML_CUDA=on"
pip install llama-cpp-python[server]