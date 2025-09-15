resource "kubernetes_namespace" "eks_build" {
  metadata {
    name = "eks-build"
  }
}

resource "kubernetes_deployment" "nexus" {
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
          path     = "/"
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

resource "kubernetes_secret" "nexus_registry" {
  metadata {
    name      = "nexus-registry"
    namespace = kubernetes_namespace.eks_build.metadata[0].name
  }
  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = base64encode(jsonencode({
      auths = {
        "nexus-service.eks-build.svc.cluster.local:8081" = {
          username = "admin"       # Your Nexus username
          password = "admin123"    # Your Nexus password
        }
      }
    }))
  }
}

