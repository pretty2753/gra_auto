# route 53에 호스팅 영역에 등록된 도메인 조회
data "aws_route53_zone" "this" {
    name = var.domain_name
    private_zone = false 
}

data "aws_acm_certificate" "this" {
  domain   = "*.${var.domain_name}"
  statuses = ["ISSUED"]
  most_recent = true
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = var.alb_arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = data.aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }
}


resource "aws_route53_record" "this_domain" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "this_www" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

