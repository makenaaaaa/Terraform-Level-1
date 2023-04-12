// Create SNS topic and subscribe using email
module "sns_topic" {
  source = "terraform-aws-modules/sns/aws"

  name = "makena-sns"

  tags = var.tags

  subscriptions = {
    email = {
      protocol = "email"
      endpoint = "makena.lu@ecloudvalley.com"
    }
  }
}

// Create alarm - if CPU utilization exceeds 90%, the SNS topic is triggered
module "metric_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  alarm_name          = "makena-alarm"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 90
  period              = 60

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  statistic   = "Average"

  alarm_actions = [module.sns_topic.topic_arn]

  dimensions = {
    InstanceId = module.web.id
  }

  tags = var.tags
}