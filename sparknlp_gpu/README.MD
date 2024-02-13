# Docker Image for SparkNLP
Built based on [https://sparknlp.org/docs/en/install#docker-support)](https://sparknlp.org/docs/en/install#docker-support), updated to later sparknlp and pyspark versions.
Because of conflict dependency (six) used by tensorflow 2.12.0 and scikit-spark, remove tensorflow from this image (spark people says it's only used for Visual NLP).
Current build  uses: pyspark==3.5.0, spark-nlp==5.2.0.
Based on my experiment, sparknlp doesn't work with torch. So no torch for this image either.

The built image is published here: [https://hub.docker.com/r/brokenjade/sparknlp_gpu](https://hub.docker.com/r/brokenjade/sparknlp_gpu)