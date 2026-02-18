# 1. [sc.yaml 대체] 스토리지 클래스 (gp3) 생성
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  parameters = {
    type = "gp3"
  }
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
}

# 2. [jenkins-values.yaml + ingress + sa 대체] 젠킨스 설치
resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  namespace        = "jenkins" # [수정] 리소스 참조 대신 직접 입력
  create_namespace = true      # [추가] 헬름아, 방(네임스페이스) 없으면 네가 만들어라!
  version          = "5.1.4"

  values = [
    yamlencode({
      controller = {
        adminPassword = "admin" # 비밀번호 
        
        installPlugins = [
          "kubernetes",
          "workflow-aggregator",
          "git",
          "configuration-as-code",
          "github",
          "kubernetes-credentials-provider"
        ]
        
        serviceType = "ClusterIP"

        # 인그레스 설정
        ingress = {
          enabled = true
          apiVersion = "networking.k8s.io/v1"
          ingressClassName = "alb"
          annotations = {
            "alb.ingress.kubernetes.io/scheme" = "internet-facing"
            "alb.ingress.kubernetes.io/target-type" = "ip"
            "alb.ingress.kubernetes.io/backend-protocol-version" = "HTTP1"
            "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:ap-northeast-2:808985145578:certificate/a6fa7b8f-a325-4b93-8da4-1eae29a01523"
            "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
            "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
          }
          hostName = "jenkins.fastcampus-jihyun.link"
        }
        
        # 서비스 어카운트 (IAM 역할 연결)
        serviceAccount = {
          create = true
          name   = "jenkins-admin-sa"
          annotations = {
            "eks.amazonaws.com/role-arn" = "arn:aws:iam::808985145578:role/jenkins-ecr-push-role"
          }
        }
      }

      persistence = {
        enabled      = true
        storageClass = "gp3"
        size         = "20Gi"
      }
    })
  ]
  
  # 스토리지 클래스가 먼저 만들어져야 함
  depends_on = [kubernetes_storage_class.gp3]
}

# 3. [jenkins-role-binding.yaml 대체] 관리자 권한 부여
resource "kubernetes_cluster_role_binding" "jenkins_admin" {
  metadata {
    name = "jenkins-admin-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "jenkins-admin-sa"
    namespace = "jenkins" # [수정] 여기도 직접 입력
  }
}