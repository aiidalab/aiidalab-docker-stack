# syntax=docker/dockerfile:1
FROM base

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

USER root
WORKDIR /opt/

ARG AIIDA_VERSION
ARG PGSQL_VERSION
ARG RMQ_VERSION
ARG TARGETARCH

# Location of the Postgresql DB
# This variable is automatically picked up by initdb and pg_ctl
# WARNING: If you change this, you have to change it in full-stack as well!
ENV PGDATA=/home/${NB_USER}/.postgresql

# Install RabbitMQ and PostgreSQL in a dedicated conda environment.
#
# RabbitMQ is currently not available on conda-forge for arm64, see:
# https://github.com/conda-forge/rabbitmq-server-feedstock/issues/67If
# Instead we need install erlang via apt and RabbitMQ as a "Generic Unix Build", see:
# https://www.rabbitmq.com/install-generic-unix.html
# Note that this version must be compatible with system's erlang version.
# Currently installed Erlang version is 23.3, so the latest supported RMQ version is 3.9.21
# https://www.rabbitmq.com/docs/which-erlang#old-timers
# Note that system erlang from arm64 is already installed in the base image,
# together with other APT dependencies to save build time.
RUN if [ "$TARGETARCH" = "amd64" ]; then \
     mamba create -p /opt/conda/envs/aiida-core-services --yes \
         postgresql=${PGSQL_VERSION} \
         rabbitmq-server=${RMQ_VERSION} && \
     mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}"; \
  elif [ "$TARGETARCH" = "arm64" ]; then \
     mamba create -p /opt/conda/envs/aiida-core-services --yes \
         postgresql=${PGSQL_VERSION} && \
     mamba clean --all -f -y && \
     wget -c https://github.com/rabbitmq/rabbitmq-server/releases/download/v${RMQ_VERSION}/rabbitmq-server-generic-unix-${RMQ_VERSION}.tar.xz && \
     tar -xf rabbitmq-server-generic-unix-${RMQ_VERSION}.tar.xz && \
     rm rabbitmq-server-generic-unix-${RMQ_VERSION}.tar.xz && \
     mv rabbitmq_server-${RMQ_VERSION} /opt/conda/envs/aiida-core-services/rabbitmq_server && \
     ln -sf /opt/conda/envs/aiida-core-services/rabbitmq_server/sbin/* /opt/conda/envs/aiida-core-services/bin/ && \
     fix-permissions "${CONDA_DIR}"; \
  fi

# Configure AiiDA profile.
COPY config-quick-setup.yaml .
COPY before-notebook.d/20_start-postgresql.sh /usr/local/bin/before-notebook.d/
COPY before-notebook.d/30_start-rabbitmq.sh /usr/local/bin/before-notebook.d/

# Supress rabbitmq version warning from aiida-core.
# AiiDA prints a warning for RabbitMQ versions >3.8, for which
# we explicitly set consumer_timeout to 100 hours in /etc/rabbitmq/rabbitmq.conf
COPY before-notebook.d/41_suppress-rabbitmq-version-warning.sh /usr/local/bin/before-notebook.d/

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"

# Initialize the database
RUN mamba run -n aiida-core-services initdb
