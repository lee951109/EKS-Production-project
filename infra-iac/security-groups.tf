
# 1. ALB를 위한 보안 그룹
resource "aws_security_group" "alb_sg" {
  description = "Security group for Application Load Balancer"
  name        = "${var.project_name}-alb-sg"
  vpc_id      = module.vpc.vpc_id

  # 외부로부터의 HTTP 요청 허용
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 외부로부터의 HTTPS 요청 허용
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# 2. EKS 워커 노드를 위한 보안 그룹
resource "aws_security_group" "node_sg" {
  description = "Security group for EKS worker nodes"
  name        = "${var.project_name}-node-sg"
  vpc_id      = module.vpc.vpc_id

  # 오직 위에서 만든 ALB 보안 그룹을 거친 트래픽만 허용 (Chaining)
  ingress {
    description     = "Allow traffic from ALB only"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # 모든 아웃바운드 트래픽 허용 (인터넷 나가기 위함)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-node-sg"
  }
}