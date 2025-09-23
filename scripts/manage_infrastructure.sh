#!/bin/bash
set -e # Exit on any error

# ──────────────────────────────────────────────
# Directories
EKS_DIR="$HOME/GitHub_Repos/aws-eks-devops-project/EKS/terraform"
TERRAFORM_DIR="$HOME/GitHub_Repos/aws-eks-devops-project/terraform/servers-setup"
ANSIBLE_DIR="$HOME/GitHub_Repos/aws-eks-devops-project/ansible"
HELM_DIR="$HOME/GitHub_Repos/aws-eks-devops-project/helm"

# SSH details
ANSIBLE_KEY="$HOME/.ssh/deployer-one"
ANSIBLE_USER="ec2-user"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PROXY_OPTS="-o ProxyCommand=ssh -i $ANSIBLE_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $ANSIBLE_USER@"

# ──────────────────────────────────────────────
# Function to display usage
usage() {
    echo "Usage: $0 [apply|destroy <servers|eks|all>]"
    echo "  apply           - Create infrastructure and deploy Jenkins"
    echo "  destroy servers - Destroy servers only"
    echo "  destroy eks     - Destroy EKS only"
    echo "  destroy all     - Destroy everything (servers + EKS)"
    exit 1
}

# ──────────────────────────────────────────────
# Terraform Apply
# In your terraform_apply() function, add this after servers are created:

terraform_apply() {
    echo "=== Running Terraform Apply (EKS) ==="
    cd "$EKS_DIR"
    terraform init -input=false
    terraform apply -auto-approve
    
    echo "=== Running Terraform Apply (servers-setup) ==="
    cd "$TERRAFORM_DIR"
    terraform init -input=false
    terraform apply -auto-approve
    
    # After terraform apply finishes
    echo "=== Updating /etc/hosts with custom domains ==="
    
    # Get the ELB hostname/IP from Terraform
    NLB_HOSTNAME=$(cd "$TERRAFORM_DIR" && terraform output -raw nexus_docker_lb_hostname)
    
    # Optional: resolve hostname → IP
    NLB_IP=$(dig +short $NLB_HOSTNAME | tail -n1)
    
    if [ -z "$NLB_IP" ]; then
        echo "❌ Could not resolve NLB hostname ($NLB_HOSTNAME)"
    else
        echo "✅ NLB resolved to $NLB_IP"
        
        # Add nexus.local and app.local to /etc/hosts
        sudo sh -c "grep -v 'nexus.local' /etc/hosts > /tmp/etchosts && mv /tmp/etchosts /etc/hosts"
        sudo sh -c "grep -v 'app.local' /etc/hosts > /tmp/etchosts && mv /tmp/etchosts /etc/hosts"
        
        echo "$NLB_IP nexus.local app.local" | sudo tee -a /etc/hosts
        echo "✅ /etc/hosts updated → $NLB_IP nexus.local app.local"
    fi
    
    # Step 1: Get bastion public IP and Ansible private IP
    BASTION_IP=$(terraform output -raw bastion_public_ip)
    ANSIBLE_PRIVATE_IP=$(terraform output -raw ansible_private_ip)
    echo "Bastion IP: $BASTION_IP"
    echo "Ansible private IP: $ANSIBLE_PRIVATE_IP"
    
    # Also get kubeconfig path from Terraform (EKS module output)
    KUBECONFIG_FILE=$(cd "$EKS_DIR" && terraform output -raw kubeconfig_file)
    echo "Kubeconfig file: $KUBECONFIG_FILE"
    
    # Wait for SSH to be available
    echo "=== Waiting for SSH to bastion to be available ==="
    sleep 15
    
    # Step 2: Copy Ansible and Helm folders to Ansible host via bastion
    echo "=== Copying Ansible folder to Ansible EC2 via bastion ==="
    scp -i "$ANSIBLE_KEY" $SSH_OPTS \
    -o "ProxyCommand=ssh -i $ANSIBLE_KEY $SSH_OPTS -W %h:%p $ANSIBLE_USER@$BASTION_IP" \
    -r "$ANSIBLE_DIR" "$ANSIBLE_USER@$ANSIBLE_PRIVATE_IP:~/"
    
    echo "=== Copying Helm folder to Ansible EC2 via bastion ==="
    scp -i "$ANSIBLE_KEY" $SSH_OPTS \
    -o "ProxyCommand=ssh -i $ANSIBLE_KEY $SSH_OPTS -W %h:%p $ANSIBLE_USER@$BASTION_IP" \
    -r "$HELM_DIR" "$ANSIBLE_USER@$ANSIBLE_PRIVATE_IP:~/"
    
    # Step 2.5: Ensure .kube folder exists and copy kubeconfig
    echo "=== Copying kubeconfig file to Ansible EC2 via bastion ==="
    ssh -i "$ANSIBLE_KEY" $SSH_OPTS \
    -o "ProxyCommand=ssh -i $ANSIBLE_KEY $SSH_OPTS -W %h:%p $ANSIBLE_USER@$BASTION_IP" \
    "$ANSIBLE_USER@$ANSIBLE_PRIVATE_IP" "mkdir -p ~/.kube && chmod 700 ~/.kube"
    
    scp -i "$ANSIBLE_KEY" $SSH_OPTS \
    -o "ProxyCommand=ssh -i $ANSIBLE_KEY $SSH_OPTS -W %h:%p $ANSIBLE_USER@$BASTION_IP" \
    "$KUBECONFIG_FILE" "$ANSIBLE_USER@$ANSIBLE_PRIVATE_IP:~/.kube/config"
    
    # Step 3: Copy SSH key separately
    echo "=== Copying SSH key to Ansible EC2 via bastion ==="
    scp -i "$ANSIBLE_KEY" $SSH_OPTS \
    -o "ProxyCommand=ssh -i $ANSIBLE_KEY $SSH_OPTS -W %h:%p $ANSIBLE_USER@$BASTION_IP" \
    "$ANSIBLE_KEY" "$ANSIBLE_USER@$ANSIBLE_PRIVATE_IP:~/ansible/"
    
    # Step 4: Prepare SSH key on Ansible EC2 and run playbook
    echo "=== Running Jenkins playbook on Ansible EC2 ==="
    ssh -tt -i "$ANSIBLE_KEY" $SSH_OPTS \
    -o "ProxyCommand=ssh -i $ANSIBLE_KEY $SSH_OPTS -W %h:%p $ANSIBLE_USER@$BASTION_IP" \
        "$ANSIBLE_USER@$ANSIBLE_PRIVATE_IP" << 'EOF'
set -e

echo "=== Remote Ansible structure ==="
ls -la ~/ansible/

# Ensure .ssh folder exists
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Copy key to proper location
cp ~/ansible/deployer-one ~/.ssh/id_rsa
rm -f ~/ansible/deployer-one
chmod 600 ~/.ssh/id_rsa

# Start ssh-agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Run initial playbooks
cd ~/ansible
ansible-playbook -i inventory/hosts.ini site.yml
EOF
    
    echo "✅ Ansible Deployments executed successfully from Ansible EC2!"
}

# ──────────────────────────────────────────────
# Terraform Destroy (Servers only)
terraform_destroy_servers() {
    echo "=== Running Terraform Destroy (servers) ==="
    cd "$TERRAFORM_DIR"
    terraform init
    terraform destroy -auto-approve
    echo "✅ Servers destroyed successfully!"
}

# Terraform Destroy (EKS only)
terraform_destroy_eks() {
    echo "=== Running Terraform Destroy (EKS) ==="
    cd "$EKS_DIR"
    terraform init
    terraform destroy -auto-approve
    echo "✅ EKS destroyed successfully!"
}

# Terraform Destroy (All)
terraform_destroy_all() {
    echo "=== Destroying Servers first ==="
    terraform_destroy_servers
    
    echo "=== Destroying EKS next ==="
    terraform_destroy_eks
    
    echo "✅ All infrastructure destroyed successfully!"
}

# ──────────────────────────────────────────────
# Main script logic
if [ $# -eq 0 ]; then
    echo "Please choose an action:"
    echo "1) Apply - Create infrastructure and deploy Jenkins"
    echo "2) Destroy Servers only"
    echo "3) Destroy EKS only"
    echo "4) Destroy All"
    echo "5) Quit"
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1) terraform_apply ;;
        2) terraform_destroy_servers ;;
        3) terraform_destroy_eks ;;
        4) terraform_destroy_all ;;
        5) echo "Exiting..." ; exit 0 ;;
        *) echo "Invalid choice!" ; usage ;;
    esac
else
    case $1 in
        apply|create|deploy)
            terraform_apply
        ;;
        destroy|delete|remove)
            case $2 in
                servers) terraform_destroy_servers ;;
                eks) terraform_destroy_eks ;;
                all) terraform_destroy_all ;;
                *) echo "Invalid destroy option: $2" ; usage ;;
            esac
        ;;
        *)
            echo "Invalid argument: $1"
            usage
        ;;
    esac
fi