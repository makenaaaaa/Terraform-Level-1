module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "makena-alb"

  load_balancer_type = "application"
  internal           = false

  vpc_id          = module.vpc.vpc_id
  subnets         = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_groups = [module.alb_sg.security_group_id]

  target_groups = [
    {
      name             = "makena-tg"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = {
        web = {
          target_id = module.web.id
          port      = 80
        }
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
  tags = var.tags
}

/*
resource "aws_lb_target_group" "tg" {
  name     = "${var.prefix}tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

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
  security_groups    = [module.alb_sg.security_group_id]
  subnets            = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]

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
  target_id        = module.web.id
  port             = 80
}
*/