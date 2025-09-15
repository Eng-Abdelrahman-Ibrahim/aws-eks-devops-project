#EKS/terraform/eks.tf


# ---------------------------
# Launch Template for worker nodes
# ---------------------------

resource "aws_launch_template" "myapp_nodes" {
  name_prefix = "myapp-nodes-"

  user_data = base64encode(<<-EOT
              #!/bin/bash
              set -e
              amazon-linux-extras enable containerd
              yum install -y containerd
              systemctl enable containerd
              systemctl start containerd
              systemctl restart kubelet
              EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }
}



module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name
  kubernetes_version = "1.33"

  # Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"


  access_entries = {
    # Access entry for the Ansible role
    AnsibleRole = {
      principal_arn = "arn:aws:iam::068732175550:role/ansible-eks-role"
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

  # EKS Addons
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
      most_recent = true
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

      min_size = 2
      max_size = 3
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2

      launch_template = {
        id      = aws_launch_template.myapp_nodes.id
        version = "$Latest"
      }

      # 🔑 ADD SSM POLICY FOR WORKER NODES

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
      tags = local.tags
    }
  }
}



# Get current AWS account ID
data "aws_caller_identity" "current" {}


