# 1. 모니터링 전용 네임스페이스 생성
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# 2. Kube-Prometheus-Stack 설치 (Prometheus + Grafana)
resource "helm_release" "prometheus_stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "69.6.0" # 최신 안정 버전

  # 젠킨스와 마찬가지로 gp3 스토리지 클래스를 사용하여 데이터 보존
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "gp3"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "10Gi"
  }

  # 그라파나 설정 및 도메인 연결 (Ingress)
  values = [
    jsonencode({
      grafana = {
        persistence = {
          enabled          = true
          storageClassName = "gp3"
          size             = "5Gi"
        }
        ingress = {
          enabled   = true
          ingressClassName = "alb"
          annotations = {
            "kubernetes.io/ingress.class"      = "alb"
            "alb.ingress.kubernetes.io/scheme" = "internet-facing"
            "alb.ingress.kubernetes.io/target-type" = "ip"
            "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:ap-northeast-2:808985145578:certificate/a6fa7b8f-a325-4b93-8da4-1eae29a01523"
            "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
            "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
          }
          hosts = ["grafana.fastcampus-jihyun.link"]
          path  = "/"
        }
      }
    })
  ]
}