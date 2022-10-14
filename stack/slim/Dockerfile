FROM mambaorg/micromamba:0.27-jammy
ARG NEW_MAMBA_USER=aiida
ARG NEW_MAMBA_USER_ID=1000
ARG NEW_MAMBA_USER_GID=1000

USER root
RUN usermod "--login=${NEW_MAMBA_USER}" "--home=/home/${NEW_MAMBA_USER}" \
        --move-home "-u ${NEW_MAMBA_USER_ID}" "${MAMBA_USER}" && \
    groupmod "--new-name=${NEW_MAMBA_USER}" \
             "-g ${NEW_MAMBA_USER_GID}" "${MAMBA_USER}" && \
    # Update the expected value of MAMBA_USER for the
    # _entrypoint.sh consistency check.
    echo "${NEW_MAMBA_USER}" > "/etc/arg_mamba_user" && \
    :

ENV MAMBA_USER=$NEW_MAMBA_USER

COPY _init.sh /usr/local/bin/_init.sh
RUN chmod +x /usr/local/bin/_init.sh

COPY prepare-aiida.sh /usr/local/bin/prepare-aiida.sh
RUN chmod +x /usr/local/bin/prepare-aiida.sh

COPY --chown=$MAMBA_USER:$MAMBA_USER env.yaml /tmp/env.yaml
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes

USER $MAMBA_USER

# Configure AiiDA profile.
COPY config-quick-setup.yaml /opt/config-quick-setup.yaml

# Configure AiiDA.
ENV SETUP_DEFAULT_AIIDA_PROFILE true
ENV AIIDA_PROFILE_NAME default
ENV AIIDA_USER_EMAIL aiida@localhost
ENV AIIDA_USER_FIRST_NAME Giuseppe
ENV AIIDA_USER_LAST_NAME Verdi
ENV AIIDA_USER_INSTITUTION Khedivial

# Make sure that the known_hosts file is present inside the .ssh folder.
RUN mkdir -p --mode=0700 /home/${MAMBA_USER}/.ssh && \
        touch /home/${MAMBA_USER}/.ssh/known_hosts

RUN /usr/local/bin/_entrypoint.sh ssh-keygen -f /home/${MAMBA_USER}/.ssh/id_rsa -t rsa -b 4096 -m PEM -N ''

WORKDIR /home/${MAMBA_USER}

ENTRYPOINT [ "/usr/local/bin/_init.sh" ]

