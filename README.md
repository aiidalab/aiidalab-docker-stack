# Docker Stack for AiiDA lab

This repo contains the Docker file used in the [AiiDA lab](https://www.materialscloud.org/aiidalab).

Docker images are available from Dockerhub via `docker pull aiidalab/aiidalab-docker-stack:latest`.

# Deploy on AiiDA lab server

To deploy changes, log into the AiiDA lab server and execute the following commands:
```
docker pull aiidalab/aiidalab-docker-stack:latest
docker tag aiidalab/aiidalab-docker-stack:latest aiidalab-docker-stack:latest
```
The users will gradually pick up the new image, whenever they restart their container via the _Control Panel_.

# Deploy locally

To run AiiDA lab image image locally, you first need to make sure that [Docker](https://www.docker.com/) is installed on your computer. Run `$ docker` in the command line and see if you get something like
```
Usage:	docker [OPTIONS] COMMAND

A self-sufficient runtime for containers

Options:
...
```

If this is the case, everything proceed with the next steps. Otherwise, please visit the [Docker installation page](http://www.docker.com/install) and install Docker on your machine.

To pull image from DockerHub and start the container do the following:
```
docker pull aiidalab/aiidalab-docker-stack:latest
mkdir ${HOME}/aiidalab # Create a new folder where your data vill be stored
docker run -d -p 8888:8888 -v ${HOME}/aiidalab:/home/aiida aiidalab/aiidalab-docker-stack:latest
# Note the Docker ID that was displayed after the last command and put it into the following run
./get_token.sh DOCKER_ID # This will display the authentication token once the container is ready.
```

To open AiiDA lab home page go to your browswer and type 'localhost:8888' in the address field. Jupyter will require
to provide the token use the one you've got when running `./get_token.sh DOCKER_ID`.

# Cheat Sheet

- List running containers: `docker ps`
- List resource usage: `docker stats`
- View log of a container: `docker container logs  <container_id>`
- View JupyterHub log: `tail -f /var/log/syslog | grep jupyterhub`
- Restart JupyterHub: `sudo service jupyterhub restart`
- Restart Apache: `sudo apachectl graceful`

# Slow IO

To check for issues with OpenStack's block storage observe the following command for a **few minutes**:
```
watch -n 0.1 "ps axu| awk '{print \$8, \"   \", \$11}' | sort | head -n 10"
```
Pretty much all processes should be in the `S` state. If a process stays in the `D` state for a longer time it is most likely waiting for slow IO.



# Acknowledgements

This work is supported by the [MARVEL National Centre for Competency in Research](<http://nccr-marvel.ch>)
funded by the [Swiss National Science Foundation](<http://www.snf.ch/en>), as well as by the [MaX
European Centre of Excellence](<http://www.max-centre.eu/>) funded by the Horizon 2020 EINFRA-5 program,
Grant No. 676598.

![MARVEL](miscellaneous/logos/MARVEL.png)
![MaX](miscellaneous/logos/MaX.png)
