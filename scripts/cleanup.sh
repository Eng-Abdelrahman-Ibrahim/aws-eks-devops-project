#!/bin/bash
# THE DEFINITIVE, MULTI-VPC, SCORCHED EARTH CLEANUP SCRIPT

set -e

# --- Configuration ---
CLUSTER_NAME="myapp-eks"
VPC_NAME_TAG="myapp-eks"
REGION="us-east-1"

# --- Tool Check ---
if ! command -v jq &> /dev/null; then
    echo "ERROR: 'jq' is not installed. Please install jq to parse AWS CLI output." >&2
    exit 1
fi

echo "--- STARTING DEFINITIVE SCORCHED EARTH CLEANUP ---"

# 1. Hunt and Destroy ALL Zombie Foremen (Orphaned Auto Scaling Groups)
echo "[Step 1/4] Hunting for ALL orphaned Auto Scaling Groups for cluster '$CLUSTER_NAME'..."
ASG_NAMES=$(aws autoscaling describe-auto-scaling-groups --region "$REGION" \
  --query "AutoScalingGroups[?contains(Tags[?Key==\`eks:cluster-name\`].Value, \`$CLUSTER_NAME\`)].AutoScalingGroupName" \
  --output json | jq -r '.[]')
if [ -z "$ASG_NAMES" ]; then echo "No orphaned ASGs found."; else
    for asg in $ASG_NAMES; do
        echo "--> ZOMBIE FOREMAN FOUND: $asg. Firing now."
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$asg" --min-size 0 --max-size 0 --desired-capacity 0 --region "$REGION"
        sleep 5
        aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "$asg" --force-delete --region "$REGION"
        echo "    Foreman $asg has been fired."
    done
fi

# 2. Hunt and Destroy ALL EKS Clusters with the name
echo "[Step 2/4] Hunting for ALL EKS clusters named '$CLUSTER_NAME'..."
CLUSTERS=$(aws eks list-clusters --region "$REGION" --query "clusters" --output json | jq -r '.[]' | grep "$CLUSTER_NAME" || true)
if [ -z "$CLUSTERS" ]; then echo "No EKS Clusters named '$CLUSTER_NAME' found."; else
    for cluster in $CLUSTERS; do
        echo "--> Deleting EKS cluster '$cluster' (this can take 10-15 minutes)..."
        aws eks delete-cluster --name "$cluster" --region "$REGION"
        aws eks wait cluster-deleted --name "$cluster" --region "$REGION"
    done
fi

# 3. Hunt and Destroy ALL VPCs and their contents, one by one
echo "[Step 3/4] Hunting for ALL VPCs tagged '$VPC_NAME_TAG'..."
VPC_IDS=$(aws ec2 describe-vpcs --region "$REGION" --filters "Name=tag:Name,Values=$VPC_NAME_TAG" --query "Vpcs[].VpcId" --output text)

if [ -z "$VPC_IDS" ]; then
  echo "✅ No VPCs with the name tag '$VPC_NAME_TAG' found."
else
  for VPC_ID in $VPC_IDS; do
    echo "------------------------------------------------------------"
    echo "--- Processing Wreckage for VPC: $VPC_ID ---"
    
    # Terminate any remaining instances
    INSTANCES=$(aws ec2 describe-instances --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=pending,running,shutting-down,stopping" --query "Reservations[].Instances[].InstanceId" --output text)
    if [ -n "$INSTANCES" ]; then aws ec2 terminate-instances --region "$REGION" --instance-ids $INSTANCES; aws ec2 wait instance-terminated --region "$REGION" --instance-ids $INSTANCES; fi
    
    # Delete NATs, IGWs, ENIs, Subnets, SGs
    NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[].NatGatewayId" --output text)
    for ngw in $NAT_GATEWAYS; do aws ec2 delete-nat-gateway --nat-gateway-id "$ngw"; done
    if [ -n "$NAT_GATEWAYS" ]; then echo "Waiting for NATs..."; sleep 60; fi
    
    IGWS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text)
    for igw in $IGWS; do aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$VPC_ID"; aws ec2 delete-internet-gateway --internet-gateway-id "$igw"; done
    
    ENIS=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkInterfaces[].NetworkInterfaceId" --output text)
    for eni in $ENIS; do aws ec2 delete-network-interface --network-interface-id "$eni" >/dev/null 2>&1 || true; done
    
    SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
    for sg in $SGS; do aws ec2 delete-security-group --group-id "$sg" >/dev/null 2>&1 || true; done
    
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text)
    for subnet in $SUBNETS; do aws ec2 delete-subnet --subnet-id "$subnet"; done
    
    echo "--- Deleting VPC $VPC_ID ---"
    aws ec2 delete-vpc --vpc-id "$VPC_ID"
    echo "✅ VPC $VPC_ID destroyed."
  done
fi

# 4. Erase Terraform's Memory
echo "[Step 4/4] Deleting local Terraform state files..."
rm -f "$HOME/GitHub_Repos/aws-eks-devops-project/EKS/terraform/terraform.tfstate*"
rm -f "$HOME/GitHub_Repos/aws-eks-devops-project/terraform/servers-setup/terraform.tfstate*"

echo "--- DEFINITIVE CLEANUP COMPLETE ---"
echo "You now have a clean slate. You can run your 'apply' script."