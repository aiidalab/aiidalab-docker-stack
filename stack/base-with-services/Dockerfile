# syntax=docker/dockerfile:1
FROM base

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

USER root
WORKDIR /opt/

ARG AIIDA_VERSION
ARG PGSQL_VERSION
ARG TARGETARCH

# Install RabbitMQ and PostgreSQL in a dedicated conda environment.
#
# RabbitMQ is not available on conda-forge at the time being, see:
# https://github.com/conda-forge/rabbitmq-server-feedstock/issues/67If
# Instead we need install erlang via apt and RabbitMQ as a "Generic Unix Build", see:
# https://www.rabbitmq.com/install-generic-unix.html
# Note that this version must be compatible with system's erlang version.
# Note that system erlang from arm64 is already installed in the base image,
# together with other APT dependencies to save build time.
RUN if [ "$TARGETARCH" = "amd64" ]; then \
     mamba create -p /opt/conda/envs/aiida-core-services --yes \
         postgresql=${PGSQL_VERSION} \
         rabbitmq-server=3.8.14  && \
     mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"; \
elif [ "$TARGETARCH" = "arm64" ]; then \
     mamba create -p /opt/conda/envs/aiida-core-services --yes \
         postgresql=${PGSQL_VERSION} \
     mamba clean --all -f -y && \
     export RMQ_VERSION=3.9.13 && \
     wget -c https://github.com/rabbitmq/rabbitmq-server/releases/download/v${RMQ_VERSION}/rabbitmq-server-generic-unix-${RMQ_VERSION}.tar.xz && \
     tar -xf rabbitmq-server-generic-unix-${RMQ_VERSION}.tar.xz && \
     rm rabbitmq-server-generic-unix-${RMQ_VERSION}.tar.xz && \
     mv rabbitmq_server-${RMQ_VERSION} /opt/conda/envs/aiida-core-services/ && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"; \
     ln -sf /opt/conda/envs/aiida-core-services/rabbitmq_server-${RMQ_VERSION}/sbin/* /opt/conda/envs/aiida-core-services/bin/; \
fi

# Configure AiiDA profile.
COPY config-quick-setup.yaml .
COPY before-notebook.d/20_start-postgresql.sh /usr/local/bin/before-notebook.d/
COPY before-notebook.d/30_start-rabbitmq-${TARGETARCH}.sh /usr/local/bin/before-notebook.d/

# Supress rabbitmq version warning from aiida-core.
# This is needed for the arm64 build which uses RabbitMQ version >3.8, for which
# we explicitly set consumer_timeout to 100 hours in /etc/rabbitmq/rabbitmq.conf
COPY before-notebook.d/41_suppress-rabbitmq-version-warning.sh /usr/local/bin/before-notebook.d/
RUN if [ "$TARGETARCH" = "amd64" ]; then \
     rm /usr/local/bin/before-notebook.d/41_suppress-rabbitmq-version-warning.sh; \
fi

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"

# Initialize the database
RUN mamba run -n aiida-core-services initdb -D aiida_db -U aiida
