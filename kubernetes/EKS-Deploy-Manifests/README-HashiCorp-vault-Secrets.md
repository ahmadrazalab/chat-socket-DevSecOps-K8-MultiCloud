# Deploy and use HashiCorp Vault in kuberntes
Integrating HashiCorp Vault with Kubernetes allows you to securely manage and access secrets for your applications. Here’s a step-by-step guide to set up HashiCorp Vault in your Kubernetes cluster and use it to manage secrets for your backend pods.

### Step 1: Deploy HashiCorp Vault

#### 1.1 Install Vault

You can deploy Vault using Helm, which simplifies the installation process. First, make sure you have Helm installed on your machine.

1. **Add the HashiCorp Helm repository**:

   ```bash
   helm repo add hashicorp https://helm.releases.hashicorp.com
   helm repo update
   ```

2. **Install Vault using Helm**:

   ```bash
   helm install vault hashicorp/vault \
     --set "server.dev.enabled=true" \
     --set "injector.enabled=true"
   ```

   This command installs Vault in development mode, which is suitable for testing purposes. In production, you should configure Vault with a proper storage backend.

#### 1.2 Initialize and Unseal Vault

After installing Vault, you need to initialize and unseal it.

1. **Port forward to the Vault service**:

   ```bash
   kubectl port-forward svc/vault 8200:8200
   ```

2. **Initialize Vault**:

   Open another terminal and run the following command:

   ```bash
   vault operator init
   ```

   Note down the unseal keys and the root token from the output.

3. **Unseal Vault**:

   Use the unseal keys to unseal Vault. Run the command below three times, using a different unseal key each time:

   ```bash
   vault operator unseal <unseal_key>
   ```

4. **Login to Vault**:

   Use the root token to log in:

   ```bash
   vault login <root_token>
   ```

### Step 2: Enable Kubernetes Authentication

#### 2.1 Configure Kubernetes Authentication

1. **Enable the Kubernetes Auth method**:

   ```bash
   vault auth enable kubernetes
   ```

2. **Configure the Kubernetes Auth method**:

   Run the following command, replacing `<KUBE_SA_TOKEN>` and `<KUBE_CA_CERT>` with your Kubernetes service account token and CA certificate, respectively:

   ```bash
   vault write auth/kubernetes/config \
     token_reviewer_jwt=<KUBE_SA_TOKEN> \
     kubernetes_host=https://<KUBE_API_SERVER> \
     kubernetes_ca_cert=<KUBE_CA_CERT>
   ```

#### 2.2 Create a Policy for Access

1. **Create a policy file named `k8s-policy.hcl`**:

   ```hcl
   path "secret/data/myapp/*" {
     capabilities = ["read"]
   }
   ```

2. **Write the policy to Vault**:

   ```bash
   vault policy write k8s-policy k8s-policy.hcl
   ```

#### 2.3 Create a Kubernetes Role

1. **Create a role for the Kubernetes service account**:

   ```bash
   vault write auth/kubernetes/role/myapp-role \
     bound_service_account_names=myapp-sa \
     bound_service_account_namespaces=default \
     policies=k8s-policy \
     ttl=1h
   ```

### Step 3: Store Secrets in Vault

1. **Store your secrets in Vault**:

   ```bash
   vault kv put secret/myapp/config username='myusername' password='mypassword'
   ```

### Step 4: Configure Your Backend Pod to Access Vault Secrets

#### 4.1 Create a Service Account

Create a service account for your backend application.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-sa
  namespace: default
```

#### 4.2 Deploy Your Application with Vault Sidecar Injector

Update your deployment file to include a Vault agent sidecar that can fetch the secrets.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat-app-backend-deployment
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
          - name: VAULT_ADDR
            value: "http://127.0.0.1:8200"
          - name: VAULT_TOKEN
            valueFrom:
              secretKeyRef:
                name: vault-token
                key: token
      - name: vault-agent
        image: hashicorp/vault:latest
        volumeMounts:
          - name: vault-agent-config
            mountPath: /etc/vault/config
        command: ["vault", "agent", "-config=/etc/vault/config/config.hcl"]
      volumes:
        - name: vault-agent-config
          configMap:
            name: vault-agent-config
```

#### 4.3 Create a ConfigMap for Vault Agent Configuration

Create a ConfigMap that defines how the Vault agent should operate.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-agent-config
data:
  config.hcl: |
    exit_after_auth = false
    pid_file = "./pidfile"
    auto_auth {
      method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
          role = "myapp-role"
        }
      }
      sink "file" {
        config = {
          path = "/vault/token"
        }
      }
    }
    template {
      source      = "/etc/vault/secrets/template.hcl"
      destination = "/etc/secrets/config.json"
    }
```

#### 4.4 Create a Template File for Secrets

You also need to create a template file that the Vault agent will use to write the secrets to a file.

Create a ConfigMap for the template:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-secrets-template
data:
  template.hcl: |
    {{- with secret "secret/myapp/config" }}
    {
      "username": "{{ .Data.data.username }}",
      "password": "{{ .Data.data.password }}"
    }
    {{- end }}
```

### Step 5: Deploy Everything

Deploy your service account, ConfigMap, and the application:

```bash
kubectl apply -f service-account.yaml
kubectl apply -f vault-agent-config.yaml
kubectl apply -f vault-secrets-template.yaml
kubectl apply -f chat-app-backend-deployment.yaml
```

### Summary

1. **Deploy Vault**: Use Helm to install Vault and enable Kubernetes authentication.
2. **Store Secrets**: Use Vault to manage and store your application secrets.
3. **Configure Application**: Update your application deployment to include a Vault agent sidecar for fetching secrets.

> With this setup, your backend application will use HashiCorp Vault to securely access secrets, keeping them out of your source code and Kubernetes ConfigMaps.