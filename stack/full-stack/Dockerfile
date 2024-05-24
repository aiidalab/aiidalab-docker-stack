# syntax=docker/dockerfile:1
ARG PGDATA_FOLDER
FROM base-with-services as base
ARG PGDATA_FOLDER

FROM lab

ARG PGDATA_FOLDER
ENV PGDATA=${PGDATA_FOLDER}

USER root

COPY --from=base /opt/config-quick-setup.yaml /opt/
COPY --from=base "${CONDA_DIR}/envs/aiida-core-services" "${CONDA_DIR}/envs/aiida-core-services"
COPY --from=base /usr/local/bin/before-notebook.d /usr/local/bin/before-notebook.d
COPY --from=base ${PGDATA} ${PGDATA}

RUN fix-permissions "${CONDA_DIR}"
RUN fix-permissions "/home/${NB_USER}/.aiida"

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"
