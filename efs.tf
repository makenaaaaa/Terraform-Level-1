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
  subnet_id      = aws_subnet.private[0].id
  security_groups = [aws_security_group.web.id]
}

resource "aws_efs_mount_target" "asg" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = aws_subnet.private[1].id
  security_groups = [aws_security_group.web.id]
}