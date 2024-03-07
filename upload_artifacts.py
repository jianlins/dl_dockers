import os
import argparse
import requests

def parse_arguments():
    parser = argparse.ArgumentParser(description='Upload files from a specified folder to GitHub as artifacts.')
    parser.add_argument('source_folder', type=str, help='The source folder containing files to upload')
    parser.add_argument('--expire_days', type=int, default=5, help='The number of days until the artifact expires')
    return parser.parse_args()

def create_artifact(repo_owner, repo_name, artifact_name, expire_days, headers):
    url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/actions/artifacts'
    json_data = {
        'name': artifact_name,
        'expires_in': f'{expire_days} days'
    }
    response = requests.post(url, headers=headers, json=json_data)
    response.raise_for_status()
    return response.json()['url'], response.json()['upload_url']

def upload_artifact(upload_url, artifact_name, file_path, headers):
    with open(file_path, 'rb') as file:
        response = requests.post(upload_url, headers=headers, data=file, params={'name': artifact_name})
        response.raise_for_status()

def main():
    args = parse_arguments()
    source_folder = args.source_folder
    expire_days = args.expire_days
    
    GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
    REPO_OWNER = os.getenv('GITHUB_REPOSITORY_OWNER')
    REPO_NAME = os.getenv('GITHUB_REPOSITORY').split('/')[-1]
    headers = {
        'Authorization': f'token {GITHUB_TOKEN}',
        'Accept': 'application/vnd.github.v3+json',
    }
    
    for root, dirs, files in os.walk(source_folder):
        for filename in files:
            file_path = os.path.join(root, filename)
            artifact_name = os.path.basename(file_path)
            print(f'Uploading {artifact_name} from {file_path}')
            artifact_url, upload_url = create_artifact(REPO_OWNER, REPO_NAME, artifact_name, expire_days, headers)
            upload_artifact(upload_url, artifact_name, file_path, headers)

if __name__ == '__main__':
    main()
