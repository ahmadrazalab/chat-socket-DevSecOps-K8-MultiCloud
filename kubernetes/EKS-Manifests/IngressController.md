### **Step 1: Install the AWS Load Balancer (ALB) Controller**
1. **Create an IAM Policy for ALB Controller**:
   Attach this policy to a new or existing IAM role used by the Kubernetes service account.

   ```bash
   curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
   aws iam create-policy \
     --policy-name AWSLoadBalancerControllerIAMPolicy \
     --policy-document file://iam-policy.json
   ```

2. **Associate the IAM Role to a Service Account**:
   ```bash
   eksctl utils associate-iam-oidc-provider --region <your-region> --cluster <your-cluster-name> --approve

   eksctl create iamserviceaccount \
     --cluster=<your-cluster-name> \
     --namespace=kube-system \
     --name=alb-ingress-controller \
     --attach-policy-arn=arn:aws:iam::<account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
     --region=<your-region> \
     --approve
   ```

3. **Install the ALB Controller via Helm**:
   ```bash
   helm repo add eks https://aws.github.io/eks-charts
   helm repo update

   helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
     --namespace kube-system \
     --set clusterName=<your-cluster-name> \
     --set serviceAccount.create=false \
     --set serviceAccount.name=alb-ingress-controller
   ```

4. **Verify Installation**:
   ```bash
   kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
   ```

---

### **Step 2: Deploy Ingress with Host-Based Routing**

### **Step 3: Enable TLS with Let's Encrypt**


#### Install cert-manager:
1. Install cert-manager for managing Let's Encrypt certificates.
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml
   ```

2. Verify cert-manager installation:
   ```bash
   kubectl get pods -n cert-manager
   ```

#### Create ClusterIssuer for Let's Encrypt:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: <your-email@example.com>
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
      - http01:
          ingress:
            class: alb
```

#### Update Ingress Manifest for TLS:
Update the `Ingress` to reference the Let's Encrypt certificate.

```yaml
spec:
  tls:
    - hosts:
        - chatapi.ahmadraza.in
        - chat.ahmadraza.in
      secretName: chat-app-tls
```

---

### **Step 4: Deploy and Verify**

1. Apply the Ingress manifest:
   ```bash
   kubectl apply -f chat-app-ingress.yaml
   ```

2. Verify that the ALB is created:
   ```bash
   kubectl describe ingress chat-app-ingress -n production
   ```

3. Check the ALB DNS name:
   ```bash
   kubectl get ingress -n production
   ```

   Use this DNS name to validate routing and SSL setup.
