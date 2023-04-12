module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "makena-rds"

  engine              = "mysql"
  engine_version      = "8.0.28"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  skip_final_snapshot = true

  create_db_option_group    = false
  create_db_parameter_group = false

  create_random_password = false // Will ignore password argument if not explicitly set to false
  username               = var.db_user
  password               = var.db_pw

  vpc_security_group_ids = [module.rds_sg.security_group_id]

  // Subnet group
  create_db_subnet_group = true
  subnet_ids             = [module.vpc.private_subnets[2], module.vpc.private_subnets[3]]

  tags = var.tags
}