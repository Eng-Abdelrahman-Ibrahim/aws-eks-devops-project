provider "aws" {
  region = "us-east-1"
}

# ──────────────────────────────────────────────
# Remote state: fetch VPC outputs from EKS stack
# ──────────────────────────────────────────────
data "terraform_remote_state" "eks_vpc" {
  backend = "local"
  config = {
    path = "../../EKS/terraform/terraform.tfstate"
  }
}

# Auto detect public IP for SSH access
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# ──────────────────────────────────────────────
# Security Groups
# ──────────────────────────────────────────────

# 1. Ansible SG (accessible from your IP)
resource "aws_security_group" "ansible_sg" {
  name        = "ansible_sg"
  description = "SG for Ansible control machine"
  vpc_id      = data.terraform_remote_state.eks_vpc.outputs.vpc_id

  ingress {
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

# 2. Jenkins SG
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "SG for Jenkins"
  vpc_id      = data.terraform_remote_state.eks_vpc.outputs.vpc_id

 ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ansible_sg.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

# ──────────────────────────────────────────────
# Use existing Key Pair
# ──────────────────────────────────────────────

resource "aws_key_pair" "deployer_one" {
  key_name   = "deployer-one"
  public_key = file("~/.ssh/deployer-one.pub")
}

# ──────────────────────────────────────────────
# AMI
# ──────────────────────────────────────────────
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ──────────────────────────────────────────────
# EC2 Instances
# ──────────────────────────────────────────────

# Ansible Control Machine (Public subnet so you can SSH)
resource "aws_instance" "ansible_machine" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.deployer_one.key_name
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ansible_profile.name
  subnet_id                   = element(data.terraform_remote_state.eks_vpc.outputs.public_subnets, 0)
  associate_public_ip_address = true

root_block_device {
    volume_size = 30   # 30GB to be safe
    volume_type = "gp3"
  }

  tags = {
    Name = "ansible-control-machine"
  }

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y ansible
              EOF
}

# Jenkins Server (Public subnet)
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.deployer_one.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = element(data.terraform_remote_state.eks_vpc.outputs.public_subnets, 1)
  associate_public_ip_address = true

root_block_device {
    volume_size = 20   # increase from 8 GB to 20 GB
    volume_type = "gp3"
}
  tags = {
    Name = "jenkins-server"
  }

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y ansible
              EOF
}

# ──────────────────────────────────────────────
# Elastic IP for Jenkins
# ──────────────────────────────────────────────
resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = {
    Name = "jenkins-eip"
  }
}

# ──────────────────────────────────────────────
# Ansible Inventory File
# ──────────────────────────────────────────────
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../ansible/inventory/hosts.ini"
  content  = <<EOT
[jenkins-server]
${aws_instance.jenkins.private_ip}

[ansible-controller]
localhost ansible_connection=local
EOT
}
