module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.1.0"

  endpoint_public_access = true

  name = "ecomm-eks"
  kubernetes_version = "1.33"

  vpc_id = module.ecomm-vpc.vpc_id
  subnet_ids = module.ecomm-vpc.private_subnets


  tags = {
    Environment = "dev"
    Terraform   = "true"
  }


 # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    dev = {
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}