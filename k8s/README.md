# AiiDAlab on Kubernetes

## Deploy on a local Minikube (Kubernetes) cluster for testing

Here we provide instructions on how to run the stack on a local [Minikube Kubernetes cluster](https://minikube.sigs.k8s.io) for testing.

Using Minikube is one approach to deploy a small local Kubernetes cluster, however alternatives exist (e.g. [kind](https://kind.sigs.k8s.io/), k3s, colima).
If you are not using Minikube you may have to adjust the instructions provided here slightly.

First, [install Minikube](https://k8s-docs.netlify.app/en/docs/tasks/tools/install-minikube/) in your test environment and then start it, e.g., with `minikube start`.

If you want to test locally built images, make sure to build them within your test environment, with
```console
eval $(minikube docker-env)
doit build
```

Before installing the deployment for the first time, execute:

```console
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
```

Then execute `./k8s/helm-install.sh` to install AiiDAlab on the cluster.

To expose the web server, you need to create a tunnel with
```console
minikube tunnel
```

You should then be able to access the server at the address shown by
```console
kubectl get svc proxy-public
```

Tip: Use ngrok to forward the server to the internet and access it from a different machine.
**Please be advised that this approach carries significant security risk and should only be used for testing!**
