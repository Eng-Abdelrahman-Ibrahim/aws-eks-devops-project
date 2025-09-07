provider "aws" {
  region = "us-east-1"
}

# Auto detect public IP
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# 1. Create the ansible machine SG
resource "aws_security_group" "ansible_sg" {
  name        = "ansible_sg"
  description = "SG for Ansible control machine"

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

# 2. Create the jenkins Server SG
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "SG for jenkins"

  tags = {
    Name = "jenkins_sg"
  }

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
}

# 3. Use existing local key pair (persistent)
resource "aws_key_pair" "deployer_one" {
  key_name   = "deployer-one"
  public_key = file("~/.ssh/deployer-one.pub")
}

# 4. Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# 5. Launch Ansible-machine
resource "aws_instance" "ansible_machine" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer_one.key_name
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ansible_profile.name  # 🔑

  tags = {
    Name = "ansible-control-machine"
  }

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y ansible

              # Add SSH key for Jenkins access
              mkdir -p /home/ec2-user/.ssh
              echo '${file("~/.ssh/deployer-one")}' > /home/ec2-user/.ssh/id_rsa
              chmod 600 /home/ec2-user/.ssh/id_rsa
              chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa

              # Start ssh-agent and add private key
              eval "$(ssh-agent -s)"
              ssh-add /home/ec2-user/.ssh/deployer-one
              EOF
}


# 6. Launch the jenkins
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer_one.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  tags = {
    Name = "jenkins-server"
  }
}

# 7. Allocate Elastic IP
resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = {
    Name = "jenkins-eip"
  }
}

# 8. Generate Ansible inventory with Jenkins EIP
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/hosts.ini"
  content  = <<EOT
[jenkins-server]
${aws_eip.jenkins_eip.public_ip}

[ansible-controller]
localhost ansible_connection=local
EOT
}
