FROM aiidateam/aiida-core:1.6.9

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

# Specify default factory reset (not set):
ENV AIIDALAB_FACTORY_RESET ""

# Configure environment.
ENV AIIDALAB_HOME /home/${SYSTEM_USER}
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
ENV AIIDALAB_DEFAULT_APPS "aiidalab-widgets-base~=1.0"

USER root
WORKDIR /opt/

# Install OS dependencies.
# Not clear whether libssl-dev and libffi-dev are still needed.
# povray needed for structure editor widget.
RUN apt-get update && apt-get install -y  \
    ca-certificates       \
    file                  \
    libssl-dev            \
    libffi-dev            \
    povray                \
    python3-pip           \
  && rm -rf /var/lib/apt/lists/*

# Dependencies needed for Jupyter Lab.
RUN apt-get update && apt-get install -y \
     nodejs                \
     npm                   \
  && rm -rf /var/lib/apt/lists/*

# Install ngrok to be able to proxy AiiDA RESTful API server.
# Currently not used by the home app, but used in tutorials
RUN wget --quiet -P /tmp/ \
  https://bin.equinox.io/a/dnxFaDKQgP4/ngrok-2.3.35-linux-amd64.zip \
  && unzip /tmp/ngrok-2.3.35-linux-amd64.zip \
  && mv ./ngrok /usr/local/bin/ \
  && rm -f /tmp/ngrok-2.3.35-linux-amd64.zip

# Get recent version of pip (needed for `pip cache` command).
# New pip executable is installed into /usr/local/bin
RUN /usr/bin/pip3 install --upgrade pip

# Jupyter dependencies installed into system python environment
# which runs the jupyter notebook server.
COPY requirements-server.txt .
RUN /usr/local/bin/pip install -r /opt/requirements-server.txt \
    && /usr/local/bin/pip cache purge

# Install and enable appmode.
RUN git clone https://github.com/oschuett/appmode.git && cd appmode && git reset --hard v0.8.0
COPY gears.svg ./appmode/appmode/static/gears.svg
RUN /usr/local/bin/pip install ./appmode
RUN /usr/local/bin/jupyter nbextension     enable --py --sys-prefix appmode
RUN /usr/local/bin/jupyter serverextension enable --py --sys-prefix appmode

# Install jupyterlab theme (takes about 4 minutes and 10 seconds).
#WORKDIR /opt/jupyterlab-theme
#RUN git clone https://github.com/aiidalab/jupyterlab-theme && \
#    cd jupyterlab-theme && \
#     npm install && \
#     npm run build && \
#     npm run build:webpack && \
#     npm pack ./ && \
#     /usr/local/bin/jupyter labextension install *.tgz && \
#    cd ..

## Configure user environment

# Install some useful packages that are not available on PyPi.
RUN conda install --yes -c conda-forge \
  openbabel==3.1.1 \
  rdkit==2021.09.2 \
  && conda clean --all

# Install AiiDAlab Python packages into user conda environment and populate reentry cache.
COPY requirements.txt .
ARG extra_requirements
RUN pip install --upgrade pip
RUN pip install -r requirements.txt $extra_requirements
RUN reentry scan

# Configure pip to use requirements file as constraints file.
RUN conda env config vars set PIP_CONSTRAINT=/opt/requirements.txt

# Install python kernel from the conda environment (comes with the aiidalab package).
RUN python -m ipykernel install


# Perform factory reset if needed.
COPY my_init.d/factory_reset.sh /etc/my_init.d/09_factory_reset.sh

# Prepare user's folders for AiiDAlab launch.
COPY opt/aiidalab-singleuser /opt/
COPY opt/prepare-aiidalab.sh /opt/
COPY my_init.d/prepare-aiidalab.sh /etc/my_init.d/80_prepare-aiidalab.sh

# Install the aiidalab-home app.
ARG aiidalab_home_version=v22.08.0
RUN git clone https://github.com/aiidalab/aiidalab-home && cd aiidalab-home && git checkout $aiidalab_home_version
RUN chmod 774 aiidalab-home

# Copy scripts to start Jupyter notebook.
COPY opt/start-notebook.sh /opt/
COPY service/jupyter-notebook /etc/service/jupyter-notebook/run

# Expose port 8888.
EXPOSE 8888

# Remove when the following issue is fixed: https://github.com/jupyterhub/dockerspawner/issues/319.
COPY my_my_init /sbin/my_my_init

CMD ["/sbin/my_my_init"]
