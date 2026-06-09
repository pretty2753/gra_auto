############################################
# 6. APPLICATION LOAD BALANCER (ALB)
############################################

# [1] ALB (로드밸런서)
# → 외부(인터넷)에서 들어오는 사용자 트래픽을 받아서 
#    내부(프라이빗 서브넷)에 있는 여러 대의 WAS 서버로 골고루 분배합니다.
# → 서버가 죽었는지 살았는지(Health Check) 확인하는 기능도 수행합니다.
module "project02_alb" {
  source = "../../modules/alb"

  name   = "project02-alb"
  vpc_id = module.project02_vpc.vpc_id

  # 로드밸런서는 고가용성을 위해 무조건 2개 이상의 가용 영역(AZ)에 위치해야 하므로 
  # A와 B 두 개의 퍼블릭 서브넷을 지정합니다.
  subnet_ids = [
    module.project02_public_subnet_a.subnet_id,
    module.project02_public_subnet_b.subnet_id
  ]

  # ALB 전용 방화벽(80, 443 포트 오픈)을 연결합니다.
  security_group_ids = [module.project02_alb_sg.sg_id]  

  # ASG(Auto Scaling Group)를 사용할 예정이므로, 특정 인스턴스를 수동으로 등록하지 않고 빈 값으로 둡니다.
  # (ASG가 알아서 인스턴스를 늘리거나 줄이면서 로드밸런서에 등록/해제 해줍니다.)
  target_instance_ids = {}
}