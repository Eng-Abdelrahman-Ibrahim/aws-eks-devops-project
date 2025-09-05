provider "aws" {
  region = "us-east-1"
}

# -----------------------------
# Data sources
# -----------------------------

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# -----------------------------
# IAM Roles & Policies
# -----------------------------

# Common SSM policy attachment
resource "aws_iam_policy_attachment" "ssm_managed" {
  name       = "ssm-managed-core"
  roles      = [
    aws_iam_role.ansible_role.name,
    aws_iam_role.jenkins_role.name,
    aws_iam_role.nexus_role.name
  ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Role for Ansible controller
resource "aws_iam_role" "ansible_role" {
  name = "ansible-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Role for Jenkins
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Role for Nexus
resource "aws_iam_role" "nexus_role" {
  name = "nexus-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# EKS Admin role for Ansible (optional)
resource "aws_iam_role" "eks_admin_role" {
  name = "ansible-eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Instance profiles
resource "aws_iam_instance_profile" "ansible_profile" {
  name = "ansible-ec2-profile"
  role = aws_iam_role.ansible_role.name
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-ec2-profile"
  role = aws_iam_role.jenkins_role.name
}

resource "aws_iam_instance_profile" "nexus_profile" {
  name = "nexus-ec2-profile"
  role = aws_iam_role.nexus_role.name
}

resource "aws_iam_instance_profile" "eks_admin_profile" {
  name = "ansible-eks-admin-profile"
  role = aws_iam_role.eks_admin_role.name
}

# -----------------------------
# Security Groups (No SSH ports!)
# -----------------------------

# Ansible SG - Only egress needed
resource "aws_security_group" "ansible_sg" {
  name        = "ansible_sg"
  description = "SG for Ansible control machine"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-security-group"
  }
}

# Jenkins SG - Only web UI and egress
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "SG for Jenkins"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Jenkins UI
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-security-group"
  }
}

# Nexus SG - Only web UI and egress
resource "aws_security_group" "nexus_sg" {
  name        = "nexus_sg"
  description = "SG for Nexus Repo"

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Nexus UI
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nexus-security-group"
  }
}

# -----------------------------
# EC2 Instances
# -----------------------------

# Ansible Controller
resource "aws_instance" "ansible" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.eks_admin_profile.name

  tags = {
    Name = "ansible-controller"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              dnf update -y
              dnf install -y ansible git unzip tar

              # AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

              # Install eksctl
              ARCH=amd64
              PLATFORM=$(uname -s)_$ARCH
              curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
              tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp
              mv /tmp/eksctl /usr/local/bin

              # Install Helm
              curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
              chmod 700 get_helm.sh
              ./get_helm.sh
              EOF
}

# Jenkins Server
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name

  tags = {
    Name = "jenkins-server"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              dnf update -y
              dnf install -y java-17-amazon-corretto

              # Jenkins setup
              curl -fsSL https://pkg.jenkins.io/redhat-stable/jenkins.io.key | tee /etc/pki/rpm-gpg/RPM-GPG-KEY-jenkins
              curl -fsSL https://pkg.jenkins.io/redhat-stable/jenkins.repo | tee /etc/yum.repos.d/jenkins.repo
              dnf install -y jenkins
              systemctl enable jenkins
              systemctl start jenkins
              EOF
}

# Nexus Repo
resource "aws_instance" "nexus" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.small" # better than micro for memory
  vpc_security_group_ids = [aws_security_group.nexus_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.nexus_profile.name

  tags = {
    Name = "nexus-repo"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              dnf update -y
              dnf install -y java-17-amazon-corretto wget

              # Nexus user and install
              useradd nexus
              cd /opt
              wget https://download.sonatype.com/nexus/3/nexus-3.83.2-01-linux-x86_64.tar.gz
              tar -xvzf nexus-3.83.2-01-linux-x86_64.tar.gz
              mv nexus-3.83.2-01 nexus
              chown -R nexus:nexus /opt/nexus

              echo 'run_as_user="nexus"' > /opt/nexus/bin/nexus.rc

              # systemd service
              cat <<EOL > /etc/systemd/system/nexus.service
              [Unit]
              Description=Nexus Repository Manager
              After=network.target

              [Service]
              Type=forking
              LimitNOFILE=65536
              ExecStart=/opt/nexus/bin/nexus start
              ExecStop=/opt/nexus/bin/nexus stop
              User=nexus
              Restart=on-abort

              [Install]
              WantedBy=multi-user.target
              EOL

              systemctl daemon-reload
              systemctl enable nexus
              systemctl start nexus
              EOF
}