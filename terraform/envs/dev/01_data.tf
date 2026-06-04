############################################
# 1. DATA SOURCE (가용 AZ 조회)
############################################
# AWS가 제공하는 사용 가능한 AZ 목록을 가져옴
# → subnet을 여러 AZ에 분산 배치하기 위해 사용
data "aws_availability_zones" "available" {
  state = "available"
}
