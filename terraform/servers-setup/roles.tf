# IAM Role for Ansible
resource "aws_iam_role" "ansible_role" {
  name = "ansible-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach EKS cluster permissions
resource "aws_iam_role_policy_attachment" "ansible_eks_policy" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach EKS worker node permissions
resource "aws_iam_role_policy_attachment" "ansible_worker_policy" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach EC2 full access
resource "aws_iam_role_policy_attachment" "ansible_ec2_policy" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Attach VPC full access
resource "aws_iam_role_policy_attachment" "ansible_vpc_policy" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

# 🔽 NEW: Add EKS Describe policy for kubectl access
resource "aws_iam_role_policy_attachment" "ansible_eks_describe" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_Describe_Cluster"
}

# Create instance profile for EC2
resource "aws_iam_instance_profile" "ansible_profile" {
  name = "ansible-eks-profile"
  role = aws_iam_role.ansible_role.name
}