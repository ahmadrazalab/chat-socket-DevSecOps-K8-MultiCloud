# Setting Up Persistent Storage for MySQL Using Azure Disk in AKS

This guide explains how to configure persistent storage for MySQL using Azure Disk as a Persistent Volume (PV) in Azure Kubernetes Service (AKS). The configuration ensures that MySQL data persists across pod restarts.

## Prerequisites
- Azure Kubernetes Service (AKS) cluster.
- Azure Disk available for use in your subscription.
- kubectl configured to interact with your AKS cluster.

## Step 1: Create a Persistent Volume (PV)
In Azure, we use **Azure Disk** to create a Persistent Volume (PV). The PV will be attached to the Kubernetes nodes, and data will be stored on this Azure-managed disk.

### Key Configuration Details:
- **DiskName**: This is the name of the disk in Azure.
- **DiskURI**: The URI to the Azure Disk in your subscription.
- **AccessMode**: Set to `ReadWriteOnce` to allow a single node to access the disk.

The PersistentVolume is defined to use Azure Managed Disk and should have the `Retain` reclaim policy to keep the data when the PV is deleted.

## Step 2: Create a Persistent Volume Claim (PVC)
The **Persistent Volume Claim (PVC)** is created to request the storage from the PV. It binds to the PV based on the specified volume name and access mode.

### Key Configuration Details:
- **Storage Request**: Defines the storage capacity required (e.g., 5Gi).
- **AccessMode**: The PVC should match the PV's access mode (typically `ReadWriteOnce`).

The PVC specifies the volume that is being claimed from the PersistentVolume.

## Step 3: MySQL Deployment Configuration
In the MySQL deployment configuration, you need to reference the PVC for persistent storage. This allows the MySQL container to use the persistent volume for storing database files.

### Key Configuration Details:
- **Container Image**: MySQL Docker image (`mysql:5.7`).
- **Environment Variables**: Configure MySQL root password, user, and database name.
- **Volume Mounts**: Mount the PVC to the MySQL data directory (`/var/lib/mysql`) to persist data.

The MySQL container will mount the persistent volume and store its data on the Azure-managed disk.

## Step 4: Create a MySQL Service
To expose MySQL to other services within the AKS cluster, create a **ClusterIP** service. This allows internal services to connect to MySQL on port 3306.

### Key Configuration Details:
- **Port**: Expose port `3306` for MySQL.
- **Service Type**: `ClusterIP`, which makes the service accessible only within the cluster.

The service will facilitate communication with MySQL from other pods in the Kubernetes cluster.

## Step 5: Permissions for Azure Disk Attachment to AKS Nodes
For AKS to attach the Azure disk to the Kubernetes nodes, you need to grant the appropriate permissions.

### Key Permissions:
1. **Managed Disk Contributor**: Ensure the AKS managed identity has the `Managed Disk Contributor` role in the Azure resource group containing the disk.
   
2. **Virtual Machine Contributor** (optional): This role may be needed if you encounter disk attachment issues.

To assign the required role, run the following command:

```bash
az role assignment create --assignee <aks-managed-identity> --role "Managed Disk Contributor" --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>
```

## Step 6: Deploy the Resources
Once the configurations are set, apply the necessary YAML files to your Kubernetes cluster using `kubectl`.

```bash
kubectl apply -f elasticsearch-pv.yaml
kubectl apply -f elasticsearch-pvc.yaml
kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml
```

## Conclusion
By following the steps above, you will set up persistent storage for MySQL using Azure Disks in AKS. This ensures that data is stored persistently and can survive pod restarts. Ensure you have the correct Azure permissions to attach disks to AKS nodes and that your PV and PVC are properly configured to bind the Azure Disk to your MySQL container.