# Autoscaling GitHub Actions runners using Azure Kubernetes Service

Deployment of [ARC](https://github.com/actions/actions-runner-controller) on
Azure kubernetes (AKS) for the [TLOmodel project](https://tlomodel.org), based
on the [original prototype](https://github.com/t-young31/gha-aks-prototype) by
[Tom Young](https://github.com/t-young31).

## Prerequisites

You need to install

* [GNU `make`](https://www.gnu.org/software/make/)
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Terraform](https://www.terraform.io/)
* [`kubectl`](https://kubernetes.io/docs/reference/kubectl/)

## Usage

1. Create a [fine-grained GitHub
   token](https://github.com/settings/tokens?type=beta) which can operate on the
   desired repository, and with the following permissions:
   * Read access to actions
   * Read and Write access to administration
1. Create a `.env` file from `.env.sample`
1. Login to Azure and deploy with
   ```bash
   make login
   make deploy
   ```

If you need to redeploy a new setup, you may have to destroy the previous
instance.  You can do that with
```bash
make destroy
```

## Troubleshooting

After deployment, you can list the available pods with

```sh
export KUBECONFIG=kubeconfig.yaml
kubectl get pods -A
```

Exporting `KUBECONFIG` is for being able to use `kubectl` correctly.

You should expect to have a controller, with name which includes `controller` in
it.  While a job is running, you should expect the runners among the pods, in
the `runners` namespace.

If something isn't working, you can check the log of the controller with the command

```sh
kubectl logs <CONTROLLER_NAME> -n <CONTROLLER_NAMESPACE>
```

where `<CONTROLLER_NAME>` and `<CONTROLLER_NAMESPACE>` are the name and
namespace you found with `kubectl get pods -A` above.
If you feel fancy you can try a single command like
```
kubectl logs $(kubectl get -n actions-runner-system pod | grep -v 'NAME'|cut -d' ' -f1) -n actions-runner-system
```

When you run `make deploy` to deploy again your Kubernetes service, it will try
first to delete the existing Kubernetes service, but if you deleted it via the Azure
web portal instead of using `make destroy`/`make deploy`, then terraform will
not find it and fail with something like
```
Plan: 9 to add, 0 to change, 1 to destroy.
╷
│ Error: Get "https://something.something.azmk8s.io:443/api/v1/namespaces/runners": dial tcp: lookup something.something.azmk8s.io on 193.60.250.1:53: no such host
│
│   with kubernetes_namespace.gha-ns,
│   on gha.tf line 56, in resource "kubernetes_namespace" "gha-ns":
│   56: resource "kubernetes_namespace" "gha-ns" {
│
╵
```
You can get a clean state to start from with
```
git clean -fxd infra/ kubeconfig.yaml
```
Make sure not to delete your `.env` file!

To check the status of a pod you can use the command
```
kubectl describe pod <POD_NAME> -n <NAMESPACE>
```
where `<POD_NAME>` is the name of pod and `<NAMESPACE>` is its namespace.
For example this can be useful to check the status of a runner that you can find
with `kubectl get runners -A`.


***Note***: there's a configuration about the [IP addresses allowed to use the
API
server](https://learn.microsoft.com/en-us/azure/aks/api-server-authorized-ip-ranges),
which is set when you run `make deploy`.  If you have an IP address different
from what you had when you deployed the service, then you may have errors like
```
% kubectl get runners -A
E1213 16:27:17.329486   42971 memcache.go:265] couldn't get current server API group list: Get "https://dns-k8s-test-82y64n61.hcp.uksouth.azmk8s.io:443/api?timeout=32s": dial tcp 20.108.89.37:443: i/o timeout
```
To fix this, you will have to either re-run a partial deploy to change the IP
address (but I don't know how to do that at the moment), or go to the Networking
settings of your Kubernetes services in Azure portal and change the allowed IP
ranges (it can be a comma-separated list of IP or ranges).
