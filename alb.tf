module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "makena-alb"

  load_balancer_type = "application"
  internal           = false

  // Internet facing ALB - chosen subnets must be public subnets to receive traffic from ALB
  vpc_id          = module.vpc.vpc_id
  subnets         = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_groups = [module.alb_sg.security_group_id]

  // Create target group and add web instance
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

  // Listen to 80 port
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
  tags = var.tags
}