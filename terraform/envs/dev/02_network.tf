############################################
# 2. NETWORK LAYER (VPC / IGW / SUBNET)
############################################

# VPC 생성
# → 모든 네트워크 리소스의 최상위 컨테이너
module "project01_vpc" {
  source     = "../../modules/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "project01-vpc"
}

# Internet Gateway 생성
# → VPC 내부에서 인터넷으로 나가는 출구 역할
module "igw" {
  source = "../../modules/internet-gateway"
  vpc_id = module.project01_vpc.vpc_id
  name   = "project01-igw"
}

# Bastion Subnet (Public)
# → 관리자 접속용 서버가 위치하는 퍼블릭 서브넷
module "project01_public_subnet_bastion" {
  source        = "../../modules/subnet"
  vpc_id        = module.project01_vpc.vpc_id
  cidr_block    = "10.0.1.0/24"
  az            = data.aws_availability_zones.available.names[0]
  map_public_ip = true
  name          = "project01-public-subnet-bastion"
}

# ALB Public Subnet (A/B)
# → 로드밸런서가 외부 요청을 받는 퍼블릭 서브넷
# → AZ 분산으로 장애 대비 (HA 구성)
module "project01_public_subnet_alb_a" {
  source        = "../../modules/subnet"
  vpc_id        = module.project01_vpc.vpc_id
  cidr_block    = "10.0.2.0/24"
  az            = data.aws_availability_zones.available.names[0]
  map_public_ip = true
  name          = "project01-public-subnet-alb-a"
}

module "project01_public_subnet_alb_b" {
  source        = "../../modules/subnet"
  vpc_id        = module.project01_vpc.vpc_id
  cidr_block    = "10.0.3.0/24"
  az            = data.aws_availability_zones.available.names[1]
  map_public_ip = true
  name          = "project01-public-subnet-alb-b"
}


# WAS Private Subnet
# → 실제 애플리케이션 서버가 위치 (외부 직접 접근 불가)
module "project01_private_subnet_was" {
  source        = "../../modules/subnet"
  vpc_id        = module.project01_vpc.vpc_id
  cidr_block    = "10.0.10.0/24"
  az            = data.aws_availability_zones.available.names[0]
  map_public_ip = false
  name          = "project01-private-subnet-was"
}

# DB Private Subnet
# → 데이터베이스 전용 (외부 완전 차단)
module "project01_private_subnet_db" {
  source        = "../../modules/subnet"
  vpc_id        = module.project01_vpc.vpc_id
  cidr_block    = "10.0.30.0/24"
  az            = data.aws_availability_zones.available.names[0]
  map_public_ip = false
  name          = "project01-private-subnet-db"
}