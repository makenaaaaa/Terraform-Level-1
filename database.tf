resource "aws_db_subnet_group" "rds_subnet" {
  name        = "${var.prefix}subnetgroup"
  description = "makena subnet group"
  subnet_ids  = [aws_subnet.private[2].id, aws_subnet.private[3].id]

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}subnetgroup"
    }
  )
}

resource "aws_db_instance" "db_ins" {
  allocated_storage      = 20
  identifier             = "${var.prefix}rds"
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  username               = var.db_user
  password               = var.db_pw
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}rds"
    }
  )
}