FROM brokenjade/nvidia_jupyter
LABEL maintainer="VA"

USER root


ARG openjdk_version="8"

# Spark dependencies
# Default values can be overridden at build time
# (ARGS are in lower case to distinguish them from ENV)
ARG spark_version="3.4.1"
ARG hadoop_version="3"
ARG scala_version
ARG spark_checksum="5a21295b4c3d1d3f8fc85375c711c7c23e3eeb3ec9ea91778f149d8d321e3905e2f44cf19c69a28df693cffd536f7316706c78932e7e148d224424150f18b2c5"


ENV APACHE_SPARK_VERSION="${spark_version}" \
    HADOOP_VERSION="${hadoop_version}" \
    NVTE_FRAMEWORK="pytorch"
    
# https://docs.nvidia.com/deeplearning/transformer-engine/user-guide/installation.html

# need build essential for some pip installs (only source code available.)
RUN apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*



WORKDIR /tmp
COPY environment.yml /tmp/environment.yml
COPY post_install.sh /tmp/post_install.sh


RUN mamba env update --file environment.yml
# -a, --all	Remove index cache, lock files, unused cache packages, and tarballs
# -f, --force-pkgs-dirs	Remove all writable package caches
# -y, --yes	Do not ask for confirmation
RUN mamba clean --all -f -y 
RUN pip cache purge



# install jdk, download models.
RUN chmod 770 /tmp/post_install.sh && \
    /tmp/post_install.sh


# Install Corretto JDK 8 or ${openjdk_version}
RUN wget https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.tar.gz
RUN tar xzf amazon-corretto-${openjdk_version}-x64-linux-jdk.tar.gz
RUN rm amazon-corretto-${openjdk_version}-x64-linux-jdk.tar.gz
RUN [ ! -d /usr/lib/jvm ] && mkdir /usr/lib/jvm
RUN mv amazon-corretto-${openjdk_version}.* /usr/lib/jvm/corretto


# Set Java environment variables
ENV JAVA_HOME=/usr/lib/jvm/corretto
ENV PATH=$PATH:$JAVA_HOME/bin



    
# Spark installation
# You need to use https://archive.apache.org/dist/ website if you want to download old Spark versions
# But it seems to be slower, that's why we use recommended site for download
RUN if [ -z "${scala_version}" ]; then \
    wget -qO "spark.tgz" "https://dlcdn.apache.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"; \
  else \
    wget -qO "spark.tgz" "https://dlcdn.apache.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}-scala${scala_version}.tgz"; \
  fi && \
  echo "${spark_checksum} *spark.tgz" | sha512sum -c - && \
  tar xzf "spark.tgz" -C /usr/local --owner root --group root --no-same-owner && \
  rm "spark.tgz"

# Configure Spark
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx8192M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH="${PATH}:${SPARK_HOME}/bin"

RUN if [ -z "${scala_version}" ]; then \
    ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" "${SPARK_HOME}"; \
  else \
    ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}-scala${scala_version}" "${SPARK_HOME}"; \
  fi && \
  # Add a link in the before_notebook hook in order to source automatically PYTHONPATH && \
  mkdir -p /usr/local/bin/before-notebook.d && \
  ln -s "${SPARK_HOME}/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh

# Configure IPython system-wide
COPY ipython_kernel_config.py "/etc/ipython/"
RUN chmod -R 775 "/etc/ipython/"

# clean tmp
RUN ls -l -a /tmp

WORKDIR "${WORK_DIR}"

EXPOSE 4040
EXPOSE 18080
EXPOSE 8081
EXPOSE 8080

