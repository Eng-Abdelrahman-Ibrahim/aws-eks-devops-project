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

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "VPC ID used by the cluster"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnets for workloads"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnets for load balancers"
  value       = module.vpc.public_subnets
}

output "intra_subnets" {
  description = "Intra subnets (for internal workloads, not routed to internet)"
  value       = module.vpc.intra_subnets
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "availability_zones" {
  description = "Availability Zones used in this VPC"
  value       = local.azs
}

output "ansible_security_group_id" {
  description = "The ID of the security group for the Ansible instance"
  value       = aws_security_group.ansible_sg.id
}

# Optional: kubeconfig content if you generate it via local_file
output "kubeconfig_file" {
  description = "Path to the generated kubeconfig file"
  value       = local_file.kubeconfig.filename
  sensitive   = true
}