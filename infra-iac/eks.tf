# My Public IP 가져오기
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = "1.32"

  # OIDC Provider 활성화 (IRSA를 위해 필수)
  enable_irsa = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # EBS CSI 드라이버 애드온 설정
  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = aws_iam_role.ebs_csi_role.arn
    }
  }

  # 클러스터 엔드포인트 설정
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["${chomp(data.http.myip.response_body)}/32"]

  # 클러스터를 만든 IAM 사용자에게 자동으로 관리자 권한을 부여.
  enable_cluster_creator_admin_permissions = true

  # EKS Managed Node Group 설정
  eks_managed_node_groups = {
    main = {
      node_group_name = "${var.project_name}-node-group"
      instance_types  = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # 필요한 정책 추가
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      }
    }
  }


  tags = {
    Name = "${var.project_name}-cluster"
  }
}


# AWS Load Balancer Controller 설치
resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1" # 안정적인 버전

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "region"
    value = var.region
  }

  # iam.tf에서 만든 lbc_role의 ARN을 자동으로 조회
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.lbc_role.arn
  }
}