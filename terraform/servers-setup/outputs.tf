output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_private_ip" {
  description = "Private IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.private_ip
}

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
