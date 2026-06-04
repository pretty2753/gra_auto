############################################
# 7-1. Ansible - bootstrap전용 inventory.yml 생성
############################################
resource "local_file" "ansible_inventory_bootstrap" {

  #filename = "${path.root}/../../../ansible/inventories/dev/inventory.yml"
  filename = "${path.root}/../../../ansible/inventories/bootstrap/inventory.yml"

  content = yamlencode({
    all = {
      # 기본값으로 ec2-user / bastion 키를 사용
      vars = {
        ansible_user                 = "ec2-user"
        ansible_ssh_private_key_file = "~/.ssh/project01-bastion-key.pem"
        # 호스트 키 체크 생략
        ansible_host_key_checking    = false
      }

      children = {
        bastion = {
          hosts = {
            bastion01 = {
              ansible_host                    = module.project01_bastion_ec2.public_ip
              #ansible_user                    = "ec2-user"
              ansible_ssh_private_key_file    = "~/.ssh/${module.project01_bastion_ec2_key.key_name}.pem"
            }
          }
        }

        was = {
          hosts = {
            was01 = {
              ansible_host                    = module.project01_was01_ec2.private_ip
              #ansible_user                    = "adreamin"
			  #ansible_user                    = "ec2-user"
              ansible_ssh_private_key_file    = "~/.ssh/${module.project01_was_ec2_key.key_name}.pem"
              #ansible_ssh_common_args        = "-o ProxyJump=bastion01"
			  # .ssh/config 설정하지 않을경우
			  	#ansible_ssh_common_args      = "-o ProxyJump=ec2-user@${module.project01_bastion_ec2.public_ip} -o IdentityFile=~/.ssh/project01-bastion-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
              ansible_ssh_common_args = <<-EOT
                -o ProxyCommand="ssh -i ~/.ssh/project01-bastion-key.pem -W %h:%p -q ec2-user@${module.project01_bastion_ec2.public_ip}"
                -o StrictHostKeyChecking=no
                -o UserKnownHostsFile=/dev/null
              EOT			  
            }
          }
        }

        db = {
          hosts = {
            db01 = {
              ansible_host                    = module.project01_db_ec2.private_ip
              #ansible_user                    = "adreamin"
			  #ansible_user                    = "ec2-user"
              ansible_ssh_private_key_file    = "~/.ssh/${module.project01_db_ec2_key.key_name}.pem"
              #ansible_ssh_common_args        = "-o ProxyJump=bastion01"
			  # .ssh/config 설정하지 않을경우
			  	#ansible_ssh_common_args      = "-o ProxyJump=ec2-user@${module.project01_bastion_ec2.public_ip} -o IdentityFile=~/.ssh/project01-bastion-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
              ansible_ssh_common_args = <<-EOT
                -o ProxyCommand="ssh -i ~/.ssh/project01-bastion-key.pem -W %h:%p -q ec2-user@${module.project01_bastion_ec2.public_ip}"
                -o StrictHostKeyChecking=no
                -o UserKnownHostsFile=/dev/null
              EOT				
            }
          }
        }
      }
    }
  })

  # EC2 인스턴스가 만들어진 후에 인벤토리를 생성해야 하므로 depends_on 을 걸어줍니다.
  depends_on = [
    module.project01_bastion_ec2,
    module.project01_was01_ec2,
    module.project01_db_ec2,
  ]
}

############################################
# 7-2. Ansible - prod/dev 전용 inventory.yml 생성
############################################
resource "local_file" "ansible_inventory_prod" {

  filename = "${path.root}/../../../ansible/inventories/dev/inventory.yml"

  content = yamlencode({
    all = {
      # 기본값으로 ec2-user / bastion 키를 사용
      vars = {
        ansible_user                 = "adreamin"
        ansible_ssh_private_key_file = "~/.ssh/ansible-key.pem"
        # 호스트 키 체크 생략
        ansible_host_key_checking    = false
      }

      children = {
        bastion = {
          hosts = {
            bastion01 = {
              ansible_host                    = module.project01_bastion_ec2.public_ip
			  ansible_ssh_private_key_file = "~/.ssh/bastion-key.pem"
            }
          }
        }

        was = {
          hosts = {
            was01 = {
              ansible_host                    = module.project01_was01_ec2.private_ip
              ansible_ssh_common_args = <<-EOT
                -o ProxyCommand="ssh -i ~/.ssh/bastion-key.pem -W %h:%p -q adreamin@${module.project01_bastion_ec2.public_ip}"
                -o StrictHostKeyChecking=no
                -o UserKnownHostsFile=/dev/null
              EOT				
            }		
          }
        }

        db = {
          hosts = {
            db01 = {
              ansible_host                    = module.project01_db_ec2.private_ip
              ansible_ssh_common_args = <<-EOT
                -o ProxyCommand="ssh -i ~/.ssh/bastion-key.pem -W %h:%p -q adreamin@${module.project01_bastion_ec2.public_ip}"
                -o StrictHostKeyChecking=no
                -o UserKnownHostsFile=/dev/null
              EOT				
            }
          }
        }
      }
    }
  })

  # EC2 인스턴스가 만들어진 후에 인벤토리를 생성해야 하므로 depends_on 을 걸어줍니다.
  depends_on = [
    module.project01_bastion_ec2,
    module.project01_was01_ec2,
    module.project01_db_ec2,
  ]
}