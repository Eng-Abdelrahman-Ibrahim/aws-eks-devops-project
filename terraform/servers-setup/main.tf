#terraform/servers-setup/main.tf

provider "aws" {
  region = "us-east-1"
}

# ---------------------
# Data Sources
# ---------------------

# Remote state: fetch VPC and Ansible SG outputs from the EKS stack
data "terraform_remote_state" "eks_vpc" {
  backend = "local"
  config = {
    path = "../../EKS/terraform/terraform.tfstate"
  }
}

# Your public IP for SSH access to the bastion
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# AMI lookup for Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "block-device-mapping.volume-size"
    values = ["8"] 
  }
}

# ---------------------
# Security Groups
# ---------------------

# Bastion SG - only your IP can SSH
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Bastion for SSH access to private instances"
  vpc_id      = data.terraform_remote_state.eks_vpc.outputs.vpc_id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# NOTE: The "ansible_sg" resource has been REMOVED from this file
# and is now defined in the EKS/terraform project.

# EKS VPC Endpoint SG
resource "aws_security_group" "eks_vpc_endpoint_sg" {
  name        = "eks-vpc-endpoint-sg"
  description = "Security group for EKS VPC endpoint"
  vpc_id      = data.terraform_remote_state.eks_vpc.outputs.vpc_id

  # Ingress rule to allow traffic from the Ansible SG on port 443 (HTTPS)
  ingress {
    description     = "Allow EKS API access from Ansible machine"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    # <-- CORRECTED: Uses the remote state output for Ansible SG
    security_groups = [data.terraform_remote_state.eks_vpc.outputs.ansible_security_group_id]
  }
}

# Jenkins SG
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "SG for Jenkins"
  vpc_id      = data.terraform_remote_state.eks_vpc.outputs.vpc_id

  ingress {
    description = "SSH from bastion and Ansible"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [
      aws_security_group.bastion_sg.id,
      data.terraform_remote_state.eks_vpc.outputs.ansible_security_group_id
    ]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_sg"
  }
}

# ---------------------
# Key Pair & VPC Endpoint
# ---------------------
resource "aws_key_pair" "deployer_one" {
  key_name   = "deployer-one"
  public_key = file("~/.ssh/deployer-one.pub")
}

resource "aws_vpc_endpoint" "eks_api" {
  vpc_id              = data.terraform_remote_state.eks_vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.terraform_remote_state.eks_vpc.outputs.private_subnets
  security_group_ids  = [aws_security_group.eks_vpc_endpoint_sg.id]
  private_dns_enabled = true
}

# ---------------------
# Instances
# ---------------------

# Bastion host in public subnet
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.deployer_one.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  subnet_id                   = element(data.terraform_remote_state.eks_vpc.outputs.public_subnets, 0)
  associate_public_ip_address = true
  tags = { Name = "bastion" }
}

# Ansible control machine in a private subnet
resource "aws_instance" "ansible_machine" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.deployer_one.key_name
  vpc_security_group_ids = [data.terraform_remote_state.eks_vpc.outputs.ansible_security_group_id]
  # ✅ Use the instance profile from EKS
  iam_instance_profile = data.terraform_remote_state.eks_vpc.outputs.ansible_iam_instance_profile_name
  subnet_id              = element(data.terraform_remote_state.eks_vpc.outputs.private_subnets, 0)

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = { Name = "ansible-control-machine" }

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y ansible amazon-ssm-agent
              systemctl enable --now amazon-ssm-agent
              EOF
}

# Jenkins server in public subnet
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.deployer_one.key_name
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = element(data.terraform_remote_state.eks_vpc.outputs.public_subnets, 1)
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "jenkins-server" }

}

# ---------------------
# Other Resources
# ---------------------

# Elastic IP for Jenkins
resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"
  tags     = { Name = "jenkins-eip" }
}

# Ansible inventory file
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../ansible/inventory/hosts.ini"
  content  = <<EOT
[jenkins-server]
${aws_instance.jenkins.private_ip} ansible_user=ec2-user

[ansible-controller]
ansible ansible_host=${aws_instance.ansible_machine.private_ip} ansible_user=ec2-user
EOT
}