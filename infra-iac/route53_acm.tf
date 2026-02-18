# 1. Route 53 호스팅 영역 (도메인 관리소)
data "aws_route53_zone" "selected" {
  name         = "fastcampus-jihyun.link"
  private_zone = false
}

# 2. ACM 인증서 신청
resource "aws_acm_certificate" "cert" {
  domain_name       = "fastcampus-jihyun.link"
  validation_method = "DNS"

  subject_alternative_names = ["*.fastcampus-jihyun.link"]


  lifecycle {
    # 인증서 갱신 시 새인증서를 먼저 만들고 기존 것 삭제
    create_before_destroy = true
  }

  tags = {
    Name = "eks-app-cert"
  }
}

# 3. 도메인 소유권 확인을 위한 레코드 자동 생성
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}