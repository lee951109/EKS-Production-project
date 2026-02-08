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