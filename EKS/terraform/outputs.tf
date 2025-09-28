#EKS/terraform/outputs.tf

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

output "ansible_iam_instance_profile_name" {
  value       = aws_iam_instance_profile.ansible_profile.name
  description = "Name of the IAM instance profile for Ansible EC2"
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

# ───────────────────────────────
# Output the LoadBalancer hostname
# ───────────────────────────────
output "nginx_ingress_lb_hostname" {
  description = "The hostname of the NGINX Ingress LoadBalancer"
  value       = data.kubernetes_service.nginx_lb.status[0].load_balancer[0].ingress[0].hostname
}

output "nexus_registry_secret_name" {
  value = kubernetes_secret.nexus_registry.metadata[0].name
}


# ───────────────────────────────
# Output Nexus Docker LB hostname
# ───────────────────────────────
output "nexus_docker_lb_hostname" {
  value = data.kubernetes_service.nexus_docker_lb.status[0].load_balancer[0].ingress[0].hostname
}


# ───────────────────────────────
# Output Worker Node Instance IDs
# ───────────────────────────────

# Look up worker node instances by tag (set by EKS module)
# Fetch worker node instances by EKS cluster tag
data "aws_instances" "eks_workers" {
  filter {
    name   = "tag:kubernetes.io/cluster/${module.eks.cluster_name}"
    values = ["owned"]
  }
  instance_state_names = ["running"]
}

# Expose IDs to remote state
output "worker_node_instance_ids" {
  description = "EKS worker node instance IDs"
  value       = data.aws_instances.eks_workers.ids
}
