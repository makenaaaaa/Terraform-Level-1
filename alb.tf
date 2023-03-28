resource "aws_lb_target_group" "tg" {
  name     = "${var.prefix}tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled = true
    path    = "/index.php"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}tg"
    }
  )
}

resource "aws_lb" "alb" {
  name               = "makena-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id]

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}alb"
    }
  )
}

resource "aws_lb_listener" "alb_tg_listen" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
  
  tags = var.tags
}

resource "aws_lb_target_group_attachment" "instance" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}