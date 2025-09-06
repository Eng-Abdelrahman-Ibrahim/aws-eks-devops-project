output "ansible_public_ip" {
  description = "Ansible machine public IP"
  value       = aws_instance.ansible_machine.public_ip
}

output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "ssh_ansible_command" {
  description = "Command to SSH into Ansible machine"
  value       = "ssh -i ~/.ssh/deployer-one ec2-user@${aws_instance.ansible_machine.public_ip}"
}

output "ssh_jenkins_command" {
  description = "Command to SSH into Jenkins server"
  value       = "ssh -i ~/.ssh/deployer-one ec2-user@${aws_instance.jenkins.public_ip}"
}
