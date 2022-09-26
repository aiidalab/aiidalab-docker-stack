# syntax=docker/dockerfile:1
FROM base

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

USER root
WORKDIR /opt/

ARG AIIDA_VERSION=2.0.4

RUN mamba create -n aiida-core-services --yes \
     aiida-core.services=${AIIDA_VERSION} \
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

RUN mamba install aiida-quantumespresso==4.0.1
RUN mamba install qe

RUN echo 'c.NotebookApp.default_url="/lab"' >> /etc/jupyter/jupyter_notebook_config.py
