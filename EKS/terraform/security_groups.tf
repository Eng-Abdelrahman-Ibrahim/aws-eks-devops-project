# EKS/terraform/security_groups.tf

resource "aws_security_group" "ansible_sg" {
  name        = "ansible-sg"
  description = "SG for the private Ansible control machine; allows all egress."
  vpc_id      = module.vpc.vpc_id

  ingress {
    # 👇 CORRECTED DESCRIPTION (no apostrophe)
    description = "Allow SSH from the bastion public subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.vpc.public_subnets_cidr_blocks[0]]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-sg"
  }
}


# This SG will contain the rule to allow Ansible to talk to the EKS control plane.
resource "aws_security_group" "eks_to_ansible_access" {
  name        = "eks-control-plane-allow-ansible"
  description = "Allow Ansible SG to access the EKS control plane"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow HTTPS from Ansible machine"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    # This rule allows traffic FROM the Ansible machine's SG
    security_groups = [aws_security_group.ansible_sg.id]
  }

  tags = {
    Name = "eks-allow-ansible-access"
  }
}