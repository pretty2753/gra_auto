terraform {
  backend "s3" {
    bucket         = "project02-tfstate-bucket"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "project02-terraform-lock"
	encrypt = true # tstate 에는 민감한 정보가 들어있어 암호화
  }
}