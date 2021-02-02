FROM aiidateam/aiida-core:1.5.2

LABEL maintainer="Materials Cloud Team <aiidalab@materialscloud.org>"

# Configure environment.
ENV AIIDALAB_HOME /home/${SYSTEM_USER}
ENV AIIDALAB_APPS ${AIIDALAB_HOME}/apps
ENV AIIDALAB_DEFAULT_GIT_BRANCH master

USER root

# Install OS dependencies.
RUN apt-get update && apt-get install -y  \
    ca-certificates       \
    cp2k                  \
    file                  \
    libssl-dev            \
    libffi-dev            \
    povray                \
    python3-pip           \
    python3-setuptools    \
    python3-wheel         \
    quantum-espresso      \
  && rm -rf /var/lib/apt/lists/*

# Install what is needed for Jupyter Lab.
RUN apt-get update && apt-get install -y \
     nodejs                \
     npm                   \
  && rm -rf /var/lib/apt/lists/*

# Install Jupyter-related things in the root environment.
RUN /usr/bin/pip3 install          \
    'jupyterhub==1.3.0'            \
    'jupyterlab==3.0.5'            \
    'notebook==6.2.0'

# Install ngrok to be able to proxy AiiDA RESTful API server.
RUN wget --quiet -P /tmp/ \
  https://bin.equinox.io/a/dnxFaDKQgP4/ngrok-2.3.35-linux-amd64.zip \
  && unzip /tmp/ngrok-2.3.35-linux-amd64.zip \
  && mv ./ngrok /usr/local/bin/ \
  && rm -f /tmp/ngrok-2.3.35-linux-amd64.zip

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

# Change workdir.
WORKDIR /opt/

# Install Python packages needed for AiiDAlab and populate reentry cache for root (https://pypi.python.org/pypi/reentry/).
COPY requirements.txt .
RUN pip install -r requirements.txt
RUN reentry scan

# Install python kernel from the conda environment (comes with the aiidalab package).
RUN python -m ipykernel install

# Install and enable nbserverproxy.
RUN /usr/bin/pip3 install nbserverproxy==0.8.8
RUN /usr/local/bin/jupyter serverextension enable --py --sys-prefix nbserverproxy

# Install and enable nglview.
RUN /usr/bin/pip3 install nglview==2.7.7
RUN /usr/local/bin/jupyter nbextension enable nglview --py --sys-prefix

# Install and enable appmode.
RUN git clone https://github.com/oschuett/appmode.git && cd appmode && git reset --hard v0.8.0
COPY gears.svg ./appmode/appmode/static/gears.svg
RUN /usr/bin/pip3 install ./appmode
RUN /usr/local/bin/jupyter nbextension     enable --py --sys-prefix appmode
RUN /usr/local/bin/jupyter serverextension enable --py --sys-prefix appmode

# Install and enable bqplot.
RUN /usr/bin/pip3 install bqplot
RUN /usr/local/bin/jupyter nbextension install --py --symlink --sys-prefix bqplot
RUN /usr/local/bin/jupyter nbextension enable bqplot --py --sys-prefix

# Install voila package and AiiDAlab voila template.
RUN /usr/bin/pip3 install voila==0.2.6
RUN /usr/bin/pip3 install voila-aiidalab-template==0.2.1

# Enable widget_periodictable (installed with aiidalab package).
RUN /usr/bin/pip3 install widget-periodictable==2.1.5
RUN /usr/local/bin/jupyter nbextension install --py --user widget_periodictable
RUN /usr/local/bin/jupyter nbextension enable widget_periodictable --user --py

# Enable ipywidgets-extended.
RUN /usr/bin/pip3 install ipywidgets-extended==1.0.5 && \
  /usr/local/bin/jupyter nbextension install --py --user ipywidgets_extended && \
  /usr/local/bin/jupyter nbextension enable --py --user ipywidgets_extended

# Install and enable ipytree.
RUN /usr/bin/pip3 install ipytree==0.1.8 && \
  /usr/local/bin/jupyter nbextension install --py --user ipytree && \
  /usr/local/bin/jupyter nbextension enable --py --user ipytree

# Install some useful packages that are not available on PyPi.
# The 2020.09.2 version of rdkit introduced an implicit dependency on tornado>=6.
RUN conda install --yes -c conda-forge \
  openbabel==3.1.1 \
  rdkit==2020.09.1 \
  && conda clean --all

# Prepare user's folders for AiiDAlab launch.
COPY opt/aiidalab-singleuser /opt/
COPY opt/prepare-aiidalab.sh /opt/
COPY my_init.d/prepare-aiidalab.sh /etc/my_init.d/80_prepare-aiidalab.sh

# Get aiidalab-home app.
RUN git clone https://github.com/aiidalab/aiidalab-home && cd aiidalab-home && git reset --hard v20.11.0
RUN chmod 774 aiidalab-home

# Copy scripts to start Jupyter notebook.
COPY opt/start-notebook.sh /opt/
COPY service/jupyter-notebook /etc/service/jupyter-notebook/run

# Expose port 8888.
EXPOSE 8888

# Remove when the following issue is fixed: https://github.com/jupyterhub/dockerspawner/issues/319.
COPY my_my_init /sbin/my_my_init

CMD ["/sbin/my_my_init"]
