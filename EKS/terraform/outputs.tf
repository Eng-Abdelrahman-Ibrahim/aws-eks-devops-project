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

# VPC outputs from remote state
output "vpc_id" {
  description = "VPC ID used by the cluster"
  value       = data.terraform_remote_state.vpc.outputs.vpc_id
}

output "private_subnets" {
  description = "Private subnets for EKS worker nodes"
  value       = data.terraform_remote_state.vpc.outputs.private_subnets
}

output "public_subnets" {
  description = "Public subnets for load balancers"
  value       = data.terraform_remote_state.vpc.outputs.public_subnets
}

# Optional: kubeconfig content if you generate it via local_file
output "kubeconfig_file" {
  description = "Path to the generated kubeconfig file"
  value       = local_file.kubeconfig.filename
  sensitive   = true
}