# EKS/terraform/ansible-vars.tf
resource "local_file" "ansible_vars" {
  content = templatefile("${path.module}/templates/ansible-vars.yml.tpl", {
    nginx_lb_hostname = data.kubernetes_service.nginx_lb.status[0].load_balancer[0].ingress[0].hostname
    nexus_docker_lb_hostname = data.kubernetes_service.nexus_docker_lb.status[0].load_balancer[0].ingress[0].hostname
    aws_account_id    = data.aws_caller_identity.current.account_id
  })
  filename = "${path.module}/../../ansible/vars/terraform-generated.yml"
  
  depends_on = [helm_release.nginx_ingress, kubernetes_service.nexus_docker_registry]
}