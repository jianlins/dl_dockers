param($location)
# This is a simple bash script that prints a message and the current date

echo 'done'
Write-Output "conda activate location: $location"
conda activate $location
pip install -r requirements.txt