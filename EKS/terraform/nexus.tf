#EKS/terraform/nexus.tf

resource "kubernetes_namespace" "eks_build" {
  provider = kubernetes.eks
  metadata {
    name = "eks-build"
  }
}

resource "kubernetes_deployment" "nexus" {
  provider = kubernetes.eks
  metadata {
    name      = "nexus-deployment"
    namespace = kubernetes_namespace.eks_build.metadata[0].name
    labels = {
      app = "nexus"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nexus"
      }
    }

    template {
      metadata {
        labels = {
          app = "nexus"
        }
      }

      spec {
        container {
          name  = "nexus"
          image = "sonatype/nexus3:latest"

          port {
            container_port = 8081
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "1"
              memory = "2Gi"
            }
          }

          volume_mount {
            mount_path = "/nexus-data"
            name       = "nexus-data"
          }
        }

        volume {
          name = "nexus-data"
          empty_dir {}
          # replace with PVC if you want persistence
        }
      }
    }
  }
}

resource "kubernetes_service" "nexus" {
  provider = kubernetes.eks
  metadata {
    name      = "nexus-service"
    namespace = kubernetes_namespace.eks_build.metadata[0].name
  }

  spec {
    selector = {
      app = "nexus"
    }

    port {
      port        = 8081
      target_port = 8081
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "nexus" {
  provider = kubernetes.eks
  metadata {
    name      = "nexus-ingress"
    namespace = kubernetes_namespace.eks_build.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.nexus.metadata[0].name
              port {
                number = 8081
              }
            }
          } 
        }
      }
    }
  }
}

# -------------------------
# Docker Registry Secret for Nexus
# -------------------------
resource "kubernetes_secret" "nexus_registry" {
  provider   = kubernetes.eks
  depends_on = [null_resource.wait_for_eks]

  metadata {
    name      = "nexus-credentials"
    namespace = kubernetes_namespace.eks_build.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "nexus.${kubernetes_namespace.eks_build.metadata[0].name}.svc.cluster.local:8081" = {
          auth = base64encode("admin:admin123")
        }
      }
    })
  }
}