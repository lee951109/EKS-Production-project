resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  version = "6.7.11"

  # LBC가 완전히 뜬 후에 설치되도록 순서 보장
  depends_on = [helm_release.aws_lbc]

  values = [
    yamlencode({
      server = {
        # ALB에서 HTTPS(SSL)를 해제하고 내부 Pod로는 HTTP로 보내기 위한 필수 설정
        extraArgs = ["--insecure"]

        ingress = {
          enabled          = true
          ingressClassName = "alb"
          annotations = {
            "alb.ingress.kubernetes.io/scheme"                   = "internet-facing"
            "alb.ingress.kubernetes.io/target-type"              = "ip"
            "alb.ingress.kubernetes.io/backend-protocol-version" = "HTTP1"
            "alb.ingress.kubernetes.io/certificate-arn"          = aws_acm_certificate.cert.arn
            "alb.ingress.kubernetes.io/listen-ports"             = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
            "alb.ingress.kubernetes.io/actions.ssl-redirect"     = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
          }
          hosts = [
            "argocd.fastcampus-jihyun.link"
          ]
        }
      }
    })
  ]
}