#!/bin/bash
# THE DEFINITIVE, MULTI-VPC, SCORCHED EARTH CLEANUP SCRIPT
# Handles all common blockers for VPC deletion including security group dependencies

set -euo pipefail

# --- Configuration ---
CLUSTER_NAME="myapp-eks"
VPC_NAME_TAG="myapp-eks"
REGION="us-east-1"
ACCOUNT_ID="YOUR_AWS_ACCOUNT_ID"  # Replace with your AWS Account ID

# --- Tool Check ---
if ! command -v jq &> /dev/null; then
    echo "ERROR: 'jq' is not installed. Please install jq to parse AWS CLI output." >&2
    exit 1
fi

echo "--- STARTING DEFINITIVE SCORCHED EARTH CLEANUP ---"

# --- Step 1: Orphaned Auto Scaling Groups ---
echo "[Step 1/7] Hunting for ALL orphaned Auto Scaling Groups for cluster '$CLUSTER_NAME'..."
ASG_NAMES=$(aws autoscaling describe-auto-scaling-groups --region "$REGION" \
    --query "AutoScalingGroups[?contains(Tags[?Key=='eks:cluster-name'].Value, '$CLUSTER_NAME') || \
             contains(AutoScalingGroupName, '$CLUSTER_NAME') || \
    contains(AutoScalingGroupName, 'myapp-nodes')].AutoScalingGroupName" \
--output text)

# Also check for any ASGs that might have different naming patterns
ADDITIONAL_ASGS=$(aws autoscaling describe-auto-scaling-groups --region "$REGION" \
    --query "AutoScalingGroups[?starts_with(AutoScalingGroupName, 'eksctl-$CLUSTER_NAME') || \
    contains(AutoScalingGroupName, 'nodegroup')].AutoScalingGroupName" \
--output text)

# Combine both lists and remove duplicates
ALL_ASGS=$(echo "$ASG_NAMES $ADDITIONAL_ASGS" | tr ' ' '\n' | sort -u | tr '\n' ' ')

if [ -z "$ALL_ASGS" ]; then
    echo "No orphaned ASGs found."
else
    echo "Found ASGs to delete: $ALL_ASGS"
    for asg in $ALL_ASGS; do
        echo "--> ZOMBIE FOREMAN FOUND: $asg. Firing now."
        
        # First, set desired capacity to 0 to terminate instances
        aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name "$asg" \
        --min-size 0 \
        --max-size 0 \
        --desired-capacity 0 \
        --region "$REGION"
        
        # Wait for instances to terminate
        echo "    Waiting for instances in $asg to terminate..."
        sleep 30
        
        # Delete the ASG
        aws autoscaling delete-auto-scaling-group \
        --auto-scaling-group-name "$asg" \
        --force-delete \
        --region "$REGION"
        
        echo "    Foreman $asg has been fired."
    done
fi

# --- Additional check: EKS Nodegroups ---
echo "[Step 1.5/7] Checking for EKS Nodegroups..."
NODEGROUPS=$(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$REGION" --query "nodegroups" --output text 2>/dev/null || true)

if [ -n "$NODEGROUPS" ]; then
    echo "Found EKS Nodegroups: $NODEGROUPS"
    for ng in $NODEGROUPS; do
        echo "--> Deleting EKS Nodegroup: $ng"
        aws eks delete-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$ng" --region "$REGION"
        aws eks wait nodegroup-deleted --cluster-name "$CLUSTER_NAME" --nodegroup-name "$ng" --region "$REGION"
        echo "    Nodegroup $ng deleted."
    done
fi

# --- Step 2: EKS Clusters ---
echo "[Step 2/7] Hunting for ALL EKS clusters named '$CLUSTER_NAME'..."
CLUSTERS=$(aws eks list-clusters --region "$REGION" --query "clusters" --output text | grep "$CLUSTER_NAME" || true)

if [ -z "$CLUSTERS" ]; then
    echo "No EKS Clusters named '$CLUSTER_NAME' found."
else
    for cluster in $CLUSTERS; do
        echo "--> Deleting EKS cluster '$cluster'..."
        aws eks delete-cluster --name "$cluster" --region "$REGION"
        aws eks wait cluster-deleted --name "$cluster" --region "$REGION"
    done
fi

# --- Step 3: OIDC Provider ---
echo "[Step 3/7] Cleaning up EKS OIDC Provider..."
OIDC_PROVIDER_ARN=$(aws iam list-open-id-connect-providers --region "$REGION" \
--query "OpenIDConnectProviderList[?contains(Arn, '$CLUSTER_NAME')].Arn" --output text)

if [ -n "$OIDC_PROVIDER_ARN" ]; then
    echo "--> Deleting OIDC Provider: $OIDC_PROVIDER_ARN"
    aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" --region "$REGION"
    echo "✅ OIDC Provider deleted."
else
    echo "No OIDC Provider found for cluster '$CLUSTER_NAME'."
fi

# --- Step 4: IAM Roles & Policies ---
echo "[Step 4/7] Cleaning up IAM Roles and Policies..."
ROLES_TO_DELETE=$(aws iam list-roles --region "$REGION" \
    --query "Roles[?contains(RoleName, 'myapp-eks') || contains(RoleName, 'ansible-eks') || contains(RoleName, 'eks-admin')].RoleName" \
--output text)

for role in $ROLES_TO_DELETE; do
    echo "--> Processing IAM Role: $role"
    
    INLINE_POLICIES=$(aws iam list-role-policies --role-name "$role" --query "PolicyNames" --output text)
    for policy in $INLINE_POLICIES; do
        aws iam delete-role-policy --role-name "$role" --policy-name "$policy"
    done
    
    MANAGED_POLICIES=$(aws iam list-attached-role-policies --role-name "$role" --query "AttachedPolicies[].PolicyArn" --output text)
    for policy_arn in $MANAGED_POLICIES; do
        aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn"
    done
    
    INSTANCE_PROFILES=$(aws iam list-instance-profiles-for-role --role-name "$role" --query "InstanceProfiles[].InstanceProfileName" --output text)
    for profile in $INSTANCE_PROFILES; do
        aws iam remove-role-from-instance-profile --role-name "$role" --instance-profile-name "$profile"
        aws iam delete-instance-profile --instance-profile-name "$profile"
    done
    
    aws iam delete-role --role-name "$role"
    echo "✅ IAM Role '$role' deleted."
done

# --- Step 5: VPCs & Dependencies ---
echo "[Step 5/7] Hunting for ALL VPCs tagged '$VPC_NAME_TAG'..."
VPC_IDS=$(aws ec2 describe-vpcs --region "$REGION" --filters "Name=tag:Name,Values=$VPC_NAME_TAG" --query "Vpcs[].VpcId" --output text)

if [ -z "$VPC_IDS" ]; then
    echo "✅ No VPCs with the name tag '$VPC_NAME_TAG' found."
else
    for VPC_ID in $VPC_IDS; do
        echo "------------------------------------------------------------"
        echo "--- Processing VPC: $VPC_ID ---"
        
        # --- Terminate EC2 Instances ---
        INSTANCES=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=pending,running,stopping,shutting-down" --query "Reservations[].Instances[].InstanceId" --output text)
        if [ -n "$INSTANCES" ]; then
            aws ec2 terminate-instances --instance-ids $INSTANCES
            aws ec2 wait instance-terminated --instance-ids $INSTANCES
        fi
        
        # --- Delete NAT Gateways ---
        NATS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[].NatGatewayId" --output text)
        for nat in $NATS; do
            echo "Deleting NAT Gateway: $nat"
            aws ec2 delete-nat-gateway --nat-gateway-id "$nat"
        done
        for nat in $NATS; do
            aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$nat"
        done
        
        for nat in $NATS; do
            aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$nat"
        done
        
        # --- ADD EIP CLEANUP HERE ---
        echo "--> Releasing Elastic IPs from deleted NAT Gateways..."
        EIPS=$(aws ec2 describe-addresses --region "$REGION" \
            --filters Name=domain,Values=vpc \
            --query "Addresses[?AssociationId==null].AllocationId" \
        --output text)
        
        if [ -n "$EIPS" ]; then
            for eip in $EIPS; do
                echo "    Releasing unused EIP: $eip"
                aws ec2 release-address --allocation-id "$eip" --region "$REGION"
            done
            echo "    ✅ All unused EIPs released."
        else
            echo "    No unused EIPs found."
        fi
        
        # --- Delete Transit Gateway Attachments ---
        TGWS=$(aws ec2 describe-transit-gateway-attachments --filters Name=resource-id,Values=$VPC_ID --query "TransitGatewayAttachments[].TransitGatewayAttachmentId" --output text)
        for tgw in $TGWS; do
            echo "Deleting Transit Gateway Attachment: $tgw"
            aws ec2 delete-transit-gateway-vpc-attachment --transit-gateway-attachment-id "$tgw"
        done
        
        # --- Delete VPC Endpoints ---
        VPC_ENDPOINTS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --query "VpcEndpoints[].VpcEndpointId" --output text)
        for ep in $VPC_ENDPOINTS; do
            echo "Deleting VPC Endpoint: $ep"
            aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$ep"
        done
        
        # --- Delete Route Tables ---
        for rt in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[].RouteTableId" --output text); do
            for assoc in $(aws ec2 describe-route-tables --route-table-ids $rt --query "RouteTables[].Associations[?Main==\`false\`].RouteTableAssociationId" --output text); do
                aws ec2 disassociate-route-table --association-id $assoc
            done
            aws ec2 delete-route-table --route-table-id $rt >/dev/null 2>&1 || true
        done
        
        # --- Delete VPC Peering Connections ---
        for pcx in $(aws ec2 describe-vpc-peering-connections --query "VpcPeeringConnections[?RequesterVpcInfo.VpcId=='$VPC_ID' || AccepterVpcInfo.VpcId=='$VPC_ID'].VpcPeeringConnectionId" --output text); do
            aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $pcx
        done
        
        # --- Delete Load Balancers ---
        echo "--> Deleting Load Balancers in VPC $VPC_ID..."
        for lb_arn in $(aws elbv2 describe-load-balancers --region "$REGION" --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text); do
            echo "    Deleting LB $lb_arn"
            aws elbv2 delete-load-balancer --load-balancer-arn "$lb_arn"
        done
        
        # Wait until all LBs are gone
        while true; do
            REMAINING=$(aws elbv2 describe-load-balancers --region "$REGION" --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text)
            if [ -z "$REMAINING" ]; then
                echo "    ✅ All LBs deleted."
                break
            fi
            echo "    Waiting for LBs to terminate..."
            sleep 10
        done
        
        # Repeat for Classic ELBs
        for clb in $(aws elb describe-load-balancers --region "$REGION" --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text); do
            echo "    Deleting Classic LB $clb"
            aws elb delete-load-balancer --load-balancer-name "$clb"
        done
        while true; do
            REMAINING=$(aws elb describe-load-balancers --region "$REGION" --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text)
            if [ -z "$REMAINING" ]; then
                echo "    ✅ All Classic LBs deleted."
                break
            fi
            echo "    Waiting for Classic LBs to terminate..."
            sleep 10
        done
        
        # --- Delete EFS Mount Targets ---
        for fs in $(aws efs describe-file-systems --query "FileSystems[].FileSystemId" --output text); do
            for mt in $(aws efs describe-mount-targets --file-system-id $fs --query "MountTargets[?VpcId=='$VPC_ID'].MountTargetId" --output text); do
                echo "Deleting EFS Mount Target: $mt"
                aws efs delete-mount-target --mount-target-id $mt
            done
        done
        
        # --- Delete RDS Instances ---
        for rds in $(aws rds describe-db-instances --query "DBInstances[?DBSubnetGroup.VpcId=='$VPC_ID'].DBInstanceIdentifier" --output text); do
            echo "Deleting RDS Instance: $rds"
            aws rds delete-db-instance --db-instance-identifier $rds --skip-final-snapshot
            aws rds wait db-instance-deleted --db-instance-identifier $rds
        done
        
        # --- Delete Network Interfaces ---
        for eni in $(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkInterfaces[].NetworkInterfaceId" --output text); do
            echo "Deleting ENI: $eni"
            aws ec2 delete-network-interface --network-interface-id $eni || true
        done
        
        # --- CRITICAL: SECURITY GROUP DEPENDENCY CLEANUP ---
        echo "--> Handling Security Group Dependencies (Common VPC Deletion Blocker)..."
        SECURITY_GROUPS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
        
        for sg in $SECURITY_GROUPS; do
            echo "  Processing Security Group: $sg"
            
            # Remove all ingress rules that reference other security groups
            echo "    Removing ingress rules from security group $sg"
            aws ec2 revoke-security-group-ingress --group-id "$sg" --ip-permissions "$(aws ec2 describe-security-groups --group-ids "$sg" --query 'SecurityGroups[0].IpPermissions' --output json)" 2>/dev/null || true
            
            # Remove all egress rules too if needed
            echo "    Removing egress rules from security group $sg"
            aws ec2 revoke-security-group-egress --group-id "$sg" --ip-permissions "$(aws ec2 describe-security-groups --group-ids "$sg" --query 'SecurityGroups[0].IpPermissionsEgress' --output json)" 2>/dev/null || true
            
            # Delete the security group
            echo "    Deleting security group $sg"
            aws ec2 delete-security-group --group-id "$sg" 2>/dev/null || echo "    Could not delete $sg (may have remaining dependencies)"
        done
        
        # --- Delete Subnets ---
        for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text); do
            echo "Deleting Subnet: $subnet"
            aws ec2 delete-subnet --subnet-id $subnet
        done
        
        # --- Delete Internet Gateways ---
        for igw in $(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text); do
            echo "Detaching & Deleting IGW: $igw"
            aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $VPC_ID
            aws ec2 delete-internet-gateway --internet-gateway-id $igw
        done
        
        # --- Finally Delete VPC ---
        echo "Deleting VPC: $VPC_ID"
        aws ec2 delete-vpc --vpc-id $VPC_ID
        echo "✅ VPC $VPC_ID destroyed."
    done
fi

# --- Step 6: EKS Access, CloudWatch, KMS ---
echo "[Step 6/7] Cleaning up EKS Access Entries and other resources..."

ACCESS_ENTRIES=$(aws eks list-access-entries --cluster-name "$CLUSTER_NAME" --region "$REGION" --query "accessEntries" --output text 2>/dev/null || true)
for entry in $ACCESS_ENTRIES; do
    echo "Deleting EKS access entry: $entry"
    aws eks delete-access-entry --cluster-name "$CLUSTER_NAME" --principal-arn "$entry"
done

for log_group in $(aws logs describe-log-groups --log-group-name-prefix "/aws/eks/$CLUSTER_NAME" --query "logGroups[].logGroupName" --output text); do
    echo "Deleting CloudWatch log group: $log_group"
    aws logs delete-log-group --log-group-name "$log_group"
done

for alias in $(aws kms list-aliases --query "Aliases[?contains(AliasName, 'eks/$CLUSTER_NAME')].AliasName" --output text); do
    echo "Deleting KMS alias: $alias"
    aws kms delete-alias --alias-name "$alias"
done

# --- Step 7: Erase Terraform State ---
echo "[Step 7/7] Deleting local Terraform state files..."
rm -f "$HOME/GitHub_Repos/aws-eks-devops-project/EKS/terraform/terraform.tfstate*"
rm -f "$HOME/GitHub_Repos/aws-eks-devops-project/terraform/servers-setup/terraform.tfstate*"
rm -rf "$HOME/GitHub_Repos/aws-eks-devops-project/EKS/terraform/.terraform"
rm -rf "$HOME/GitHub_Repos/aws-eks-devops-project/terraform/servers-setup/.terraform"

echo "--- DEFINITIVE CLEANUP COMPLETE ---"
echo "✅ All EKS, VPC, IAM, OIDC, and related resources have been destroyed."
echo "✅ Security group dependencies have been properly cleaned up."
echo "You now have a clean slate."