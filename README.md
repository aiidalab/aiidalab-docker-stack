# Docker Stack for Jupyter.MaterialsCloud.org

## Deploy
To deploy changes login into jupyter.materialscloud.org an execute the following commands:
```
cd /home/ubuntu/mc-docker-stack/
git pull
./build.sh
./inspect.sh  (optionally)
./activate.sh
```

The users will gradually pick up the new image, whenever they restart their container via the _Control Panel_.

## Cheat Sheet
- List running containers: `docker ps`
- List resource usage: `docker stats`
- View log of one container: `docker container logs  <container_id>`
- View JupyterHub log: `tail -f /var/log/syslog | grep jupyterhub`
- Restart JupyterHub: `sudo service jupyterhub restart`
- Restart Apache: `sudo apachectl graceful`

## Slow IO
To check for issues with OpenStack's block storage observe the following command for a **few minutes**:
```
watch -n 0.1 "ps axu| awk '{print \$8, \"   \", \$11}' | sort | head -n 10"
```
Pretty much all processes should be in the `S` state. If a process stays in the `D` state for a longer time it is most likely waiting for slow IO.