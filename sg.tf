resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "security group for bastion"
  vpc_id      = aws_vpc.main.id

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

resource "aws_security_group" "web" {
  name        = "web"
  description = "security group for web"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
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

resource "aws_security_group" "alb" {
  name        = "alb"
  description = "security group for alb"
  vpc_id      = aws_vpc.main.id

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

resource "aws_security_group" "rds" {
  name        = "dbsg"
  description = "security group for rds"
  vpc_id      = aws_vpc.main.id

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

resource "aws_security_group" "efs" {
  name        = "efs"
  description = "security group for efs"
  vpc_id      = aws_vpc.main.id

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
