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

  # AWS LBC가 완전히 설치된 후에만 프로메테우스를 설치하도록 강제
  depends_on = [ helm_release.aws_lbc ]

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
          enabled          = true
          ingressClassName = "alb"
          annotations = {
            "kubernetes.io/ingress.class"                    = "alb"
            "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
            "alb.ingress.kubernetes.io/target-type"          = "ip"
            "alb.ingress.kubernetes.io/certificate-arn"      = aws_acm_certificate.cert.arn
            "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
            "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
          }
          hosts = ["grafana.fastcampus-jihyun.link"]
          path  = "/"
        }
      }
    })
  ]
}

# 로그 수집 및 저장 시스템 (Loki + Promtail)
resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  version          = "2.9.11"

  values = [
    yamlencode({
      # 1. 기존 그라파나/프로메테우스와 중복 설치 방지
      grafana    = { enabled = false }
      prometheus = { enabled = false }

      # 2. Loki 설정
      loki = {
        enabled = true
        persistence = {
          enabled          = true
          storageClassName = "gp3"
          size             = "10Gi"
        }
      }

      # 3. Promtail 설정
      promtail = {
        enabled = true
      }
    })
  ]
}