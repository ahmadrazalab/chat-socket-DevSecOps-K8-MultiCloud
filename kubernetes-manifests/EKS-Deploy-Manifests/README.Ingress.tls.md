# Setup `TLS` for internal communication in EKS cluster + `ALB`

To set up TLS certificates for internal communication in a Kubernetes cluster, you can use Kubernetes Secrets to store the TLS certificate and private key. Here's a step-by-step guide to create a TLS certificate, store it as a Secret, and then use it in your Ingress configuration.

### Step 1: Create a TLS Certificate

You can generate a self-signed certificate using OpenSSL or use a tool like `cert-manager` if you prefer to automate certificate management.

#### Option A: Generate a Self-Signed Certificate with OpenSSL

1. **Install OpenSSL**: Ensure you have OpenSSL installed on your machine.

2. **Generate the Certificate**:
   Run the following commands to create a self-signed TLS certificate and private key. Replace `chatapi.ahmadraza.in` with your actual domain name.

   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
       -keyout tls.key \
       -out tls.crt \
       -subj "/CN=chatapi.ahmadraza.in/O=My Company Name"
   ```

   This command will create two files: `tls.crt` (the certificate) and `tls.key` (the private key).

#### Option B: Using cert-manager

If you have `cert-manager` installed, you can create certificates automatically. Here’s a simple way to set up a self-signed certificate with `cert-manager`:

1. **Install cert-manager** (if not already installed):

   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
   ```

2. **Create a Certificate resource**:

   Create a file named `selfsigned-cert.yaml` with the following content:

   ```yaml
   apiVersion: cert-manager.io/v1
   kind: Certificate
   metadata:
     name: chatapp-tls
     namespace: default  # Change to your namespace if necessary
   spec:
     secretName: your-tls-secret  # The name of the secret that will be created
     issuerRef:
       name: selfsigned-issuer
       kind: Issuer
     commonName: chatapi.ahmadraza.in
     dnsNames:
       - chatapi.ahmadraza.in
       - chat.ahmadraza.in
   ```

   And create a self-signed issuer:

   ```yaml
   apiVersion: cert-manager.io/v1
   kind: Issuer
   metadata:
     name: selfsigned-issuer
     namespace: default  # Change to your namespace if necessary
   spec:
     selfSigned: {}
   ```

   Deploy both the Issuer and Certificate:

   ```bash
   kubectl apply -f selfsigned-issuer.yaml
   kubectl apply -f selfsigned-cert.yaml
   ```

### Step 2: Store the TLS Certificate in a Kubernetes Secret

If you used OpenSSL to generate the certificate, you can create a Secret to store the TLS certificate and key:

```bash
kubectl create secret tls your-tls-secret \
  --cert=tls.crt \
  --key=tls.key
```

### Step 3: Update Your Ingress Resource

Now that you have your TLS certificate stored as a Secret, you can reference it in your Ingress configuration as follows:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: chat-app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing # or 'internal' for internal ALB
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:YOUR_ACCOUNT_ID:certificate/YOUR_CERTIFICATE_ID
spec:
  tls:
    - hosts:
        - chatapi.ahmadraza.in
        - chat.ahmadraza.in
      secretName: your-tls-secret  # Reference to the TLS secret created
  rules:
    - host: chatapi.ahmadraza.in
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: chat-app-backend-service
                port:
                  number: 8080
    - host: chat.ahmadraza.in
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: chat-app-frontend-service
                port:
                  number: 3000
```

### Step 4: Deploy Your Ingress Resource

Apply your Ingress configuration to your cluster:

```bash
kubectl apply -f your-ingress.yaml
```

### Summary

1. **Generate TLS Certificates**: You can use OpenSSL or cert-manager.
2. **Store in Kubernetes Secret**: Use `kubectl create secret` to store your TLS certificate and private key.
3. **Reference in Ingress**: Update your Ingress resource to reference the TLS secret.

This setup ensures that your internal communications are secured using TLS.