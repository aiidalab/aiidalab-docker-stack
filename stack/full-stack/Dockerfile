# syntax=docker/dockerfile:1
FROM base-with-services AS base

FROM lab

USER root

COPY --from=base /opt/config-quick-setup.yaml /opt/
COPY --from=base "${CONDA_DIR}/envs/aiida-core-services" "${CONDA_DIR}/envs/aiida-core-services"
COPY --from=base /usr/local/bin/before-notebook.d /usr/local/bin/before-notebook.d

RUN fix-permissions "${CONDA_DIR}"
RUN fix-permissions "/home/${NB_USER}/.aiida"

USER ${NB_USER}

# WARNING: If you change this, you have to change it in base-with-services as well
ENV PGDATA="/home/${NB_USER}/.postgresql"

# Initialize the database
RUN mamba run -n aiida-core-services initdb

WORKDIR "/home/${NB_USER}"
