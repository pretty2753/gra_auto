
# ALB
# → 사용자 트래픽을 WAS로 라우팅
# → health check + target group 포함
module "project01_alb" {
  source = "../../modules/alb"

  name   = "project01-alb"
  vpc_id = module.project01_vpc.vpc_id

  subnet_ids = [
    module.project01_public_subnet_alb_a.subnet_id,
    module.project01_public_subnet_alb_b.subnet_id
  ]

  security_group_ids = [module.project01_alb_sg.sg_id]  

  # ASG 없을 경우
  #target_instance_ids = { was = module.project01_was01_ec2.instance_id }

  # ASG 사용시 target_group_arns으로 인스턴스를 자동 등록으로 빈값 설정
  target_instance_ids = {}
} 