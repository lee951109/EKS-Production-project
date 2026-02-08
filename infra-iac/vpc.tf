
# 사용 가능한 가용 영역(AZ) 목록 조회
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  # 서울 리전의 가용 영역 3개를 사용 (2a, 2b, 2c)
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # 서브넷 설계: 퍼블릭(외부 통신), 프라이빗(EKS 노드/DB용)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # NAT Gateway 설정 (프라이빗 서브넷의 노드가 외부 인터넷과 통신하기 위함)
  # 실무 환경에서는 고가용성을 위해 AZ당 1개 생성이 원칙
  enable_nat_gateway     = true
  single_nat_gateway     = true # 비용 효율을 위해 TRUE
  one_nat_gateway_per_az = false

  # EKS가 로드밸런서를 생성할 때 서브넷을 찾을 수 있도록 태깅
  # 나중에 EKS를 배포할 때 해당 태그가 없으면 LB가 자동 생성 안돼서 미리 설정
  public_subnet_tags = {
    "kubernetes.io/role/elb"                            = "1"
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                   = "1"
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
  }

  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}