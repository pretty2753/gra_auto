output "bastion_public_ip" {
  value = module.project01_bastion_ec2.public_ip
}

output "was_private_ip" {
  value = module.project01_was01_ec2.private_ip
}

output "db_private_ip" {
  value = module.project01_db_ec2.private_ip
}
