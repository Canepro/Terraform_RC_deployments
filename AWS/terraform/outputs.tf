# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# EKS Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.rocketchat.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.rocketchat.zone_id
}

# S3 Outputs
output "s3_bucket_id" {
  description = "ID of the S3 bucket for RocketChat file uploads"
  value       = aws_s3_bucket.rocketchat_files.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for RocketChat file uploads"
  value       = aws_s3_bucket.rocketchat_files.arn
}

# Access Information
output "kubectl_config" {
  description = "Kubectl config command"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "rocketchat_url" {
  description = "RocketChat application URL"
  value       = "http://${aws_lb.rocketchat.dns_name}"
}

output "grafana_url" {
  description = "Grafana monitoring URL"
  value       = "http://${aws_lb.rocketchat.dns_name}/grafana"
}
