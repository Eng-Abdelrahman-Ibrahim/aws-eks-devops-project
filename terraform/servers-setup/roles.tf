#terraform/servers-setup/roles.tf

# IAM Role for Ansible EC2 to access EKS + SSM
resource "aws_iam_role" "ansible_role" {
  name = "ansible-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Inline policy to allow eks:DescribeCluster on your cluster (least-privilege)
resource "aws_iam_role_policy" "eks_describe" {
  name = "eks-describe-cluster"
  role = aws_iam_role.ansible_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "arn:aws:eks:us-east-1:068732175550:cluster/myapp-eks"
      }
    ]
  })
}

# Attach managed policies needed: EKS cluster access, SSM agent, EC2/VPC as you requested
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_access" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ansible_profile" {
  name = "ansible-eks-profile"
  role = aws_iam_role.ansible_role.name
}
