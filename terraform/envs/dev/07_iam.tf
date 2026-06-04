## bastion에 IAMROLE 권한 부여

# 1단계: 바스천 서버 전용 IAM 롤 정의 (EC2가 이 역할을 가질 수 있게 허용)
resource "aws_iam_role" "bastion_discovery_role" {
  name = "Bastion-Prometheus-Discovery-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# 2단계 : EC2 정보를 읽어올 수 있는 권한 부여 (S3 대신 EC2ReadOnly 선택)
resource "aws_iam_role_policy_attachment" "ec2_read_only" {
  role       = aws_iam_role.bastion_discovery_role.name
  # AWS에서 제공하는 표준 권한입니다.
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# 3단계 : 이 신분증을 바스천 EC2에 입히기 위한 케이스(Profile) 만들기
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "Bastion-Discovery-Instance-Profile"
  role = aws_iam_role.bastion_discovery_role.name
}