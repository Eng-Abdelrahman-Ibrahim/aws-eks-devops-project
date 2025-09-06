# Namespace for builds
resource "kubernetes_namespace" "build" {
  metadata {
    name = "build"
  }
}

# Nexus Deployment
resource "kubernetes_deployment" "nexus" {
  depends_on = [module.eks]

  metadata {
    name      = "nexus"
    namespace = kubernetes_namespace.build.metadata[0].name
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
            limits = {
              cpu    = "1"
              memory = "2Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }

          volume_mount {
            name       = "nexus-data"
            mount_path = "/nexus-data"
          }
        }

        volume {
          name = "nexus-data"
          empty_dir {}
        }
      }
    }
  }
}

# Nexus Service
resource "kubernetes_service" "nexus" {
  depends_on = [module.eks]

  metadata {
    name      = "nexus"
    namespace = kubernetes_namespace.build.metadata[0].name
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
