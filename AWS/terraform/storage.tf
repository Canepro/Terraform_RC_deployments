# S3 Bucket for RocketChat file uploads
resource "aws_s3_bucket" "rocketchat_files" {
  bucket = local.s3_bucket_name

  tags = local.common_tags
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "rocketchat_files" {
  bucket = aws_s3_bucket.rocketchat_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "rocketchat_files" {
  bucket = aws_s3_bucket.rocketchat_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "rocketchat_files" {
  bucket = aws_s3_bucket.rocketchat_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "rocketchat_files" {
  bucket = aws_s3_bucket.rocketchat_files.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Storage Class for EBS CSI Driver
resource "kubernetes_storage_class" "ebs_gp3" {
  depends_on = [kubernetes_namespace.rocketchat]

  metadata {
    name = "ebs-gp3"
  }
  
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    type       = "gp3"
    fsType     = "ext4"
    encrypted  = "true"
  }
}

# Storage Class for MongoDB
resource "kubernetes_storage_class" "mongodb" {
  depends_on = [kubernetes_namespace.rocketchat]

  metadata {
    name = "mongodb-storage"
  }
  
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    type       = "gp3"
    fsType     = "ext4"
    encrypted  = "true"
    iops       = "3000"
    throughput = "125"
  }
}

# Namespace for RocketChat
resource "kubernetes_namespace" "rocketchat" {
  metadata {
    name = "rocketchat"
    labels = {
      name = "rocketchat"
    }
  }
}

# Service Account for RocketChat S3 Access
resource "kubernetes_service_account" "rocketchat" {
  depends_on = [kubernetes_namespace.rocketchat]

  metadata {
    name      = "rocketchat"
    namespace = "rocketchat"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.rocketchat_s3.arn
    }
  }
}

# Service Account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }
  }
}

# Service Account for EBS CSI Driver
resource "kubernetes_service_account" "ebs_csi_controller" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_driver.arn
    }
  }
}
