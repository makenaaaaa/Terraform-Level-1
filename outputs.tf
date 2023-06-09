// Account ID
data "aws_caller_identity" "current" {}
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

// Name of current AWS region
data "aws_region" "current" {}
output "region" {
  value = data.aws_region.current.name
}