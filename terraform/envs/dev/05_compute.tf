############################################
# 5. COMPUTE (EC2 인스턴스)
############################################

# [1] SSH 키페어 생성
# → EC2 인스턴스에 안전하게 접속하기 위한 열쇠를 만듭니다. (Bastion용은 삭제됨)
module "project02_was_ec2_key" {
  source   = "../../modules/keypair"
  key_name = "project02-was-key"
}

module "project02_db_ec2_key" {
  source   = "../../modules/keypair"
  key_name = "project02-db-key"
}


# [3] DB (데이터베이스 서버)
# → PostgreSQL 등 데이터베이스를 구동할 단일 서버입니다. (데이터 정합성을 위해 1대만 운영)
module "project02_db_ec2" {
  source             = "../../modules/ec2"
  instance_type      = "t3.micro"
  subnet_id          = module.project02_private_subnet_db.subnet_id
  security_group_ids = [module.project02_db_sg.sg_id]
  key_name           = module.project02_db_ec2_key.key_name
  name               = "project02_db_ec2"
  tags               = { Role = "DB" }

  root_volume_size = 30
}