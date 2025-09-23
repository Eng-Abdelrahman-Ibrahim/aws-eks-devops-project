#EKS/terraform/nexus.tf

resource "kubernetes_namespace" "eks_build" {
  provider = kubernetes.eks
  metadata {
    name = "eks-build"
  }
}

# Create immediate binding storage class to avoid WaitForFirstConsumer issues
resource "kubernetes_storage_class" "gp2_immediate" {
  provider = kubernetes.eks
  
  metadata {
    name = "gp2-immediate"
  }
  
  storage_provisioner    = "kubernetes.io/aws-ebs"
  reclaim_policy        = "Delete"
  volume_binding_mode   = "Immediate"
  allow_volume_expansion = true
  
  parameters = {
    type = "gp2"
    fsType = "ext4"
  }
}

resource "kubernetes_persistent_volume_claim" "nexus_pvc" {
  provider = kubernetes.eks

  metadata {
    name      = "nexus-pvc"
    namespace = kubernetes_namespace.eks_build.metadata[0].name
  }

  spec {
    storage_class_name = kubernetes_storage_class.gp2_immediate.metadata[0].name
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
  
  wait_until_bound = false
}

resource "kubernetes_deployment" "nexus" {
  provider = kubernetes.eks
  wait_for_rollout = false
  
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
        # Add security context for proper file permissions
        security_context {
          run_as_user  = 200
          run_as_group = 200
          fs_group     = 200
        }

        container {
          name  = "nexus"
          image = "sonatype/nexus3:latest"
          image_pull_policy = "Always"

          port {
            container_port = 8081
            name          = "nexus-ui"
          }

          # Add environment variables for better performance and Docker registry
          env {
            name  = "INSTALL4J_ADD_VM_PARAMS"
            value = "-Xms1g -Xmx2g -XX:MaxDirectMemorySize=3g -Djava.util.prefs.userRoot=/nexus-data/javaprefs"
          }

          env {
            name  = "NEXUS_SECURITY_RANDOMPASSWORD"
            value = "false"
          }

          # Reduced resource requirements to fit t3.medium nodes better
          resources {
            requests = {
              cpu    = "250m"
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

          # Improved health checks with longer delays
          liveness_probe {
            http_get {
              path = "/service/rest/v1/status"
              port = 8081
            }
            initial_delay_seconds = 180
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/service/rest/v1/status"
              port = 8081
            }
            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 10
            failure_threshold     = 5
          }
        }

         volume {
           name = "nexus-data"
           persistent_volume_claim {
             claim_name = kubernetes_persistent_volume_claim.nexus_pvc.metadata[0].name
           }
         }

        # Add node selector for better performance (optional)
        node_selector = {
          "kubernetes.io/arch" = "amd64"
        }
      }
    }
  }

  depends_on = [kubernetes_persistent_volume_claim.nexus_pvc]
}

resource "kubernetes_service" "nexus" {
  provider = kubernetes.eks
  metadata {
    name      = "nexus-service"
    namespace = kubernetes_namespace.eks_build.metadata[0].name
    labels = {
      app = "nexus"
    }
  }

  spec {
    selector = {
      app = "nexus"
    }

    port {
      name        = "nexus-ui"
      port        = 8081
      target_port = 8081
      protocol    = "TCP"
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
      "nginx.ingress.kubernetes.io/proxy-body-size" = "0"
    }
  }

  spec {
    rule {
      host = "nexus.local"
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

# Separate service for Docker registry (LoadBalancer)
resource "kubernetes_service" "nexus_docker_registry" {
  provider = kubernetes.eks
  metadata {
    name      = "nexus-docker-service"
    namespace = kubernetes_namespace.eks_build.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }

  spec {
    selector = {
      app = "nexus"
    }

    port {
      name        = "docker-registry"
      port        = 8082
      target_port = 8082
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}

# Add data source for the Nexus Docker LoadBalancer
data "kubernetes_service" "nexus_docker_lb" {
  provider = kubernetes.eks

  metadata {
    name      = "nexus-docker-service"
    namespace = kubernetes_namespace.eks_build.metadata[0].name
  }

  depends_on = [kubernetes_service.nexus_docker_registry]
}

# Docker registry secret using the correct LoadBalancer
resource "kubernetes_secret" "nexus_registry" {
  provider   = kubernetes.eks
  depends_on = [null_resource.wait_for_eks, kubernetes_service.nexus_docker_registry]

  metadata {
    name      = "nexus-credentials"
    namespace = kubernetes_namespace.eks_build.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        # Use the Nexus Docker LoadBalancer hostname
        "${data.kubernetes_service.nexus_docker_lb.status[0].load_balancer[0].ingress[0].hostname}:8082" = {
          auth = base64encode("admin:admin123") # Change to your username and password, or make it variable for security
        }
      }
    })
  }
}