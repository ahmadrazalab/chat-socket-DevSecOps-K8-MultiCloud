# Ingress demonstration 
This is a demonstration of how to use Kubernetes Ingress to route traffic to different services in your cluster based on different paths.


## Install certificate manager
If you want to use HTTPS with your Ingress, you will need to install a certificate manager. Run the following command to install the Jetstack cert-manager:

```
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.yaml
```

This will install the cert-manager as a Deployment in your cluster.

## Create Clusterissuer
After you have installed the cert-manager, you can create a Clusterissuer to issue SSL certificates for your Ingress. Run the following commands to create the staging and production Clusterissuers:

```
kubectl apply -f prod_issuer.yaml
```

These commands will create two Clusterissuers, one for staging and one for production.

## Other Commands
Here are some other useful commands to help you manage your Kubernetes cluster:

#### To view deployments
```
kubectl get deploy
```
#### To view services
```
kubectl get svc
```
#### To view ingress
```
kubectl get ing
```
#### To describe ingress
```
kubectl describe ing <ing-name>
```
#### To view clusterissuer
```
kubectl get clusterissuer
```
#### To view certificate
```
kubectl get certificate
```
#### To describe certificate
```
kubectl describe certificate
```