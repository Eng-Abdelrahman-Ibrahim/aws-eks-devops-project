#EKS/terraform/kubeconfig.tf

data "template_file" "kubeconfig" {
  template = file("${path.module}/templates/kubeconfig.yml.j2")

  vars = {
    eks_name     = module.eks.cluster_name
    eks_endpoint = module.eks.cluster_endpoint
    eks_ca       = module.eks.cluster_certificate_authority_data
    eks_region   = var.eks_region       # <- make sure this exists
  }
}


# Write kubeconfig to ~/.kube/config
resource "local_file" "kubeconfig" {
  content  = data.template_file.kubeconfig.rendered
  filename = "${pathexpand("~/.kube/config")}"
}
