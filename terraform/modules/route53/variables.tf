variable "domain_name" {
    type = string
    default = "등록된 도메인주소"
}

variable "alb_arn" {
  description = "443 리스너를 붙일 ALB의 ARN"
  type        = string
}

variable "alb_dns_name" {
  description = "Route53 A레코드(alias)에 연결할 ALB DNS 주소"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB의 호스팅 영역 ID (alias용)"
  type        = string
}

variable "target_group_arn" {
  description = "443 리스너가 forward할 타겟 그룹 ARN"
  type        = string
}