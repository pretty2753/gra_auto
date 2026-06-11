# 12. ELASTIC CONTAINER REGISTRY (ECR)
############################################

# [1] WAS 애플리케이션용 ECR 리포지토리
# → GitHub Actions 빌드 후 생성된 Docker 이미지를 저장하는 공간입니다.
resource "aws_ecr_repository" "was_repo" {
  name                 = "project02-was-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "project02-was-repo"
  }
}

# [2] DB 인스턴스용 ECR 리포지토리
# → GitHub Actions 빌드 후 생성된 DB 커스텀 Docker 이미지를 저장하는 공간입니다.
resource "aws_ecr_repository" "db_repo" {
  name                 = "project02-db-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "project02-db-repo"
  }
}
