# EKS cluster outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS Kubernetes version"
  value       = module.eks.cluster_version
}

# VPC outputs
output "vpc_id" {
  description = "VPC ID used by the cluster"
  value       = module.myapp-vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnets for EKS worker nodes"
  value       = module.myapp-vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnets for load balancers"
  value       = module.myapp-vpc.public_subnets
}

# Nexus outputs
output "nexus_service_name" {
  description = "Nexus service name"
  value       = kubernetes_service.nexus.metadata[0].name
}

output "nexus_service_namespace" {
  description = "Namespace where Nexus is deployed"
  value       = kubernetes_service.nexus.metadata[0].namespace
}

output "nexus_service_cluster_ip" {
  description = "ClusterIP address for Nexus service"
  value       = kubernetes_service.nexus.spec[0].cluster_ip
}
