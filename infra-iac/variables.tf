variable "region" {
  description = "AWS 리전 설정"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "eks-production"
}

variable "vpc_cidr" {
  description = "VPC CIDE 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "jenkins_admin_password" {
  description = "Jenkins 초기 관리자 패스워드"
  type        = string
  sensitive   = true
}