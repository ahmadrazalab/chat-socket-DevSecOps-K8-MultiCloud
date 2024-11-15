# Chat Application Deployment Guide

This guide explains how to deploy the Chat Application across multiple cloud environments with HTTPS support.

![alt text](ChatAPP-EKS.png)

## Supported Cloud Platforms
- Amazon Elastic Kubernetes Service (EKS)
- Azure Kubernetes Service (AKS)
- DigitalOcean Kubernetes

## Prerequisites
- Kubernetes cluster set up on your chosen cloud platform
- `kubectl` CLI tool installed
- Access credentials configured for your cluster
- Domain name for HTTPS setup

## Deployment Structure
The deployment configurations are organized by cloud platform:
- `kubernetes/AKS-Deploy-Manifests/` - Azure Kubernetes Service configurations
- `kubernetes/EKS-Manifests/` - Amazon EKS configurations
- `kubernetes/DigitalOcean-Manifests/` - DigitalOcean Kubernetes configurations

## Common Components
All deployments include:
- Frontend application deployment
- Backend application deployment
- MongoDB database
- Load balancers
- Ingress controllers
- SSL/HTTPS configuration

## Deployment Instructions

### Amazon EKS Deployment
1. Create the namespace:
   ```bash
   kubectl apply -f kubernetes/EKS-Manifests/namespace.yaml
   ```

2. Apply configurations and secrets:
   ```bash
   kubectl apply -f kubernetes/EKS-Manifests/configmap.yaml
   kubectl apply -f kubernetes/EKS-Manifests/secret.yaml
   ```

3. Deploy MongoDB:
   ```bash
   kubectl apply -f kubernetes/EKS-Manifests/mongo-db-sec.yaml
   ```

4. Deploy backend and frontend:
   ```bash
   kubectl apply -f kubernetes/EKS-Manifests/backend-deployment.yaml
   kubectl apply -f kubernetes/EKS-Manifests/frontend-app.yaml
   ```

5. Configure ALB Ingress:
   - Update the cluster name in `aws-alb-ingress.yaml`
   - Update domain name if needed (current: chatapi.ahmadraza.in)
   ```bash
   kubectl apply -f kubernetes/EKS-Manifests/aws-alb-ingress.yaml
   ```

### Azure AKS Deployment
1. Deploy Application Gateway Ingress:
   - Update domain name if needed (current: chat.ahmadraza.in)
   ```bash
   kubectl apply -f kubernetes/AKS-Deploy-Manifests/azure-ag-ingress.yaml
   ```

### DigitalOcean Kubernetes Deployment
1. Deploy backend:
   ```bash
   kubectl apply -f kubernetes/DigitalOcean-Manifests/b-chatapp.yaml
   kubectl apply -f kubernetes/DigitalOcean-Manifests/b-lb-chatapp.yaml
   kubectl apply -f kubernetes/DigitalOcean-Manifests/svc-nodeport-b.yaml
   ```

2. Deploy frontend:
   ```bash
   kubectl apply -f kubernetes/DigitalOcean-Manifests/f-chatapp.yaml
   kubectl apply -f kubernetes/DigitalOcean-Manifests/f-lb-chatapp.yaml
   kubectl apply -f kubernetes/DigitalOcean-Manifests/svc-nodeport-f.yaml
   ```

## Application Access
After deployment, the application will be accessible via:
- EKS: https://chatapi.ahmadraza.in
- AKS: https://chat.ahmadraza.in
- DigitalOcean: Through configured load balancer IP/hostname

## SSL/HTTPS Configuration
- EKS: Uses AWS Certificate Manager (ACM) with ALB
- AKS: Uses Application Gateway with TLS termination
- DigitalOcean: Configure SSL through DO Load Balancer

## Monitoring and Maintenance
- Use kubectl to check deployment status:
  ```bash
  kubectl get pods -n <namespace>
  kubectl get svc -n <namespace>
  kubectl get ingress -n <namespace>
  ```

- Check logs:
  ```bash
  kubectl logs <pod-name> -n <namespace>
  ```

## Troubleshooting
1. If pods are not starting, check logs:
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   ```

2. If ingress is not working:
   ```bash
   kubectl describe ingress -n <namespace>
   ```

3. For networking issues:
   ```bash
   kubectl get events -n <namespace>
   ```

## Security Considerations
- All sensitive information is stored in Kubernetes secrets
- HTTPS is enabled for all external access
- Network policies should be configured as per your security requirements
- Regular updates and security patches should be applied

## Note
Remember to replace placeholder values like domain names and cluster names with your actual values before deployment.