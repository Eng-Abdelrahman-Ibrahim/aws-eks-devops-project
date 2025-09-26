#EKS/terraform/eks.tf

# ---------------------------
# Launch Template for worker nodes
# ---------------------------

resource "aws_launch_template" "myapp_nodes" {
  name_prefix = "myapp-nodes-"

  user_data = base64encode(<<-EOT
                #!/bin/bash
                set -e
                # Install EKS-supported containerd
                dnf install -y yum-utils
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                dnf install -y containerd.io

                # Configure containerd for CRI
                mkdir -p /etc/containerd
                containerd config default | tee /etc/containerd/config.toml

                # Enable systemd cgroups
                sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

                # Add Nexus registry mirror
                sed -i '/registry.mirrors]/a\\
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."${data.kubernetes_service.nexus_docker_lb.status[0].load_balancer[0].ingress[0].hostname}:8082"]\\
    endpoint = ["http://${data.kubernetes_service.nexus_docker_lb.status[0].load_balancer[0].ingress[0].hostname}:8082"]' /etc/containerd/config.toml

                systemctl enable containerd
                systemctl restart containerd

                # Bootstrap EKS
                /etc/eks/bootstrap.sh ${local.name}
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
      }

      tags = local.tags
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
