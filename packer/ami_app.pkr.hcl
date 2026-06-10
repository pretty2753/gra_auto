# ============================================================
# project02 WAS AMI 빌드
#
# 굽는 것:
#   - Docker
#   - docker-compose-plugin
#
# 굽지 않는 것 (user_data에서 pull):
#   - 앱 이미지 (nginx, node-exporter, fastapi 등)
#   → 앱 업데이트 시 AMI 재빌드 불필요
# ============================================================

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  default = "ap-northeast-2"
}

variable "instance_type" {
  default = "t3.micro"
}

source "amazon-ebs" "was_image" {
  ami_name      = "project02-was-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.region

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  ssh_username = "ec2-user"

  tags = {
    Name    = "project02-was"
    Project = "project02"
    Base    = "amazonlinux2023"
  }
}

build {
  sources = ["source.amazon-ebs.was_image"]

  # Docker + docker-compose-plugin 설치
  provisioner "shell" {
    inline = [
      "sudo dnf install -y docker",
      "sudo systemctl enable --now docker",
      "sudo usermod -aG docker ec2-user",
      "sudo dnf install -y docker-compose-plugin",
      "echo 'Docker 설치 완료'"
    ]
  }

  # 완성된 AMI ID를 manifest.json에 저장
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
