# syntax=docker/dockerfile:1
FROM base-with-services as base

FROM lab

USER root

COPY --from=base /opt/config-quick-setup.yaml /opt/
COPY --from=base "${CONDA_DIR}/envs/aiida-core-services" "${CONDA_DIR}/envs/aiida-core-services"
COPY --from=base /usr/local/bin/before-notebook.d /usr/local/bin/before-notebook.d

# This is needed because we use multi-stage build,
# the erlang package is not available after the first stage.
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
    # Install erlang.
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends erlang && \
    apt-get clean && rm -rf /var/lib/apt/lists/*; \
fi

RUN fix-permissions "${CONDA_DIR}"
RUN fix-permissions "/home/${NB_USER}/.aiida"

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"
