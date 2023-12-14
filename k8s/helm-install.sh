#!/bin/bash
set -e
set -u

VERSION=$(dunamai from git --dirty | sed 's/+/_/g')

helm upgrade aiidalab \
  jupyterhub/jupyterhub \
  --version=1.1.4 \
  --values k8s/values.dev.yml \
  --set singleuser.image.tag="${VERSION}" \
  --cleanup-on-fail \
  --install $@
