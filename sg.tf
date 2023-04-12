// Bastion instance
module "bastion_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "makena-bastion"
  vpc_id = module.vpc.vpc_id

  // Allow inbound from HTTP and SSH
  ingress_cidr_blocks = var.sg_all
  ingress_rules       = ["http-80-tcp", "ssh-tcp"]

  egress_cidr_blocks = var.sg_all
  egress_rules       = ["all-all"]

  tags = var.tags
}

// Web instance
module "web_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "makena-web"
  vpc_id = module.vpc.vpc_id

  // Allow inbound from HTTP and NFS
  ingress_cidr_blocks = var.sg_all
  ingress_rules       = ["http-80-tcp", "nfs-tcp"]

  // Allow SSH inbound from bastion instance
  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "ssh-tcp"
      source_security_group_id = module.bastion_sg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_cidr_blocks = var.sg_all
  egress_rules       = ["all-all"]

  tags = var.tags
}

// ALB
module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "makena-alb"
  vpc_id = module.vpc.vpc_id

  // Allow inbound from HTTP and HTTPS
  ingress_cidr_blocks = var.sg_all
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_cidr_blocks = var.sg_all
  egress_rules       = ["all-all"]

  tags = var.tags
}

// RDS
module "rds_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "makena-rds"
  vpc_id = module.vpc.vpc_id

  // Allow inbound for MYSQL
  ingress_cidr_blocks = var.sg_all
  ingress_rules       = ["mysql-tcp"]

  egress_cidr_blocks = var.sg_all
  egress_rules       = ["all-all"]

  tags = var.tags
}

// EFS
module "efs_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "makena-efs"
  vpc_id = module.vpc.vpc_id

  // Allow inbound from NFS
  ingress_cidr_blocks = var.sg_all
  ingress_rules       = ["nfs-tcp"]

  egress_cidr_blocks = var.sg_all
  egress_rules       = ["all-all"]

  tags = var.tags
}