# --- Public IPs ---
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

# --- Web URLs ---
output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "nexus_url" {
  description = "Nexus web interface URL"
  value       = "http://${aws_instance.nexus.public_ip}:8081"
}

output "ansible_role" {
  description = "IAM role attached to Ansible controller"
  value       = aws_iam_role.eks_admin_role.name
}

# --- SSH helper commands ---
# Note: For Jenkins & Nexus, ssh FROM ansible using private IP
output "ssh_ansible_command" {
  description = "SSH from your laptop into Ansible controller"
  value       = "ssh -i ./terraform/.ssh/deployer-key ec2-user@${aws_instance.ansible.public_ip}"
}

output "ssh_jenkins_command" {
  description = "SSH from Ansible controller into Jenkins server (private IP)"
  value       = "ssh -i ~/.ssh/deployer-key ec2-user@${aws_instance.jenkins.private_ip}"
}

output "ssh_nexus_command" {
  description = "SSH from Ansible controller into Nexus server (private IP)"
  value       = "ssh -i ~/.ssh/deployer-key ec2-user@${aws_instance.nexus.private_ip}"
}
