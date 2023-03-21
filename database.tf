data "aws_vpc" "main" {
  id = aws_vpc.main.id
}

data "aws_subnet" "private3" {
  id = aws_subnet.private3.id
}

data "aws_subnet" "private4" {
  id = aws_subnet.private4.id
}

resource "aws_security_group" "rds" {
  name        = "dbsg"
  description = "security group for rds"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "makena-db"
  }
}

resource "aws_db_subnet_group" "rds_subnet" {
  name        = "makena-subnetgroup"
  description = "makena subnet group"
  subnet_ids  = [data.aws_subnet.private3.id, data.aws_subnet.private4.id]

  tags = {
    Name = "makena-subnetgroup"
  }
}

resource "aws_db_instance" "db_ins" {
  allocated_storage      = 20
  identifier             = "makena-rds"
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  username               = "makena"
  password               = "password"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
}