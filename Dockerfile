FROM aiidalab-docker-stack

COPY my_my_init /sbin/my_my_init

CMD ["/sbin/my_my_init"]