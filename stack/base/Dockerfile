ARG PYTHON_VERSION=3.9.4
FROM jupyter/minimal-notebook:python-${PYTHON_VERSION}

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

USER root
WORKDIR /opt/

ARG AIIDA_VERSION=2.0.0

# Install the shared requirements.
COPY requirements.txt .
RUN mamba install --yes \
     aiida-core=${AIIDA_VERSION} \
     --file requirements.txt \
     && mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"


# Pin shared requirements in the base environemnt.
RUN cat requirements.txt | xargs -I{} conda config --system --add pinned_packages {}

# Configure pip to use requirements file as constraints file.
ENV PIP_CONSTRAINT=/opt/requirements.txt

# Enable verdi autocompletion.
RUN mkdir -p "${CONDA_DIR}/etc/conda/activate.d" && \
     echo 'eval "$(_VERDI_COMPLETE=source verdi)"' >> "${CONDA_DIR}/etc/conda/activate.d/activate_aiida_autocompletion.sh" && \
     chmod +x "${CONDA_DIR}/etc/conda/activate.d/activate_aiida_autocompletion.sh" && \
     fix-permissions "${CONDA_DIR}"

# Configure AiiDA profile.
COPY config-quick-setup.yaml .
COPY before-notebook.d/prepare-aiida.sh /usr/local/bin/before-notebook.d/

# Configure AiiDA.
ENV SETUP_DEFAULT_AIIDA_PROFILE true
ENV AIIDA_PROFILE_NAME default
ENV AIIDA_USER_EMAIL aiida@localhost
ENV AIIDA_USER_FIRST_NAME Giuseppe
ENV AIIDA_USER_LAST_NAME Verdi
ENV AIIDA_USER_INSTITUTION Khedivial

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"

# Make sure that the known_hosts file is present inside the .ssh folder.
RUN mkdir -p --mode=0700 /home/${NB_USER}/.ssh && \
     touch /home/${NB_USER}/.ssh/known_hosts
