data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "nat" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  # NAT 인스턴스의 핵심: 자신을 목적지로 하지 않는 트래픽도 수신/전송할 수 있도록 허용
  source_dest_check = false

  user_data = <<-EOF
              #!/bin/bash
              # IP 포워딩 활성화
              sysctl -w net.ipv4.ip_forward=1
              echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/custom-ip-forwarding.conf
              
              # iptables 설치 및 구성
              yum install -y iptables-services
              systemctl enable iptables
              systemctl start iptables
              
              # 기본 네트워크 인터페이스 찾기 (예: ens5)
              INTERFACE=$(ip route | grep default | awk '{print $5}')
              
              # 마스커레이딩(NAT) 룰 추가
              iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
              iptables-save > /etc/sysconfig/iptables
              
              # Tailscale 설치 및 Subnet Router 설정
              yum install -y yum-utils
              yum-config-manager --add-repo https://pkgs.tailscale.com/stable/amazon-linux/2/tailscale.repo
              yum install -y tailscale
              systemctl enable --now tailscaled
              
              # Tailscale 인증 및 라우팅 광고 시작
              tailscale up --authkey="${var.tailscale_auth_key}" --advertise-routes=10.0.0.0/16
              EOF

  tags = {
    Name = var.name
    Role = "NAT-Instance"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
  tags = {
    Name = "${var.name}-eip"
  }
}

resource "aws_eip_association" "nat_eip_assoc" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat_eip.id
}
