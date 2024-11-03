
# Integrate AWS Secrets Manager with your Kubernetes applications, 

### Step 1: Set Up IAM Permissions for EKS to Access AWS Secrets Manager

#### 1.1 Create an IAM Policy for Secrets Manager Access

First, create an IAM policy that grants access to the secrets in AWS Secrets Manager. This policy will later be attached to an IAM role used by your EKS pods.

1. **Create a policy** that allows access to your specific secrets in AWS Secrets Manager:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "secretsmanager:GetSecretValue"
         ],
         "Resource": [
           "arn:aws:secretsmanager:your-region:your-account-id:secret:your-secret-name*"
         ]
       }
     ]
   }
   ```

2. Save this policy as `eks-secrets-access-policy.json` and create it using the AWS CLI:

   ```bash
   aws iam create-policy \
     --policy-name eks-secrets-access-policy \
     --policy-document file://eks-secrets-access-policy.json
   ```

#### 1.2 Create an IAM Role for the Kubernetes Service Account

1. **Create an IAM role** that allows EKS to assume the policy:

   ```bash
   aws iam create-role \
     --role-name eks-secrets-access-role \
     --assume-role-policy-document file://eks-trust-policy.json
   ```

   Your `eks-trust-policy.json` should look like this:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "eks.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   ```

2. **Attach the secrets access policy** to the role:

   ```bash
   aws iam attach-role-policy \
     --policy-arn arn:aws:iam::your-account-id:policy/eks-secrets-access-policy \
     --role-name eks-secrets-access-role
   ```

3. **Associate the IAM role with a Kubernetes Service Account**. This can be done through the AWS CLI or AWS Management Console, depending on your setup. Use the following command if you have the `eksctl` CLI:

   ```bash
   eksctl create iamserviceaccount \
     --name myapp-sa \
     --namespace default \
     --cluster your-cluster-name \
     --attach-role-arn arn:aws:iam::your-account-id:role/eks-secrets-access-role \
     --approve
   ```

### Step 2: Deploy AWS Secrets and Config Provider

The AWS Secrets Manager and Config Provider for Kubernetes uses the service account role to access secrets.

1. **Install the AWS Secrets and Config Provider** using Helm:

   ```bash
   helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
   helm repo update
   helm install -n kube-system aws-secrets-manager aws-secrets-manager/secrets-store-csi-driver-provider-aws
   ```

### Step 3: Create a SecretProviderClass Resource

The SecretProviderClass resource is a Kubernetes Custom Resource Definition (CRD) that defines how secrets from AWS Secrets Manager are pulled into Kubernetes.

1. **Create the SecretProviderClass** YAML:

   ```yaml
   apiVersion: secrets-store.csi.x-k8s.io/v1
   kind: SecretProviderClass
   metadata:
     name: aws-secrets
     namespace: default
   spec:
     provider: aws
     parameters:
       objects: |
         - objectName: "your-secret-name"
           objectType: "secretsmanager"
           jmesPath:
             - path: "username"
               objectAlias: "USERNAME"
             - path: "password"
               objectAlias: "PASSWORD"
   ```

   In this example:
   - `objectName` specifies the name of your secret in AWS Secrets Manager.
   - `jmesPath` specifies which keys in the secret you want to map and their aliases (e.g., `USERNAME` and `PASSWORD`).

2. **Apply the SecretProviderClass**:

   ```bash
   kubectl apply -f secret-provider-class.yaml
   ```

### Step 4: Configure Your Application Deployment to Use the Secret

In your application deployment, mount the secrets from AWS Secrets Manager as a volume.

1. **Update your deployment YAML** to include the CSI driver volume and environment variables:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: chat-app-backend-deployment
     namespace: default
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: chat-app
         tier: backend
     template:
       metadata:
         labels:
           app: chat-app
           tier: backend
       spec:
         serviceAccountName: myapp-sa
         containers:
           - name: chat-app-backend
             image: noscopev6/chatapp-b:your-image
             ports:
               - containerPort: 8080
             env:
               - name: USERNAME
                 valueFrom:
                   secretKeyRef:
                     name: aws-secrets
                     key: USERNAME
               - name: PASSWORD
                 valueFrom:
                   secretKeyRef:
                     name: aws-secrets
                     key: PASSWORD
             volumeMounts:
               - name: secrets-store-inline
                 mountPath: "/mnt/secrets-store"
                 readOnly: true
         volumes:
           - name: secrets-store-inline
             csi:
               driver: secrets-store.csi.k8s.io
               readOnly: true
               volumeAttributes:
                 secretProviderClass: "aws-secrets"
   ```

   In this configuration:
   - `serviceAccountName` is set to `myapp-sa`, which has the IAM role attached.
   - `volumeMounts` specifies where in the container the secrets should be mounted.
   - `volumeAttributes` references the `SecretProviderClass`.

2. **Apply the updated deployment**:

   ```bash
   kubectl apply -f chat-app-backend-deployment.yaml
   ```

### Step 5: Verify the Setup

1. **Check if the pod is running and accessing secrets**:

   ```bash
   kubectl get pods
   kubectl logs <pod-name>
   ```

2. **Verify the secrets** by checking if they’re accessible within the container:

   ```bash
   kubectl exec -it <pod-name> -- cat /mnt/secrets-store/USERNAME
   kubectl exec -it <pod-name> -- cat /mnt/secrets-store/PASSWORD
   ```

### Summary

With this setup:

1. AWS Secrets Manager is used to store secrets securely.
2. Kubernetes and AWS Secrets Manager are integrated using the CSI driver.
3. The backend pod accesses these secrets securely without using ConfigMaps or Kubernetes Secrets, leveraging IAM permissions for fine-grained access control. 

> Using this method allows you to manage secrets directly in AWS Secrets Manager, ensuring centralized, secure secret management, especially useful in multi-cloud environments or when secrets need to be synchronized across services.