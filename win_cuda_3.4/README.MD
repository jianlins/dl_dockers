

* This folder contains environment.yml.
* Use action to build a conda environment using windows runner
* Zip the environment folder in multiple files and Upload as artifacts
* You can download these artifacts files and upload to air gap environment to use.

The pyspark 3.5.1 has mssqlserver driver issue, this is a rollback solution.

python=3.10
use https://github.com/huggingface/transformers/releases/tag/v4.48.0