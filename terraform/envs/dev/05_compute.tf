############################################
# 5. COMPUTE (EC2)
############################################

module "project01_bastion_ec2_key" {
  source   = "../../modules/keypair"
  key_name = "project01-bastion-key"
}


module "project01_was_ec2_key" {
  source   = "../../modules/keypair"
  key_name = "project01-was-key"
}


module "project01_db_ec2_key" {
  source   = "../../modules/keypair"
  key_name = "project01-db-key"
}



# Bastion Server
# → 운영자가 SSH로 접속하는 유일한 entry point
module "project01_bastion_ec2" {
  source             = "../../modules/ec2"
  instance_type      = "t3.micro"
  subnet_id          = module.project01_public_subnet_bastion.subnet_id
  security_group_ids = [module.project01_bastion_sg.sg_id]
  key_name           = module.project01_bastion_ec2_key.key_name
  name               = "project01_bastion_ec2"
  tags               = { Role = "Bastion" }

  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  root_volume_size = 30
}

# WAS Server
# → 실제 애플리케이션 실행 서버
module "project01_was01_ec2" {
  source             = "../../modules/ec2"
  instance_type      = "t3.micro"
  subnet_id          = module.project01_private_subnet_was.subnet_id
  security_group_ids = [module.project01_was_sg.sg_id]
  key_name           = module.project01_was_ec2_key.key_name
  name               = "project01-was01-ec2"
  tags               = { Role = "WAS" }

  root_volume_size = 30
}

# DB Server
# → 데이터 저장 전용 서버
module "project01_db_ec2" {
  source             = "../../modules/ec2"
  instance_type      = "t3.micro"
  subnet_id          = module.project01_private_subnet_db.subnet_id
  security_group_ids = [module.project01_db_sg.sg_id]
  key_name           = module.project01_db_ec2_key.key_name
  name               = "project01_db_ec2"
  tags               = { Role = "DB" }

  root_volume_size = 30
}