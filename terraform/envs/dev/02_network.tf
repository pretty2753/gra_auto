############################################
# 2. NETWORK LAYER (VPC / IGW / SUBNET)
############################################

# [1] VPC (Virtual Private Cloud) 생성
# → 클라우드 내에 나만의 논리적인 독립 네트워크 공간을 만듭니다.
# → 10.0.0.0/16 대역을 사용하여 총 65,536개의 IP를 가질 수 있습니다.
module "project02_vpc" {
  source     = "../../modules/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "project02-vpc"
}

# [2] Internet Gateway (IGW) 생성
# → 만들어진 VPC가 외부 인터넷과 통신할 수 있도록 출입구(Gateway)를 붙여줍니다.
module "igw" {
  source = "../../modules/internet-gateway"
  vpc_id = module.project02_vpc.vpc_id
  name   = "project02-igw"
}

# [3] 퍼블릭 서브넷 (인터넷 통신 가능 영역)
# Public Subnet A (AZ-a)
# → ALB(로드밸런서)의 노드 1개와 외부 통신을 돕는 NAT 인스턴스, Tailscale 터널링 서버가 들어갑니다.
module "project02_public_subnet_a" {
  source        = "../../modules/subnet"
  vpc_id        = module.project02_vpc.vpc_id
  cidr_block    = "10.0.1.0/24"
  az            = data.aws_availability_zones.available.names[0]
  map_public_ip = true  # EC2 생성 시 자동으로 퍼블릭 IP를 부여함
  name          = "project02-public-subnet-a"
}

# Public Subnet B (AZ-b)
# → ALB가 고가용성을 유지하기 위해 무조건 2개 이상의 AZ를 요구하므로 만들어둔 서브넷입니다.
module "project02_public_subnet_b" {
  source        = "../../modules/subnet"
  vpc_id        = module.project02_vpc.vpc_id
  cidr_block    = "10.0.2.0/24"
  az            = data.aws_availability_zones.available.names[1]
  map_public_ip = true
  name          = "project02-public-subnet-b"
}

# [4] 프라이빗 서브넷 (인터넷 직접 통신 불가 영역 - 보안 강화)
# WAS Private Subnet (AZ-a)
# → 실제 서비스 로직(FastAPI 등)이 돌아가는 웹 어플리케이션 서버가 들어갑니다.
module "project02_private_subnet_was" {
  source        = "../../modules/subnet"
  vpc_id        = module.project02_vpc.vpc_id
  cidr_block    = "10.0.10.0/24"
  az            = data.aws_availability_zones.available.names[0]
  map_public_ip = false # 외부에서 IP로 직접 접근할 수 없도록 막음
  name          = "project02-private-subnet-was"
}

# DB Private Subnet (AZ-a)
# → 가장 강력한 보안이 필요한 데이터베이스 전용 서브넷입니다.
module "project02_private_subnet_db" {
  source        = "../../modules/subnet"
  vpc_id        = module.project02_vpc.vpc_id
  cidr_block    = "10.0.30.0/24"
  az            = data.aws_availability_zones.available.names[0]
  map_public_ip = false
  name          = "project02-private-subnet-db"
}