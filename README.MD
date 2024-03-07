Use Dockerfile and github action to create and publish images on docker hub.

For folders named "win_xxx", the action: build_win_env will create a conda environment specified by the corresponding environment.yml inside that folder using windows runner, and zip the created environment folder upload to this repo as artifacts. So that you can download them and use them in an air-gap environment later. 
