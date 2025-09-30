#EKS/terraform/eks.tf

# ---------------------------
# Launch Template for worker nodes
# ---------------------------

resource "aws_launch_template" "myapp_nodes" {
  name_prefix = "myapp-nodes-"

  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -e

    # Bootstrap EKS node with cluster name
    /etc/eks/bootstrap.sh ${local.name}

    # Install CloudWatch Agent
    yum install -y amazon-cloudwatch-agent

    # Create CloudWatch Agent configuration file
    cat << EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
      "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
      },
      "metrics": {
        "append_dimensions": {
          "InstanceId": "$${aws:InstanceId}"
        },
        "metrics_collected": {
          "cpu": {
            "measurement": [
              "cpu_usage_idle",
              "cpu_usage_user",
              "cpu_usage_system"
            ],
            "metrics_collection_interval": 60,
            "totalcpu": true
          },
          "mem": {
            "measurement": [
              "mem_used_percent"
            ],
            "metrics_collection_interval": 60
          },
          "disk": {
            "measurement": [
              "used_percent"
            ],
            "metrics_collection_interval": 60,
            "resources": [
              "*"
            ]
          }
        }
      }
    }
    EOF

    # Start CloudWatch Agent with config
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }
}


# ---------------------------
# EBS CSI Driver IAM Role with IRSA
# ---------------------------

resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "${local.name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" : "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" : "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ensure resources that talk to k8s wait until the EKS module finishes
resource "null_resource" "wait_for_eks" {
  depends_on = [module.eks]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name
  kubernetes_version = "1.33"

  # Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  enable_irsa = true

  access_entries = {
    # Access entry for the Ansible role
    AnsibleRole = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ansible-eks-role"
      policy_associations = {
        EKSAdminPolicy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # EKS Addons with proper IRSA for EBS CSI
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access  = true
  endpoint_private_access = true

  # Reference the security group defined locally in this project
  additional_security_group_ids = [aws_security_group.eks_to_ansible_access.id]

  self_managed_node_groups = {
    myapp-nodes = {
      ami_type      = "AL2023_x86_64_STANDARD"
      instance_type = "t3.medium"

      min_size     = 2
      max_size     = 3
      desired_size = 2

      launch_template = {
        id      = aws_launch_template.myapp_nodes.id
        version = "$Latest"
      }

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        CloudWatchAgentServerPolicy   = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }

      tags = local.tags
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
