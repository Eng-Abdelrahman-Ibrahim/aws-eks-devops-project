#!/bin/bash
set -e  # Exit on any error

# Directories
EKS_DIR=../EKS/terraform
TERRAFORM_DIR="../../terraform/servers-setup"
ANSIBLE_DIR="../../ansible"

# SSH details
ANSIBLE_KEY="$HOME/.ssh/deployer-one"
ANSIBLE_USER="ec2-user"

# Function to display usage
usage() {
    echo "Usage: $0 [apply|destroy]"
    echo "  apply   - Create infrastructure and deploy Jenkins"
    echo "  destroy - Destroy all infrastructure"
    exit 1
}

# Function to run Terraform apply
terraform_apply() {
    echo "=== Running Terraform Apply ==="
    cd "$EKS_DIR"
    terraform init
    terraform apply -auto-approve
}
# Function to run Terraform apply
terraform_apply() {
    echo "=== Running Terraform Apply ==="
    cd "$TERRAFORM_DIR"
    terraform init
    terraform apply -auto-approve

    # Step 2: Get Ansible EC2 public IP from Terraform
    ANSIBLE_HOST=$(terraform output -raw ansible_public_ip)
    echo "Ansible EC2 public IP: $ANSIBLE_HOST"

    # Wait for SSH to be available
    echo "=== Waiting for SSH to be available ==="
    sleep 10

    # Step 3: Copy Ansible folder to EC2
    echo "=== Copying Ansible folder to EC2 ==="
    scp -i "$ANSIBLE_KEY" -o StrictHostKeyChecking=no -r "$ANSIBLE_DIR" "$ANSIBLE_USER@$ANSIBLE_HOST:~/"
    sleep 10

    # Step 4: Copy SSH key separately
    echo "=== Copying SSH key ==="
    scp -i "$ANSIBLE_KEY" -o StrictHostKeyChecking=no "$ANSIBLE_KEY" "$ANSIBLE_USER@$ANSIBLE_HOST:~/ansible/"
    sleep 5

    # Step 5: Prepare SSH key on Ansible EC2 and run playbook
    echo "=== Setting up SSH key and running Jenkins playbook on Ansible EC2 ==="
    ssh -tt -i "$ANSIBLE_KEY" -o StrictHostKeyChecking=no "$ANSIBLE_USER@$ANSIBLE_HOST" << 'EOF'
set -e  # Exit on error in remote session

# Verify what was copied
echo "=== Remote Ansible structure ==="
ls -la ~/ansible/

# Ensure .ssh folder exists
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Copy the key to proper location from ansible folder
cp ~/ansible/deployer-one ~/.ssh/id_rsa
rm -rf ~/ansible/deployer-one
chmod 600 ~/.ssh/id_rsa

# Start ssh-agent and add the key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Run Jenkins playbook
cd ~/ansible
ansible-playbook -i inventory/hosts.ini site.yml
EOF

    echo "✅ Ansible Deployments executed successfully from Ansible EC2!"
}

# Function to run Terraform destroy
terraform_destroy() {
    echo "=== Running Terraform Destroy ==="
    cd "$TERRAFORM_DIR"
    terraform destroy -auto-approve
    echo "✅ All infrastructure destroyed successfully!"
}

# Main script logic
if [ $# -eq 0 ]; then
    # No arguments provided, ask user
    echo "Please choose an action:"
    echo "1) Apply - Create infrastructure and deploy Jenkins"
    echo "2) Destroy - Destroy all infrastructure"
    echo "3) Quit"
    read -p "Enter your choice (1-3): " choice

    case $choice in
        1) terraform_apply ;;
        2) terraform_destroy ;;
        3) echo "Exiting..." ; exit 0 ;;
        *) echo "Invalid choice!" ; usage ;;
    esac
else
    # Argument provided
    case $1 in
        apply|create|deploy)
            terraform_apply
            ;;
        destroy|delete|remove)
            terraform_destroy
            ;;
        *)
            echo "Invalid argument: $1"
            usage
            ;;
    esac
fi