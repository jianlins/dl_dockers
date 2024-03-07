import os
import requests
from glob import glob

def upload_artifact(token, repo, run_id, artifact_name, file_path):
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json"
    }
    # Create an artifact
    create_artifact_url = f"https://api.github.com/repos/{repo}/actions/runs/{run_id}/artifacts"
    response = requests.post(create_artifact_url, headers=headers, json={"name": artifact_name})
    response.raise_for_status()
    upload_url = response.json()["upload_url"]

    # Upload the file to the artifact
    with open(file_path, 'rb') as f:
        files = {'file': (os.path.basename(file_path), f)}
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.post(upload_url, headers=headers, files=files)
        response.raise_for_status()

if __name__ == "__main__":
    token = os.getenv("GITHUB_TOKEN")
    repo = os.getenv("GITHUB_REPOSITORY")
    run_id = os.getenv("GITHUB_RUN_ID")

    for file_path in glob(f"./*.7z.*"):
        artifact_name = os.path.basename(file_path)
        upload_artifact(token, repo, run_id, artifact_name, file_path)
