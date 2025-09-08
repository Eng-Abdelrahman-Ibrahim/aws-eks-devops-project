# VPC outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.myapp-vpc.vpc_id
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = module.myapp-vpc.private_subnets
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = module.myapp-vpc.public_subnets
}

output "ssm_role_arn" {
  value = aws_iam_role.ssm_role.arn
}

# Jenkins public IP (Elastic IP)
output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_eip.jenkins_eip.public_ip
}

# Jenkins private IP
output "jenkins_private_ip" {
  description = "Private IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.private_ip
}

# Ansible controller public IP
output "ansible_public_ip" {
  description = "Public IP of the Ansible EC2 instance"
  value       = aws_instance.ansible_machine.public_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:8080"
}

output "ssh_ansible_command" {
  description = "Command to SSH into Ansible machine"
  value       = "ssh -i ~/.ssh/deployer-one ec2-user@${aws_instance.ansible_machine.public_ip}"
}

output "ssh_jenkins_command" {
  description = "Command to SSH into Jenkins server"
  value       = "ssh -i ~/.ssh/deployer-one ec2-user@${aws_eip.jenkins_eip.public_ip}"
}
