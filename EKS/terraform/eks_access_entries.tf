# EKS/terraform/eks_access_entries.tf

# Try to find the IAM role, but don't fail if it doesn't exist yet
data "aws_iam_role" "ansible_eks_role" {
  count = var.create_access_entries ? 1 : 0
  name  = "ansible-eks-role"
}

# Conditional access entry creation
resource "aws_eks_access_entry" "ansible_eks_role" {
  count = var.create_access_entries ? 1 : 0
  
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_iam_role.ansible_eks_role[0].arn
  type          = "STANDARD"

  depends_on = [module.eks]
}

# EKS Access Entry for Admin-user (assuming this IAM user exists)
resource "aws_eks_access_entry" "admin_user" {
  count = var.create_access_entries ? 1 : 0
  
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::068732175550:user/Admin-user"
  type          = "STANDARD"

  depends_on = [module.eks]
}

# Add this variable
variable "create_access_entries" {
  description = "Whether to create EKS access entries"
  type        = bool
  default     = false
}

# Access Policy Associations for ansible role
resource "aws_eks_access_policy_association" "ansible_admin_policy" {
  count = var.create_access_entries ? 1 : 0
  
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.ansible_eks_role[0].principal_arn

  access_scope {
    type = "namespace"
  }

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"

  depends_on = [aws_eks_access_entry.ansible_eks_role]
}

resource "aws_eks_access_policy_association" "ansible_cluster_admin_policy" {
  count = var.create_access_entries ? 1 : 0
  
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.ansible_eks_role[0].principal_arn

  access_scope {
    type = "cluster"
  }

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  depends_on = [aws_eks_access_entry.ansible_eks_role]
}

# Access Policy Associations for admin user
resource "aws_eks_access_policy_association" "admin_user_admin_policy" {
  count = var.create_access_entries ? 1 : 0
  
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.admin_user[0].principal_arn

  access_scope {
    type = "namespace"
  }

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"

  depends_on = [aws_eks_access_entry.admin_user]
}

resource "aws_eks_access_policy_association" "admin_user_cluster_admin_policy" {
  count = var.create_access_entries ? 1 : 0
  
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.admin_user[0].principal_arn

  access_scope {
    type = "cluster"
  }

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  depends_on = [aws_eks_access_entry.admin_user]
}