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

# --- Web URLs ---
output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "nexus_url" {
  description = "Nexus web interface URL"
  value       = "http://${aws_instance.nexus.public_ip}:8081"
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

# --- IAM Roles ---
output "ansible_iam_role" {
  description = "IAM role attached to Ansible controller"
  value       = aws_iam_role.ansible_role.name
}

output "eks_admin_role" {
  description = "EKS Admin IAM role"
  value       = aws_iam_role.eks_admin_role.name
}

# --- Setup Instructions ---
output "setup_instructions" {
  description = "Complete setup instructions"
  value       = <<-EOT
  === AWS SSM Session Manager Setup ===
  
  1. Ensure AWS CLI is configured on your local machine:
     aws configure
  
  2. Install Session Manager plugin (if not already installed):
     # macOS: brew install session-manager-plugin
     # Linux: Follow AWS documentation for your distribution
  
  3. Connect to instances using:
     ${aws ssm start-session --target ${aws_instance.ansible.id}}
     ${aws ssm start-session --target ${aws_instance.jenkins.id}}
     ${aws ssm start-session --target ${aws_instance.nexus.id}}
  
  4. Access web interfaces:
     Jenkins: http://${aws_instance.jenkins.public_ip}:8080
     Nexus:   http://${aws_instance.nexus.public_ip}:8081
  
  5. Initial passwords:
     Jenkins: sudo cat /var/lib/jenkins/secrets/initialAdminPassword
     Nexus:   sudo cat /opt/nexus/sonatype-work/nexus3/admin.password
  
  === Security Notes ===
  - No SSH keys required
  - No port 22 open
  - All access through secure AWS SSM channels
  EOT
}

# --- Security Group IDs ---
output "security_group_ids" {
  description = "Security Group IDs for reference"
  value = {
    ansible = aws_security_group.ansible_sg.id
    jenkins = aws_security_group.jenkins_sg.id
    nexus   = aws_security_group.nexus_sg.id
  }
}