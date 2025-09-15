# ───────────────────────────────
# Namespace for ingress-nginx
# ───────────────────────────────
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

# ───────────────────────────────
# Helm release for NGINX Ingress
# ───────────────────────────────
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  version    = "4.10.0"

  values = [
    yamlencode({
      controller = {
         config = {
          "proxy-body-size" = "20m" 
        }
        replicaCount = 2
        service = {
          type = "LoadBalancer"
          annotations = {
            # Use NLB instead of classic ELB
            "service.beta.kubernetes.io/aws-load-balancer-type"                                = "nlb"
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
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  depends_on = [helm_release.nginx_ingress]
}
