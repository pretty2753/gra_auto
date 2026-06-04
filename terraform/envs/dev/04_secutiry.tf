############################################
# 4. SECURITY GROUP (방화벽 역할)
############################################

# Bastion SG
# → 외부에서 SSH 접속 허용 (관리용)
module "project01_bastion_sg" {
  source = "../../modules/security-group"
  name   = "project01-bastion-sg"
  vpc_id = module.project01_vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Admin SSH Access"
    },
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Grafana Access"
    },
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Prometheus Access"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = null
    }
  ]
}

# WAS SG
# → ALB만 WAS 접근 가능
# → Bastion만 SSH 접근 가능
module "project01_was_sg" {
  source = "../../modules/security-group"
  name   = "project01-was-sg"
  vpc_id = module.project01_vpc.vpc_id

  ingress_rules = [
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [module.project01_bastion_sg.sg_id]
      description     = "Bastion to SSH Access"
    },
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [module.project01_alb_sg.sg_id]
      description     = "ALB to WAS HTTP Access"
    },
    {
      from_port       = 9100
      to_port         = 9100
      protocol        = "tcp"
      security_groups = [module.project01_bastion_sg.sg_id]
      description     = "Bastion to prometheus Node Exporter"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = null
    }
  ]
}

# DB SG
# → WAS만 DB 접근 가능 (3-tier 구조 핵심)
module "project01_db_sg" {
  source = "../../modules/security-group"
  name   = "project01-db-sg"
  vpc_id = module.project01_vpc.vpc_id

  ingress_rules = [
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [module.project01_bastion_sg.sg_id]
      description     = "Bastion to DB SSH Access"
    },	
    {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [module.project01_was_sg.sg_id]
      description     = "WAS to DB Access"
    },
     {
      from_port       = 9100
      to_port         = 9100
      protocol        = "tcp"
      security_groups = [module.project01_bastion_sg.sg_id]
      description     = "Bastion to prometheus Node Exporter"
    },
     {
      from_port       = 9187
      to_port         = 9187
      protocol        = "tcp"
      security_groups = [module.project01_bastion_sg.sg_id]
      description     = "Bastion to prometheus postgres Exporter"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = null
    }
  ]
}


# ALB Security Group
# → 외부 HTTP/HTTPS 트래픽 허용
module "project01_alb_sg" {
  source = "../../modules/security-group"
  name   = "project01-alb-sg"
  vpc_id = module.project01_vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP External Traffic"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS External Traffic"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = null
    }
  ]
}