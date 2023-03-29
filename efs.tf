module "efs" {
  source = "terraform-aws-modules/efs/aws"

  # File system
  name      = "makena-efs"
  encrypted = true

  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  attach_policy = false

  # Mount targets / security group
  mount_targets = {
    "us-east-1a" = {
      subnet_id = module.vpc.private_subnets[0]
    }
    "us-east-1b" = {
      subnet_id = module.vpc.private_subnets[1]
    }
  }
  security_group_name        = "makena-efs"
  security_group_description = "EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = var.sg_all
    }
  }

  enable_backup_policy = false

  # Replication configuration
  create_replication_configuration = false

  tags = var.tags
}

/*
resource "aws_efs_file_system" "efs" {
  encrypted = true
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}efs"
    }
  )
}

resource "aws_efs_mount_target" "web" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = module.vpc.private_subnets[0]
  security_groups = [module.efs_sg.security_group_id]
}

resource "aws_efs_mount_target" "asg" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = module.vpc.private_subnets[1]
  security_groups = [module.efs_sg.security_group_id]
}
*/