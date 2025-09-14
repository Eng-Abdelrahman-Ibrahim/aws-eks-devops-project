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

output "ansible_iam_role_arn" {
  description = "The ARN of the IAM role for the Ansible EC2 instance"
  value       = aws_iam_role.ansible_role.arn
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_private_ip" {
  description = "Private IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.private_ip
}

output "ssh_bastion_command" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i ~/.ssh/deployer-one ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_ansible_via_bastion" {
  description = "SSH to the private Ansible machine via the bastion host"
  value       = "ssh -tt -i ~/.ssh/deployer-one -o \"ProxyCommand=ssh -i ~/.ssh/deployer-one -W %h:%p ec2-user@${aws_instance.bastion.public_ip}\" ec2-user@${aws_instance.ansible_machine.private_ip}"
}

#   aws ssm start-session --target <ansible_ssm_instance_id>
#