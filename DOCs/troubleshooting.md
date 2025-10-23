# Troubleshooting Guide - Navigation

**Select your cloud platform for detailed troubleshooting:**

---

## 🔷 AWS EKS Troubleshooting

**→ [troubleshooting-aws.md](troubleshooting-aws.md)**

Covers AWS-specific issues:
- EKS cluster access problems
- Pod scheduling on EC2 instances
- EBS storage provisioning
- Application Load Balancer (ALB) configuration
- Security group and networking
- MongoDB connection issues
- S3 file storage access
- EC2 and EKS resource debugging
- CloudWatch logging
- AWS IAM and authentication

**Use this if deploying to AWS EKS**

---

## 🔶 Azure AKS Troubleshooting

**→ [troubleshooting-azure.md](troubleshooting-azure.md)**

Covers Azure-specific issues:
- AKS cluster access problems
- Pod scheduling on Azure VMs
- Managed Disk provisioning
- Application Gateway configuration
- Network Security Groups (NSG)
- MongoDB connection issues
- Blob Storage access
- VM and AKS resource debugging
- Log Analytics logging
- Azure CLI and authentication
- Sandbox-specific limitations

**Use this if deploying to Azure AKS**

---

## 🟣 Universal Kubernetes Commands

Commands that work on **both AWS and Azure**:

```bash
# General cluster debugging
kubectl get nodes
kubectl get pods --all-namespaces
kubectl top nodes
kubectl top pods --all-namespaces
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Network debugging
kubectl get svc --all-namespaces
kubectl get endpoints --all-namespaces
kubectl run debug --image=busybox --rm -it -- nslookup <service-name>

# Storage debugging
kubectl get pv
kubectl get pvc --all-namespaces
kubectl get storageclass

# Pod debugging
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
kubectl exec <pod-name> -n <namespace> -- <command>
```

---

## 📋 Common Issues (Platform-Agnostic)

These issues occur on **both AWS and Azure** - look in the appropriate guide for solutions:

1. **Pod Scheduling Failures** - Pods stuck in Pending state
2. **MongoDB Connection Issues** - RocketChat can't reach database
3. **Application Inaccessibility** - Can't access RocketChat UI
4. **Storage Issues** - Persistent volumes not provisioning
5. **Resource Constraints** - Nodes/pods running out of resources

---

## 🚀 Quick Decision Tree

```
Are you deploying to...

├─ AWS EKS?
│  └─ → Go to troubleshooting-aws.md
│
└─ Azure AKS?
   └─ → Go to troubleshooting-azure.md

Having cluster access issues?
├─ AWS: Use troubleshooting-aws.md
└─ Azure: Use troubleshooting-azure.md

Having pod/application issues?
├─ AWS: Use troubleshooting-aws.md
└─ Azure: Use troubleshooting-azure.md

Getting permission errors?
├─ AWS: Check IAM roles (troubleshooting-aws.md)
└─ Azure: Check RBAC (troubleshooting-azure.md)
```

---

## 📚 Related Documentation

- **[deployment.md](deployment.md)** - Step-by-step deployment (has AWS and Azure sections)
- **[architecture.md](architecture.md)** - Architecture overview (covers both clouds)
- **[operations.md](operations.md)** - Day-2 operations (has AWS and Azure sections)
- **[MASTER-PLAN.md](MASTER-PLAN.md)** - Implementation roadmap

---

**Last Updated**: October 23, 2025  
**Status**: Split into cloud-specific guides for clarity
