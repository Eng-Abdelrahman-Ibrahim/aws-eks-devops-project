# #EKS/terraform/kubernetes.tf
# Kubernetes provider using IAM-based authentication
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  config_path = "~/.kube/config"
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      "us-east-1"
    ]
  }
}

# ──────────────────────────────────────────────
# aws-auth ConfigMap for IAM role access
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = "arn:aws:iam::068732175550:role/ansible-eks-role"
        username = "ansible"
        groups   = ["system:masters"]   # gives full cluster-admin permissions
      },
      {
        rolearn  = "arn:aws:iam::068732175550:role/eks-admin-role"
        username = "eks-admin"
        groups   = ["system:masters"]   # ensure cluster admin role is preserved
      }
    ])
  }

  depends_on = [module.eks]
}

