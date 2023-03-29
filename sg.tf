module "bastion_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "makena-bastion"
  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = var.sg_all
  ingress_rules       = ["http-80-tcp", "ssh-tcp"]

  egress_cidr_blocks = var.sg_all
  egress_rules       = ["all-all"]

  tags = var.tags
}

/*
resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "security group for bastion"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.sg_all
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.sg_all
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.sg_all
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}bastion"
    }
  )
}
*/

module "web_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "makena-web"
  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = var.sg_all
  ingress_rules       = ["http-80-tcp", "nfs-tcp"]

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

/*
resource "aws_security_group" "web" {
  name        = "web"
  description = "security group for web"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [module.bastion_sg.security_group_id]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.sg_all
  }
  
  ingress {
    description     = "Allow EFS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    cidr_blocks = var.sg_all
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.sg_all
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}web"
    }
  )
}
*/

module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "makena-alb"
  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = var.sg_all
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_cidr_blocks = var.sg_all
  egress_rules       = ["all-all"]

  tags = var.tags
}

/*
resource "aws_security_group" "alb" {
  name        = "alb"
  description = "security group for alb"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.sg_all
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.sg_all
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.sg_all
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}alb"
    }
  )
}
*/

module "rds_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "makena-rds"
  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = var.sg_all
  ingress_rules       = ["mysql-tcp"]

  egress_cidr_blocks = var.sg_all
  egress_rules       = ["all-all"]

  tags = var.tags
}

/*
resource "aws_security_group" "rds" {
  name        = "dbsg"
  description = "security group for rds"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.sg_all
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.sg_all
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}db"
    }
  )
}
*/

module "efs_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "makena-efs"
  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = var.sg_all
  ingress_rules       = ["nfs-tcp"]

  egress_cidr_blocks = var.sg_all
  egress_rules       = ["all-all"]

  tags = var.tags
}

/*
resource "aws_security_group" "efs" {
  name        = "efs"
  description = "security group for efs"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow EFS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    cidr_blocks = var.sg_all
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.sg_all
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}efs"
    }
  )
}
*/