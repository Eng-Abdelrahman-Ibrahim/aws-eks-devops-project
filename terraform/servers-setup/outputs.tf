output "ansible_public_ip" {
  description = "Ansible controller public IP"
  value       = aws_instance.ansible.public_ip
}

output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = aws_instance.jenkins.public_ip
}

output "nexus_public_ip" {
  description = "Nexus server public IP"
  value       = aws_instance.nexus.public_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "key_name" {
  description = "SSH key pair name used for instances"
  value       = aws_key_pair.deployer.key_name
}

output "ansible_role" {
  description = "IAM role attached to Ansible controller"
  value       = aws_iam_role.eks_admin_role.name
}

output "ssh_ansible_command" {
  description = "Command to SSH into Ansible controller"
  value       = "ssh -i ~/.ssh/deployer-key ec2-user@${aws_instance.ansible.public_ip}"
}

output "ssh_jenkins_command" {
  description = "Command to SSH into Jenkins server"
  value       = "ssh -i ~/.ssh/deployer-key ec2-user@${aws_instance.jenkins.public_ip}"
}

output "ssh_nexus_command" {
  description = "Command to SSH into Nexus server"
  value       = "ssh -i ~/.ssh/deployer-key ec2-user@${aws_instance.nexus.public_ip}"
}
