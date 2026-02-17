# EKS Cluster Role
# Cluster Control plan이 AWS 리소스를 관리할 때 사용하는 권한
resource "aws_iam_role" "cluster_role" {
  name = "${var.project_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

# cluster에 필요한 표준 정책 연결
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  // EKS가 사용자를 대신해 리소스를 생성하고 관리(예: 로드밸런서 생성 등)할 수 있게 해주는 마스터 권한
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# EKS Node Group Role
# 실제 앱이 돌아가는 노드(EC2)들이 가져야 할 권한
resource "aws_iam_role" "node_role" {
  name = "${var.project_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# 노드에 필요한 필수 정책들 연결
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  // 워커 노드가 EKS 클러스터에 연결되어 관리될 수 있게 해주는 권한
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  // Pod들이 VPC 내부 IP를 할당받아 서로 통신할 수 있게 해주는 네트워크(CNI) 관련 권힌
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  // ECR에서 이미지를 Pull 해오려면 해당 권한이 필수!!!
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

# 1. 현재 AWS 계정 ID 정보 조회
data "aws_caller_identity" "current" {}

# ECR 접근 권한을 가진 IAM 역할 생성
resource "aws_iam_role" "jenkins_ecr_role" {
  name = "jenkins-ecr-push-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          # 모듈의 출력값을 참조하여 의존성 해결
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            # 공식 모듈 출력값은 https:// 가 이미 제거되어 있음
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:jenkins:jenkins-admin-sa"
          }
        }
      }
    ]
  })
}

# ECR PowerUser 정책 연결
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.jenkins_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# 로드밸런서 컨트롤러를 위한 IAM 정책 가져오기
resource "aws_iam_policy" "lbc_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Permissions for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/iam_policy.json")
}

# 로드밸런서 컨트롤러용 IAM 역할 생성
resource "aws_iam_role" "lbc_role" {
  name = "aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          # EKS 모듈 OIDC 참조
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            # OIDC URL에서 https://를 제거한 값 뒤에 서브넷 붙이기
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller",
            "${module.eks.oidc_provider}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# 역할과 정책 연결
resource "aws_iam_role_policy_attachment" "lbc_attach" {
  role       = aws_iam_role.lbc_role.name
  policy_arn = aws_iam_policy.lbc_policy.arn
}