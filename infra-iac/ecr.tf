
resource "aws_ecr_repository" "app_repo" {
  name = "status-checker-app"
  image_tag_mutability = "MUTABLE" # 같은 태그로 텊어쓰기 허용

  image_scanning_configuration {
    # 이미지를 올릴 때마다 보안 취약점을 자동으로 검사
    scan_on_push = true
  }
  
  tags = {
    Name = "status-checker-app"
  }
}

# 나중에 도커 명령어에서 사용할 ECR 주소를 출력
output "ecr_repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}