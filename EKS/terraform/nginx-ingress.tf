#EKS/terraform/nginx-ingress.tf

# ───────────────────────────────
# Namespace for ingress-nginx
# ───────────────────────────────
resource "kubernetes_namespace" "ingress_nginx" {
provider = kubernetes.eks

  metadata {
    name = "ingress-nginx"
  }
}

# ───────────────────────────────
# Helm release for NGINX Ingress
# ───────────────────────────────
resource "helm_release" "nginx_ingress" {

  provider = helm.eks
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    yamlencode({
      controller = {
        replicaCount = 2
        config = {
          "proxy-body-size" = "1g"
           "proxy-read-timeout": 600       # 10 minutes read timeout
           "proxy-send-timeout": 600       # 10 minutes send timeout
        }
        service = {
          type = "LoadBalancer"
          annotations = {
            # Use NLB instead of classic ELB
            "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
          }
        }
      }
    })
  ]

  wait    = true
  timeout = 600
}

# ───────────────────────────────
# Fetch the LoadBalancer hostname
# ───────────────────────────────
data "kubernetes_service" "nginx_lb" {
    provider = kubernetes.eks

  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  depends_on = [helm_release.nginx_ingress]
}
