#  HCP Vault Secrets with Vault Secrets Operator for Kubernetes

The **Vault Secrets Operator** is a Kubernetes operator that continuously fetches secrets from **HCP Vault Secrets** and creates native Kubernetes secrets. Kubernetes workloads and users do not need to update workflows to adopt HCP Vault Secrets.

The Vault Secrets Operator syncs secrets between **HCP Vault Secrets** and Kubernetes secrets in a specified namespace, enabling applications within that namespace to access these secrets, while HCP Vault Secrets retains management control.

> https://developer.hashicorp.com/hcp/tutorials/get-started-hcp-vault-secrets/hcp-vault-secrets-kubernetes-vso

> https://portal.cloud.hashicorp.com/services/secrets

---

## Prerequisites

1. **HCP Account**: Ensure you have an existing HCP account.
2. **HCP Vault Secrets Setup**: Complete the previous HCP Vault Secrets tutorials.
3. **Service Principal**: HCP service principal must be created at the org level, with `HCP_CLIENT_ID` and `HCP_CLIENT_SECRET`.
4. **Minikube**: Installed to create a local Kubernetes cluster.
5. **Helm**: Installed for deploying the Vault Secrets Operator.

---

## Lab Setup

1. **Set Environment Variables**

   Ensure your **HCP Vault Secrets** environment details are set as environment variables.

   ```bash
   echo ID=$HCP_CLIENT_ID\\nSecret=$HCP_CLIENT_SECRET
   ```

   ```
   ID=FxqJRZabCd3fGh1jKaKVMybay3m
   Secret=HoaxKFvG8QenprS3asam3stQnJbSXWWM5ab3rt4F2qWXbja33rnie
   ```

2. **Retrieve HCP Organization ID and Project ID**

   ```bash
   hcp profile display
   ```

   ```
   name            = "default"
   organization_id = "ab35ef-8d87-4443-a8a8-s3asam3st"
   project_id      = "ab35ef-d3f4-4fda-b245-s3asam3st"
   ```

3. **Set Environment Variables**

   ```bash
   export HCP_ORG_ID=$(hcp profile display --format=json | jq -r .OrganizationID)
   export HCP_PROJECT_ID=$(hcp profile display --format=json | jq -r .ProjectID)
   export APP_NAME=$(hcp profile display --format=json | jq -r .VaultSecrets.AppName)
   ```

4. **Start Minikube**

   Start Minikube to provision and manage the lifecycle of a single-node Kubernetes cluster locally.

   ```bash
   minikube start
   ```

5. **Verify Minikube Status**

   ```bash
   minikube status
   ```

---

## Configure Kubernetes

1. **Add the HashiCorp Helm Repository**

   ```bash
   helm repo add hashicorp https://helm.releases.hashicorp.com
   helm repo update hashicorp
   ```

2. **Install Vault Secrets Operator**

   ```bash
   helm install vault-secrets-operator hashicorp/vault-secrets-operator \
     --namespace vault-secrets-operator-system \
     --create-namespace
   ```

   **Expected Output:**

   ```
   NAME: vault-secrets-operator
   LAST DEPLOYED: ...
   NAMESPACE: vault-secrets-operator-system
   STATUS: deployed
   REVISION: 1
   ```

3. **Create Kubernetes Secret for HCP Service Principal**

   ```bash
   kubectl create secret generic vso-demo-sp \
       --namespace default \
       --from-literal=clientID=$HCP_CLIENT_ID \
       --from-literal=clientSecret=$HCP_CLIENT_SECRET
   ```

   **Expected Output:**

   ```
   secret/vso-demo-sp created
   ```

4. **Configure Vault Secrets Operator with HCP Organization and Project ID**

   ```yaml
   kubectl create -f - <<EOF
   ---
   apiVersion: secrets.hashicorp.com/v1beta1
   kind: HCPAuth
   metadata:
     name: default
     namespace: vault-secrets-operator-system
   spec:
     organizationID: $HCP_ORG_ID
     projectID: $HCP_PROJECT_ID
     servicePrincipal:
       secretRef: vso-demo-sp
   EOF
   ```

   **Expected Output:**

   ```
   hcpauth.secrets.hashicorp.com/default created
   ```

---

## Creating Secrets

1. **Verify Available Kubernetes Secrets**

   ```bash
   kubectl get secrets
   ```

2. **Create Kubernetes Secret from HCP Vault Secret**

   ```yaml
   kubectl create -f - <<EOF
   apiVersion: secrets.hashicorp.com/v1beta1
   kind: HCPVaultSecretsApp
   metadata:
     name: web-application
     namespace: default
   spec:
     appName: $APP_NAME
     destination:
       create: true
       labels:
         hvs: "true"
       name: web-application
     refreshAfter: 1h
   EOF
   ```

   **Expected Output:**

   ```
   hcpvaultsecretsapp.secrets.hashicorp.com/web-application created
   ```

3. **Verify Created Secrets**

   ```bash
   kubectl get secrets
   ```

4. **Retrieve and Decode Secret**

   ```bash
   kubectl get secrets web-application -o jsonpath='{.data.username}' | base64 --decode
   ```

   **Output:** `db-user`

> Your applications can now consume these secrets natively in Kubernetes by mounting the secret in a data volume or as an environment variable.
