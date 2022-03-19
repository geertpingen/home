# pingen.dev

Holds configuration of Kubernetes cluster and services at `https://pingen.dev`.

## Projects

The following projects are hosted on the cluster:

- Portfolio website
- WIDP 2020

### Portfolio website

To add details.

### WIDP-2020

To add details.

## Automatic deployment

To automatically deploy the cluster, run:

``` shell
./infra.sh
```

> Note: Consider converting to Terraform-based setup

## Manual deployment

### Prepare node

On Hetzner instance, had to up `fs.inotify.max_user_watches` (default is 8192):

```shell
sysctl fs.inotify.max_user_watches=1048576
```

#### Floating IP for MetalLB

Following this guide to set up floating IP for MetalLB:

https://community.hetzner.com/tutorials/install-kubernetes-cluster

### Install k0s

```shell
k0s install controller --single -c cluster.yaml
k0s start
k0s status
```

#### Reconfiguration

Update `cluster.yaml` and restart `k0s` service:

```shell
sudo k0s stop
sudo k0s start
```

#### Export kubeconfig

Fetch kubeconfig:

```shell
k0s kubeconfig admin > ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config
k get node
```

### Core components

Running MetalLB, NGINX ingress controller and nfs provisioner.

#### MetalLB

Install MetalLB `v0.12.1` (https://metallb.universe.tf/installation/):

```
k apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
k apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
```

Create MetalLB config to start it:

```
k apply -f metallb-configmap.yaml
```

#### Cert-manager

Add cert-manager:

```shell
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml
```

Add TransIP DNS webhook and Secret (API key) to server:

```shell
helm install cert-manager-webhook-transip --namespace=cert-manager ./cert-manager-webhook-transip/deploy/transip-webhook
k -n cert-manager create secret generic transip-credentials --from-file=transip-key
```

Apply cert-manager issuers:

```shell
k apply -f ./cert-manager-issuers.yaml
```

#### Ingress controller

Currently using NGINX Ingress Controller v1.1.1: https://kubernetes.github.io/ingress-nginx/deploy/

```shell
k apply -f nginx-ingress-controller.yaml
```

#### Dynamic PV provisioning

Install nfs server:
```
mkdir -p /srv/nfs/kubedata
chown nobody:nogroup /srv/nfs/kubedata
apt update -y
apt install -y nfs-kernel-server nfs-common
systemctl enable nfs-kernel-server
systemctl start nfs-kernel-server
echo "/srv/nfs/kubedata *(rw,sync,no_subtree_check,no_root_squash,no_all_squash)" > /etc/exports
exportfs -rav
```

Install nfs subdir external provisioner: https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner

```shell
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=localhost \
    --set nfs.path=/srv/nfs/kubedata \
    -n nfs \
    --create-namespace
```
