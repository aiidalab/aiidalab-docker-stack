# Docker Stack for AiiDA lab

This repo contains the Docker file used in the [AiiDA lab](https://aiidalab.materialscloud.org).

## Deploy
To deploy changes, log into the AiiDA lab server and execute the following commands:
```
cd /home/ubuntu/aiidalab-docker-stack/
git pull
./build.sh
./inspect.sh  (optionally)
./activate.sh
```

The users will gradually pick up the new image, whenever they restart their container via the _Control Panel_.

## Cheat Sheet
- List running containers: `docker ps`
- List resource usage: `docker stats`
- View log of a container: `docker container logs  <container_id>`
- View JupyterHub log: `tail -f /var/log/syslog | grep jupyterhub`
- Restart JupyterHub: `sudo service jupyterhub restart`
- Restart Apache: `sudo apachectl graceful`

## Slow IO
To check for issues with OpenStack's block storage observe the following command for a **few minutes**:
```
watch -n 0.1 "ps axu| awk '{print \$8, \"   \", \$11}' | sort | head -n 10"
```
Pretty much all processes should be in the `S` state. If a process stays in the `D` state for a longer time it is most likely waiting for slow IO.

## Local Testing
In order to test the docker image locally, just clone this repository locally, and
```
./build.sh
./activate.sh
./inspect.sh
```

Inside the Docker image, try
```
su scientist
/opt/start-singleuser.sh
```

## Acknowledgements

This work is supported by the [MARVEL National Centre for Competency in Research](<http://nccr-marvel.ch>)
funded by the [Swiss National Science Foundation](<http://www.snf.ch/en>), as well as by the [MaX
European Centre of Excellence](<http://www.max-centre.eu/>) funded by the Horizon 2020 EINFRA-5 program,
Grant No. 676598.

![MARVEL](miscellaneous/logos/MARVEL.png)
![MaX](miscellaneous/logos/MaX.png)
