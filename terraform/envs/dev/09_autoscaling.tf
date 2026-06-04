############################################
# Auto Scaling (ASG)
############################################

#2차 실행시 적용 (주석해제)

module "asg" {
  source = "../../modules/asg"

  ami_id = var.ami_id

  asg_name = "project01-asg"

  instance_type = "t3.micro"

  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  subnet_ids = [
    module.project01_private_subnet_was.subnet_id
  ]

  security_group_id = module.project01_was_sg.sg_id

  key_name = module.project01_was_ec2_key.key_name

  target_group_arns = [
    module.project01_alb.target_group_arn
  ]
}
