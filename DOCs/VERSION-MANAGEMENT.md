# Version Management Strategy

**Created**: October 24, 2025  
**Status**: Production Best Practice

---

## 🎯 Philosophy: Balance Between Stability and Currency

**Goal**: Stay current without breaking deterministic deployments.

**Approach**: 
- Pin versions for deterministic deployments
- Document update process for staying current
- Test updates in sandbox before production
- Maintain version changelog

---

## 📦 Version Sources

### RocketChat
- **Current Check**: https://github.com/RocketChat/Rocket.Chat/releases
- **Helm Chart**: https://github.com/RocketChat/helm-charts
- **Latest Stable**: 7.11.0 (as of Oct 2025)

### Monitoring Stack
- **Prometheus**: https://github.com/prometheus-community/helm-charts
- **Grafana**: https://github.com/grafana/helm-charts
- **Loki**: https://github.com/grafana/loki/releases
- **Tempo**: https://github.com/grafana/tempo/releases

---

## 🔄 Version Update Workflow

### Step 1: Check for Updates (Monthly)

```bash
# Check RocketChat versions
helm search repo rocketchat/rocketchat --versions | head -10

# Check Prometheus stack
helm search repo prometheus-community/kube-prometheus-stack --versions | head -10

# Check Grafana
helm search repo grafana/grafana --versions | head -10

# Check Loki
helm search repo grafana/loki --versions | head -10

# Check Tempo
helm search repo grafana/tempo --versions | head -10
```

### Step 2: Update Local Helm Values

**File**: `AZURE/helm/rocketchat-values.yaml` (and AWS equivalent)

```yaml
image:
  repository: rocketchat/rocket.chat
  tag: "7.11.0"  # Update this
  pullPolicy: IfNotPresent
```

### Step 3: Update Terraform Chart Versions

**File**: `AZURE/terraform/helm.tf`

```hcl
resource "helm_release" "rocketchat" {
  chart   = "rocketchat"
  version = "6.27.0"  # Update chart version
  # ...
}
```

### Step 4: Test in Sandbox

```bash
cd AZURE/terraform

# Deploy with updated versions
terraform plan -var-file=terraform.sandbox.tfvars -out=sandbox.tfplan
terraform apply sandbox.tfplan

# Verify pods
kubectl get pods -n rocketchat

# Check RocketChat version
kubectl logs -n rocketchat deployment/rocketchat-rocketchat | grep "Rocket.Chat Version"
```

### Step 5: Update Documentation

Update version references in:
- `DOCs/PHASE-B-DEPLOYMENT-SUCCESS.md`
- `DOCs/PHASE-B-READINESS.md`
- `README.md`

### Step 6: Commit Version Update

```bash
git add .
git commit -m "chore: Update RocketChat to v7.11.0

- Updated RocketChat image tag: 7.0.0 -> 7.11.0
- Tested in Azure sandbox
- All services operational
- See: https://github.com/RocketChat/Rocket.Chat/releases/tag/7.11.0"
```

---

## 🔍 Automated Version Checking (Optional)

### Create Version Check Script

**File**: `scripts/check-versions.sh`

```bash
#!/bin/bash

echo "=== Current Versions in Repo ==="
echo ""

echo "RocketChat Image:"
grep -A 2 "repository: rocketchat" AZURE/helm/rocketchat-values.yaml | grep tag

echo ""
echo "Helm Charts:"
grep "version.*=" AZURE/terraform/helm.tf | grep -v "#"

echo ""
echo "=== Latest Available Versions ==="
echo ""

echo "RocketChat Chart:"
helm search repo rocketchat/rocketchat --versions | head -2

echo ""
echo "Prometheus Stack:"
helm search repo prometheus-community/kube-prometheus-stack --versions | head -2

echo ""
echo "Grafana:"
helm search repo grafana/grafana --versions | head -2

echo ""
echo "Loki:"
helm search repo grafana/loki --versions | head -2

echo ""
echo "Tempo:"
helm search repo grafana/tempo --versions | head -2
```

**Usage**:
```bash
chmod +x scripts/check-versions.sh
./scripts/check-versions.sh
```

---

## 📊 Version Matrix (Current as of Oct 2025)

### Application Versions

| Component | Chart Version | Image Version | Status | Last Updated |
|-----------|---------------|---------------|--------|--------------|
| RocketChat | 6.27.0 | 7.0.0 | ⚠️ **OUTDATED** | Phase A |
| Prometheus | 52.0.0 | (managed by chart) | ✅ Current | Phase A |
| Grafana | 6.50.0 | 11.4.0 | ✅ Current | Phase A |
| Loki | 6.20.0 | (managed by chart) | ✅ Current | Phase 0 |
| Tempo | 1.23.3 | (managed by chart) | ✅ Current | Phase 0 |

### Infrastructure Versions

| Component | Version | Status |
|-----------|---------|--------|
| Terraform | ~> 1.9.0 | ✅ Current |
| AWS Provider | ~> 5.76.0 | ✅ Current |
| Azure Provider | ~> 3.117.0 | ✅ Current |
| Helm Provider | ~> 2.17.0 | ✅ Current |
| Kubernetes Provider | ~> 2.38.0 | ✅ Current |

---

## 🎯 Version Update Policy

### Semantic Versioning Rules

**Patch Updates (x.y.Z)**: 
- Apply immediately in sandbox
- Low risk, bug fixes only
- Example: 7.11.0 → 7.11.1

**Minor Updates (x.Y.0)**:
- Test in sandbox → dev → prod
- Moderate risk, new features
- Review changelog carefully
- Example: 7.11.0 → 7.12.0

**Major Updates (X.0.0)**:
- Full testing cycle required
- High risk, breaking changes
- Plan migration carefully
- Example: 7.11.0 → 8.0.0

---

## 🔐 Security Updates

**Priority**: IMMEDIATE for security patches

**Process**:
1. Monitor security advisories
2. Apply patch within 24-48 hours
3. Test in sandbox (abbreviated testing)
4. Deploy to production immediately
5. Document in security log

**Sources**:
- RocketChat Security: https://github.com/RocketChat/Rocket.Chat/security/advisories
- CVE Database: https://cve.mitre.org/

---

## 📝 Changelog Maintenance

### Version Update Log

**File**: `DOCs/VERSION-CHANGELOG.md`

```markdown
# Version Changelog

## 2025-10-24 - Phase A Initial Deployment
- RocketChat: 7.0.0 (Chart 6.27.0)
- Prometheus: 52.0.0
- Grafana: 6.50.0 (Image 11.4.0)
- Loki: 6.20.0
- Tempo: 1.23.3

## [PLANNED] 2025-10-XX - Security Update
- RocketChat: 7.0.0 → 7.11.0
- Reason: Stay current with supported versions
- Testing: Azure sandbox deployment successful
```

---

## 🚀 Recommended Actions

### Immediate (Before Production)
1. ✅ Update RocketChat to 7.11.0
2. ✅ Test in sandbox
3. ✅ Document in changelog

### Ongoing (Monthly)
1. Run version check script
2. Review changelogs for major updates
3. Plan and test updates in sandbox
4. Update production during maintenance window

### Quarterly
1. Major version review
2. Deprecated version cleanup
3. Security audit
4. Performance benchmarking

---

## 🔧 Quick Fix for Current Deployment

To update RocketChat to 7.11.0:

```bash
# Update values files
sed -i 's/tag: "7.0.0"/tag: "7.11.0"/' AZURE/helm/rocketchat-values.yaml
sed -i 's/tag: "7.0.0"/tag: "7.11.0"/' AWS/helm/rocketchat-values.yaml

# Test in sandbox
cd AZURE/terraform
terraform plan -var-file=terraform.sandbox.tfvars

# If clean, apply
terraform apply -var-file=terraform.sandbox.tfvars
```

---

**Maintained by**: DevOps Team  
**Review Frequency**: Monthly  
**Last Updated**: October 24, 2025

