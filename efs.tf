module "efs" {
  source = "terraform-aws-modules/efs/aws"

  // file system
  name      = "makena-efs"
  encrypted = true

  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  attach_policy = false

  // mount targets
  mount_targets = {
    "us-east-1a" = {
      subnet_id = module.vpc.private_subnets[0]
    }
    "us-east-1b" = {
      subnet_id = module.vpc.private_subnets[1]
    }
  }

  # create security group
  security_group_name        = "makena-efs"
  security_group_description = "EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      // relying on the defaults provided for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = var.sg_all
    }
  }

  enable_backup_policy = false

  create_replication_configuration = false

  tags = var.tags
}