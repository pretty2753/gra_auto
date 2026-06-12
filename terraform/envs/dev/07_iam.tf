############################################
# IAM Role (권한 관리)
############################################

# [1] EC2 전용 IAM 롤 정의 (Prometheus Discovery 용도)
# → 원래 Bastion 서버가 쓰던 권한이지만, 향후 다른 서버(NAT 인스턴스 등)에서 
#    내부 EC2들의 IP 리스트를 자동으로 읽어오기 위해 공용 Discovery Role로 이름을 변경했습니다.
resource "aws_iam_role" "ec2_discovery_role" {
  name = "Project02-EC2-Discovery-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# [2] EC2 읽기 권한 부여
# → AWS 내의 EC2 정보(IP, 상태 등)를 읽어올 수 있는 표준 권한을 부여합니다.
resource "aws_iam_role_policy_attachment" "ec2_read_only" {
  role       = aws_iam_role.ec2_discovery_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# [2-1] ECR 읽기 권한 부여
# → EC2 인스턴스가 ECR에서 컨테이너 이미지를 Pull 할 수 있는 권한을 부여합니다.
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2_discovery_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# [3] 인스턴스 프로파일 (Instance Profile)
# → 이 권한을 EC2 인스턴스에 입혀주기 위한 프로파일(껍데기)을 생성합니다.
resource "aws_iam_instance_profile" "ec2_discovery_profile" {
  name = "Project02-EC2-Discovery-Profile"
  role = aws_iam_role.ec2_discovery_role.name
}