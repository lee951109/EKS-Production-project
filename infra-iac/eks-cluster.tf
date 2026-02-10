data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = "1.31" # Kubernetes version

  vpc_config {
    # 실무에서는 보안을 위해 Private Subnet에만 클러스터 엔트포트에만 배치
    subnet_ids              = module.vpc.private_subnets
    security_group_ids      = [aws_security_group.node_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true

    // My Public IP 가져오기
    public_access_cidrs = ["${chomp(data.http.myip.response_body)}/32"]
  }

  # 클러스터 생성 전, IAM 정책이 먼저 연결되어 있어야 함을 명시 (의존성 관리)
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "${var.project_name}-cluster"
  }
}