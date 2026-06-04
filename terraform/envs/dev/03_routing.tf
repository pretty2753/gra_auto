############################################
# 3. ROUTING LAYER (라우팅 테이블)
############################################

# Public Route Table
# → 0.0.0.0/0 트래픽을 IGW로 보내 인터넷 연결 허용
resource "aws_route_table" "project01_public_rt" {
  vpc_id = module.project01_vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.igw.igw_id
  }

  tags = {
    Name = "project01-public-rt"
  }
}

# Public Subnet 연결
# → 해당 subnet을 인터넷 가능한 라우팅 테이블에 연결
resource "aws_route_table_association" "bastion_rt" {
  subnet_id      = module.project01_public_subnet_bastion.subnet_id
  route_table_id = aws_route_table.project01_public_rt.id
}

resource "aws_route_table_association" "alb_a_rt" {
  subnet_id      = module.project01_public_subnet_alb_a.subnet_id
  route_table_id = aws_route_table.project01_public_rt.id
}

resource "aws_route_table_association" "alb_b_rt" {
  subnet_id      = module.project01_public_subnet_alb_b.subnet_id
  route_table_id = aws_route_table.project01_public_rt.id
}

# NAT Gateway
# → Private subnet이 인터넷 outbound 가능하도록 중계 역할
module "project01_ngw" {
  source    = "../../modules/nat-gateway"
  subnet_id = module.project01_public_subnet_bastion.subnet_id
  name      = "project01-ngw"
}

# Private Route Table
# → private subnet의 인터넷 outbound를 NAT로 보냄
resource "aws_route_table" "project01_private_rt" {
  vpc_id = module.project01_vpc.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = module.project01_ngw.nat_gateway_id
  }

  depends_on = [module.project01_ngw]

  tags = {
    Name = "project01-private-rt"
  }
}

# private Subnet 연결
# → 해당 subnet을 인터넷 가능한 라우팅 테이블에 연결
resource "aws_route_table_association" "was_rt" {
  subnet_id      = module.project01_private_subnet_was.subnet_id
  route_table_id = aws_route_table.project01_private_rt.id
}

# private Subnet 연결
# → 해당 subnet을 인터넷 가능한 라우팅 테이블에 연결
resource "aws_route_table_association" "db_rt" {
  subnet_id      = module.project01_private_subnet_db.subnet_id
  route_table_id = aws_route_table.project01_private_rt.id
}