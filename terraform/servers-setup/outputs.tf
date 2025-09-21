#terraform/servers-setup/outputs.tf

output "bastion_public_ip" {
  description = "Public IP of the bastion (SSH jump)"
  value       = aws_instance.bastion.public_ip
}

output "ansible_private_ip" {
  description = "Private IP of the Ansible EC2 instance"
  value       = aws_instance.ansible_machine.private_ip
}

output "ansible_ssm_instance_id" {
  description = "Ansible EC2 instance id (use for AWS SSM Session Manager)"
  value       = aws_instance.ansible_machine.id
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_private_ip" {
  description = "Private IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.private_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:8080"
}

output "ssh_bastion_command" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i ~/.ssh/deployer-one ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_ansible_via_bastion" {
  description = "SSH to the private Ansible machine via the bastion host"
  value = <<EOT
ssh -tt -i ~/.ssh/deployer-one \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o ProxyCommand="ssh -i ~/.ssh/deployer-one -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ec2-user@${aws_instance.bastion.public_ip}" \
  ec2-user@${aws_instance.ansible_machine.private_ip}
EOT
}

output "ssh_jenkins_from_ansible" {
  description = "SSH to Jenkins from Ansible machine (run this from Ansible machine)"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.jenkins.private_ip}"
}