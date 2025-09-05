# --- Instance IDs for SSM ---
output "ansible_instance_id" {
  description = "Ansible controller instance ID for SSM access"
  value       = aws_instance.ansible.id
}

output "jenkins_instance_id" {
  description = "Jenkins server instance ID for SSM access"
  value       = aws_instance.jenkins.id
}

output "nexus_instance_id" {
  description = "Nexus server instance ID for SSM access"
  value       = aws_instance.nexus.id
}

# --- Public IPs for Web Access ---
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

# --- Private IPs for Ansible ---
output "jenkins_private_ip" {
  description = "Jenkins server private IP for Ansible inventory"
  value       = aws_instance.jenkins.private_ip
}

output "nexus_private_ip" {
  description = "Nexus server private IP for Ansible inventory"
  value       = aws_instance.nexus.private_ip
}

# --- SSM Session Manager Commands ---
output "ssm_ansible_command" {
  description = "Connect to Ansible instance using AWS SSM Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.ansible.id}"
}

output "ssm_jenkins_command" {
  description = "Connect to Jenkins instance using AWS SSM Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.jenkins.id}"
}

output "ssm_nexus_command" {
  description = "Connect to Nexus instance using AWS SSM Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.nexus.id}"
}

# --- Ansible Inventory Info ---
output "ansible_inventory" {
  description = "Ansible inventory information"
  value       = <<-EOT
  [jenkins]
  ${aws_instance.jenkins.private_ip}

  [nexus]
  ${aws_instance.nexus.private_ip}

  [all:vars]
  ansible_user=ec2-user
  ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT
}

# --- Setup Instructions ---
output "setup_instructions" {
  description = "Complete setup instructions"
  value       = <<-EOT
  === Deployment Steps ===
  
  1. Connect to Ansible controller:
     aws ssm start-session --target ${aws_instance.ansible.id}
  
  2. Create Ansible inventory file:
     cat > inventory.ini << 'EOF'
     [jenkins]
     ${aws_instance.jenkins.private_ip}

     [nexus] 
     ${aws_instance.nexus.private_ip}

     [all:vars]
     ansible_user=ec2-user
     ansible_ssh_common_args='-o StrictHostKeyChecking=no'
     EOF
  
  3. Test connectivity:
     ansible all -i inventory.ini -m ping
  
  4. Deploy Jenkins:
     ansible-playbook -i inventory.ini jenkins-playbook.yml
  
  5. Deploy Nexus:
     ansible-playbook -i inventory.ini nexus-playbook.yml
  
  === Access URLs ===
  Jenkins: http://${aws_instance.jenkins.public_ip}:8080
  Nexus:   http://${aws_instance.nexus.public_ip}:8081
  EOT
}