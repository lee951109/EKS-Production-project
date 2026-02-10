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