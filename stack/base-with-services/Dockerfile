# syntax=docker/dockerfile:1
FROM base

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

USER root
WORKDIR /opt/

ARG PGSQL_VERSION
ARG RMQ_VERSION

# Location of the Postgresql DB
# This variable is automatically picked up by initdb and pg_ctl
# WARNING: If you change this, you have to change it in full-stack as well!
ENV PGDATA=/home/${NB_USER}/.postgresql

# Install RabbitMQ and PostgreSQL in a dedicated conda environment.
RUN mamba create -p /opt/conda/envs/aiida-core-services --yes \
        postgresql=${PGSQL_VERSION} \
        rabbitmq-server=${RMQ_VERSION} && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}"

# Configure AiiDA profile.
COPY config-quick-setup.yaml .
COPY before-notebook.d/20_start-postgresql.sh /usr/local/bin/before-notebook.d/
COPY before-notebook.d/30_start-rabbitmq.sh /usr/local/bin/before-notebook.d/

# Configure RabbitMQ
COPY configure_rabbitmq.sh .
RUN ./configure_rabbitmq.sh

# Supress rabbitmq version warning from aiida-core.
# AiiDA prints a warning for RabbitMQ versions >3.8, for which
# we explicitly set consumer_timeout to 100 hours in /etc/rabbitmq/rabbitmq.conf
COPY before-notebook.d/41_suppress-rabbitmq-version-warning.sh /usr/local/bin/before-notebook.d/

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"

# Initialize the database
RUN mamba run -n aiida-core-services initdb
