ARG BASE
FROM ${BASE}

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

USER root

# build-essential: includes GCC compilers that are needed when building
# pip packages from sources, which often seems to happen for pymatgen:
# https://pymatgen.org/installation.html#installation-tips-for-optional-libraries
# rsync: needed to support the new AiiDA backup command
# povray: rendering engine used in aiidalab-widgets-base
ENV EXTRA_APT_PACKAGES "curl povray rsync build-essential"

# For ARM64 we need to install erlang as it is not available on conda-forge
# (this is needed later as rabbitmq dependency in base-with-services image,
# but we install it here so that we don't have to invoke apt multiple times.
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        EXTRA_APT_PACKAGES="erlang ${EXTRA_APT_PACKAGES}"; \
    fi;\
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends ${EXTRA_APT_PACKAGES} && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/

ARG AIIDA_VERSION
# Pin shared requirements in the base environment.
# We pin aiida-core to the exact installed version,
# to prevent accidental upgrade or downgrade, that might
# induce DB migration or break shared dependencies of AiiDAlab Apps.
RUN echo "aiida-core==${AIIDA_VERSION}" > /opt/requirements.txt

# Install aiida-core and other shared requirements.
RUN mamba install --yes \
     mamba-bash-completion \
     --file /opt/requirements.txt \
     && mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# Pin shared requirements in the conda base environment.
RUN cat /opt/requirements.txt | xargs -I{} conda config --system --add pinned_packages {}

# Upgrade pip to latest
RUN pip install --upgrade --no-cache-dir pip
# Configure pip to use requirements file as constraints file.
ENV PIP_CONSTRAINT /opt/requirements.txt
# Ensure that pip installs packages to ~/.local by default
ENV PIP_USER 1

# Enable verdi autocompletion.
RUN mkdir -p "${CONDA_DIR}/etc/conda/activate.d" && \
     echo 'eval "$(_VERDI_COMPLETE=bash_source verdi)"' >> "${CONDA_DIR}/etc/conda/activate.d/activate_aiida_autocompletion.sh" && \
     chmod +x "${CONDA_DIR}/etc/conda/activate.d/activate_aiida_autocompletion.sh" && \
     fix-permissions "${CONDA_DIR}"

# Configure AiiDA profile.
COPY config-quick-setup.yaml .
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/

# Configure AiiDA.
ENV SETUP_DEFAULT_AIIDA_PROFILE true
ENV AIIDA_PROFILE_NAME default
ENV AIIDA_USER_EMAIL aiida@localhost
ENV AIIDA_USER_FIRST_NAME Giuseppe
ENV AIIDA_USER_LAST_NAME Verdi
ENV AIIDA_USER_INSTITUTION Khedivial

# Install the load-singlesshagent.sh script as described here:
# https://aiida.readthedocs.io/projects/aiida-core/en/v2.0.0/howto/ssh.html#starting-the-ssh-agent
# The startup of this script is configured in the before-notebook.d/20_setup-ssh.sh file.
COPY load-singlesshagent.sh /opt/bin/

# Add ~/.local/bin to PATH where the dependencies get installed via pip
ENV PATH=${PATH}:/home/${NB_USER}/.local/bin

# Add conda envs_dirs in home directory,
# which will persist between container invocation
# NOTE: The order here is important!
# We want conda to create environments in ~/.conda/ by default
RUN conda config --system --add envs_dirs /opt/conda
RUN conda config --system --add envs_dirs "~/.conda/envs"

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"
