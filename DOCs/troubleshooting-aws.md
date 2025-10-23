# AWS EKS Troubleshooting Guide

**For Azure AKS, see [troubleshooting-azure.md](troubleshooting-azure.md)**

---

## 1. EKS Cluster Access Problems

### Issue: `kubectl` cannot connect to cluster
```bash
Error: unable to connect to server: dial tcp: lookup <cluster-endpoint>: no such host
```

**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name rocketchat-eks-production

# Verify cluster endpoint
aws eks describe-cluster --name rocketchat-eks-production --region us-east-1
```

### Issue: Authentication errors
```bash
Error: You must be logged in to the server (Unauthorized)
```

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Re-authenticate if needed
aws sso login --profile your-profile
```

---

## 2. Pod Scheduling Failures

### Issue: Pods stuck in Pending state
```bash
kubectl get pods -n rocketchat
# Shows: Pending
```

**Diagnosis:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n rocketchat

# Check node resources
kubectl top nodes
```

**Solutions:**
```bash
# Scale node group
aws eks update-nodegroup-config \
  --cluster-name rocketchat-eks-production \
  --nodegroup-name rocketchat-eks-production-nodes \
  --scaling-config minSize=3,maxSize=6,desiredSize=4

# Check storage classes
kubectl get storageclass
```

---

## 3. Storage Provisioning Issues

### Issue: PVC stuck in Pending state
```bash
kubectl get pvc -n rocketchat
# Shows: Pending
```

**Diagnosis:**
```bash
# Check PVC events
kubectl describe pvc <pvc-name> -n rocketchat

# Check EBS CSI driver
kubectl get pods -n kube-system | grep ebs-csi
```

**Solutions:**
```bash
# Restart EBS CSI driver
kubectl delete pod -n kube-system -l app=ebs-csi-controller

# Check IAM permissions
aws iam get-role --role-name rocketchat-eks-production-ebs-csi-driver-role
```

---

## 4. Load Balancer Configuration Problems

### Issue: ALB not created or unhealthy targets
```bash
kubectl get ingress -n rocketchat
# Shows: No ingress or unhealthy targets
```

**Diagnosis:**
```bash
# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

**Solutions:**
```bash
# Restart AWS Load Balancer Controller
kubectl delete pod -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check IAM permissions
aws iam get-role --role-name rocketchat-eks-production-aws-load-balancer-controller-role
```

---

## 5. DNS and Networking Issues

### Issue: Cannot access RocketChat via ALB
```bash
curl http://<alb-dns-name>
# Returns: Connection refused or timeout
```

**Diagnosis:**
```bash
# Check ALB status
aws elbv2 describe-load-balancers --names rocketchat-eks-production-alb

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

**Solutions:**
```bash
# Check ALB target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Verify security group rules
aws ec2 authorize-security-group-ingress \
  --group-id <sg-id> \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

---

## 6. MongoDB Connection Issues

### Issue: RocketChat cannot connect to MongoDB
```bash
kubectl logs -n rocketchat -l app.kubernetes.io/name=rocketchat
# Shows: MongoDB connection errors
```

**Diagnosis:**
```bash
# Check MongoDB pods
kubectl get pods -n rocketchat -l app.kubernetes.io/name=mongodb

# Check MongoDB logs
kubectl logs -n rocketchat -l app.kubernetes.io/name=mongodb

# Check MongoDB service
kubectl get svc -n rocketchat
```

**Solutions:**
```bash
# Restart MongoDB
kubectl delete pod -n rocketchat -l app.kubernetes.io/name=mongodb

# Check MongoDB replica set status
kubectl exec -n rocketchat mongodb-0 -- mongo --eval "rs.status()"
```

---

## 7. S3 Access Issues

### Issue: File uploads failing
```bash
kubectl logs -n rocketchat -l app.kubernetes.io/name=rocketchat
# Shows: S3 access denied errors
```

**Diagnosis:**
```bash
# Check IAM role annotations
kubectl describe sa rocketchat -n rocketchat

# Test S3 access
aws s3 ls s3://<bucket-name>
```

**Solutions:**
```bash
# Update service account with correct IAM role
kubectl annotate sa rocketchat -n rocketchat \
  eks.amazonaws.com/role-arn=arn:aws:iam::<account-id>:role/rocketchat-eks-production-rocketchat-s3-role

# Restart RocketChat pods
kubectl delete pod -n rocketchat -l app.kubernetes.io/name=rocketchat
```

---

## Kubernetes Debugging Commands

### General Debugging
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

### Network Debugging
```bash
# Check services and endpoints
kubectl get svc --all-namespaces
kubectl get endpoints --all-namespaces

# Test connectivity
kubectl run debug --image=busybox --rm -it -- nslookup <service-name>
```

### Storage Debugging
```bash
# Check persistent volumes
kubectl get pv
kubectl get pvc --all-namespaces

# Check storage classes
kubectl get storageclass
```

### Log Collection
```bash
# Create logs directory
mkdir -p logs

# Collect pod logs
kubectl logs --all-containers=true -n rocketchat > logs/rocketchat.log
kubectl logs --all-containers=true -n monitoring > logs/monitoring.log
kubectl logs --all-containers=true -n kube-system > logs/kube-system.log

# Collect events
kubectl get events --all-namespaces > logs/events.log

# Check EKS cluster
aws eks describe-cluster --name rocketchat-eks-production

# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=*rocketchat*"

# Check load balancers
aws elbv2 describe-load-balancers
```

---

## Emergency Procedures

### Complete Cluster Reset
```bash
# WARNING: This will delete everything!
cd AWS/terraform
terraform destroy -auto-approve
terraform apply
```

### Quick Recovery
```bash
# Restart all deployments
kubectl rollout restart deployment -n rocketchat
kubectl rollout restart deployment -n monitoring

# Restart all pods
kubectl delete pods --all -n rocketchat
kubectl delete pods --all -n monitoring
```

---

## Getting Help

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [AWS Support Center](https://console.aws.amazon.com/support/)
- Check Terraform state: `terraform show`
- Community Forums: Kubernetes and EKS communities

---

**Last Updated**: October 23, 2025  
**Platform**: AWS EKS only  
**Related**: [troubleshooting-azure.md](troubleshooting-azure.md) for Azure AKS issues
