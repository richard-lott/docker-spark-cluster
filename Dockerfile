FROM openjdk:11.0.11-jre-slim-buster as builder

# Add install dependencies
RUN apt-get update \
&& apt-get install -y curl vim wget software-properties-common ssh net-tools ca-certificates build-essential \
    libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev

# Download and compile Python 3.10
RUN wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tgz \
&& tar xzf Python-3.10.6.tgz \
&& cd Python-3.10.6 \
&& ./configure --enable-optimizations \
&& make altinstall \
&& update-alternatives --install "/usr/bin/python" "python" "/usr/local/bin/python3.10" 1 \
&& update-alternatives --install "/usr/bin/python3" "python3" "/usr/local/bin/python3.10" 1

# PySpark dependencies
RUN apt-get install -y python3-numpy python3-matplotlib python3-scipy python3-pandas python3-simpy

# Fix the value of PYTHONHASHSEED
# Note: this is needed when you use Python 3.3 or greater
ENV SPARK_VERSION=3.4.0 \
HADOOP_VERSION=3 \
SPARK_HOME=/opt/spark \
PYTHONHASHSEED=1

RUN wget --no-verbose -O apache-spark.tgz "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" \
&& mkdir -p /opt/spark \
&& tar -xf apache-spark.tgz -C /opt/spark --strip-components=1 \
&& rm apache-spark.tgz


FROM builder as apache-spark

WORKDIR /opt/spark

ENV SPARK_MASTER_PORT=7077 \
SPARK_MASTER_WEBUI_PORT=8080 \
SPARK_LOG_DIR=/opt/spark/logs \
SPARK_MASTER_LOG=/opt/spark/logs/spark-master.out \
SPARK_WORKER_LOG=/opt/spark/logs/spark-worker.out \
SPARK_WORKER_WEBUI_PORT=8080 \
SPARK_WORKER_PORT=7000 \
SPARK_MASTER="spark://spark-master:7077" \
SPARK_WORKLOAD="master"

EXPOSE 8080 7077 7000

RUN mkdir -p $SPARK_LOG_DIR && \
touch $SPARK_MASTER_LOG && \
touch $SPARK_WORKER_LOG && \
ln -sf /dev/stdout $SPARK_MASTER_LOG && \
ln -sf /dev/stdout $SPARK_WORKER_LOG

COPY start-spark.sh /

CMD ["/bin/bash", "/start-spark.sh"]