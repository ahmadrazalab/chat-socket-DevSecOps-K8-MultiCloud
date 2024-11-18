To install the **Amazon EBS CSI Driver** in your **AWS EKS cluster**, follow these steps:

---

### **1. Prerequisites**
- Ensure you have the following tools installed and configured:
  - **AWS CLI**: Configured with proper permissions for EKS.
  - **kubectl**: Connected to your EKS cluster.
  - **eksctl** (optional): To simplify cluster operations.
- Your worker nodes need an IAM Role with proper permissions for the EBS CSI driver.

---

### **2. Attach the IAM Policy for EBS CSI Driver**
1. Create an IAM policy for the EBS CSI Driver:
   ```bash
   aws iam create-policy \
     --policy-name AmazonEKS_EBS_CSI_Driver_Policy \
     --policy-document https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json
   ```

2. Attach the policy to the IAM role of your worker nodes. Identify your node IAM role:
   ```bash
   aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>
   ```
   Attach the policy:
   ```bash
   aws iam attach-role-policy \
     --policy-arn arn:aws:iam::<account-id>:policy/AmazonEKS_EBS_CSI_Driver_Policy \
     --role-name <node-instance-role>
   ```

---

### **3. Install the EBS CSI Driver**
You can install the driver using either `eksctl` or a Helm chart.

#### **Using eksctl** (recommended):
```bash
eksctl create addon --name aws-ebs-csi-driver --cluster <cluster-name> --region <region> --service-account-role-arn arn:aws:iam::<account-id>:role/AmazonEKS_EBS_CSI_Driver_Policy
```

#### **Using Helm**:
1. Add the Helm repository:
   ```bash
   helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
   ```

2. Install the driver:
   ```bash
   helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
     --namespace kube-system \
     --set controller.serviceAccount.create=true \
     --set controller.serviceAccount.name=ebs-csi-controller-sa \
     --set enableVolumeScheduling=true \
     --set enableVolumeResizing=true \
     --set enableVolumeSnapshot=true
   ```

---

### **4. Verify the Installation**
Check that the EBS CSI Driver pods are running:
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

You should see something like:
```
NAME                                        READY   STATUS    RESTARTS   AGE
ebs-csi-controller-xxx-yyy                 2/2     Running   0          2m
ebs-csi-node-zzz                           3/3     Running   0          2m
```

---

### **5. Test the Setup**
Deploy a sample PersistentVolumeClaim (PVC) using the EBS CSI Driver:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-volume-test
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: gp2
```
Apply the manifest:
```bash
kubectl apply -f pvc-test.yaml
```

Verify that a volume is created:
```bash
kubectl get pvc
kubectl get pv
```

---

For detailed configuration and advanced setups, visit [AWS EBS CSI Driver documentation](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html) or [docs.ahmadraza.in](https://docs.ahmadraza.in).