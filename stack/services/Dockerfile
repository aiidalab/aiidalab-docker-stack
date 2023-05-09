# syntax=docker/dockerfile:1
ARG BASE
FROM ${BASE}

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

USER root
WORKDIR /opt/

ARG AIIDA_VERSION
ARG PGSQL_VERSION

RUN mamba create -p /opt/conda/envs/aiida-core-services --yes \
     postgresql=${PGSQL_VERSION} \
     rabbitmq-server=3.8.14 \
     && mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# Configure AiiDA profile.
COPY config-quick-setup.yaml .
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"

# Initialize the database
RUN mamba run -n aiida-core-services initdb -D aiida_db -U aiida
