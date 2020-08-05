# Docker Stack for AiiDA lab

This repo contains the Docker file used in the [AiiDA lab](https://www.materialscloud.org/aiidalab).

Docker images are available from Dockerhub via `docker pull aiidalab/aiidalab-docker-stack:latest`.
See [aiidalab/aiidalab-docker-stack](https://hub.docker.com/repository/docker/aiidalab/aiidalab-docker-stack) for a list of available tags.

# Deploy on AiiDA lab server

To deploy changes, log into the AiiDA lab server and execute the following commands:
```
docker pull aiidalab/aiidalab-docker-stack:latest
docker tag aiidalab/aiidalab-docker-stack:latest aiidalab-docker-stack:latest
```
The users will gradually pick up the new image, whenever they restart their container via the _Control Panel_.

# Deploy locally

Make sure that Docker is installed on your machine, otherwise go to [Docker installation page](http://www.docker.com/install)
and follow the instructions for your operating system.

Then, start AiiDA lab:
```
./run_aiidalab.sh PORT FOLDER_ABS_PATH
```

Where `PORT` is any free port on your machine (typically it is 8888) and `FOLDER_ABS_PATH` is an absolute path to the folder where user's data will be stored
(typically it is `${HOME}/aiidalab`).
The last line of the output of the command above will contain the link to access AiiDA lab in your browser.

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
