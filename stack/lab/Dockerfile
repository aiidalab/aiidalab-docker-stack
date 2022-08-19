ARG VERSION=2022.1001
ARG BASE_IMAGE=aiidalab/base:${VERSION}
FROM ${BASE_IMAGE}

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

USER root
WORKDIR /opt/

ARG AIIDALAB_VERSION=22.08.0
RUN mamba install --yes \
     aiidalab=${AIIDALAB_VERSION} \
     && mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# Pin aiidalab version.
RUN echo "aiidalab==${AIIDALAB_VERSION}" >> /opt/requirements.txt
RUN conda config --system --add pinned_packages "aiidalab=${AIIDALAB_VERSION}"

# Install the aiidalab-home app.
ARG aiidalab_home_version=v22.08.0
RUN git clone https://github.com/aiidalab/aiidalab-home && \
     cd aiidalab-home && \
     git checkout "${aiidalab_home_version}" && \
     pip install --quiet --no-cache-dir "./" && \
     fix-permissions "./" && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# Install and enable appmode.
RUN git clone https://github.com/oschuett/appmode.git && \
     cd appmode && \
     git checkout v0.8.0
COPY gears.svg ./appmode/appmode/static/gears.svg
RUN pip install ./appmode --no-cache-dir && \
     jupyter nbextension enable --py --sys-prefix appmode && \
     jupyter serverextension enable --py --sys-prefix appmode

# Perform factory reset if needed.
COPY before-notebook.d/factory_reset.sh /usr/local/bin/before-notebook.d/

# Prepare user's folders for AiiDAlab launch.
COPY before-notebook.d/prepare-aiidalab.sh /usr/local/bin/before-notebook.d/

# Configure AiiDAlab environment.
ENV AIIDALAB_HOME /home/${NB_USER}
ENV AIIDALAB_APPS ${AIIDALAB_HOME}/apps
ENV AIIDALAB_DEFAULT_GIT_BRANCH master

# Specify which apps to install in addition to the home app. The
# AIIDALAB_DEFAULT_APPS variable should be a whitespace-delimited variable
# where each entry must follow the specifier format used by `aiidalab install`.
#
# Example for setting the AIIDALAB_DEFAULT_APPS variable:
#
#   AIIDALAB_DEFAULT_APPS="aiidalab-widgets-base quantum-espresso==20.12.0"
#
# Please note that multiple entries must be whitespace delimited.
# Please see `aiidalab install --help` for more information.
# ENV AIIDALAB_DEFAULT_APPS "aiidalab-widgets-base~=1.0"
ENV AIIDALAB_DEFAULT_APPS ""

# Specify default factory reset (not set):
ENV AIIDALAB_FACTORY_RESET ""

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"

RUN  mkdir -p /home/${NB_USER}/apps

# Switch to NOTEBOOK_ARGS approach (see below)
# for newer jupyter docker stack versions.
RUN echo 'c.NotebookApp.default_url="/apps/apps/home/start.ipynb"' >> /etc/jupyter/jupyter_notebook_config.py
# ENV NOTEBOOK_ARGS \
     # "--NotebookApp.default_url='/apps/apps/home/start.ipynb'" \
     # "--ContentsManager.allow_hidden=True"
