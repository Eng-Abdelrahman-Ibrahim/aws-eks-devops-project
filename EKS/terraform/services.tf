# Backend Service
resource "kubernetes_service" "backend" {
  depends_on = [module.eks]

  metadata {
    name = "backend"
  }

  spec {
    selector = {
      app = "backend"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

# Frontend Service
resource "kubernetes_service" "frontend" {
  depends_on = [module.eks]

  metadata {
    name = "frontend"
  }

  spec {
    selector = {
      app = "frontend"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}
