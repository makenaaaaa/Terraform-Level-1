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

/*
resource "aws_sns_topic" "alarm_sns" {
  name = "${var.prefix}sns"
  
  tags = var.tags
}

resource "aws_sns_topic_subscription" "sub_email" {
  topic_arn = aws_sns_topic.alarm_sns.arn
  protocol  = "email"
  endpoint  = "makena.lu@ecloudvalley.com"
}
*/

module "metric_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  alarm_name          = "makena-alarm"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 100
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

/*
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name                = "${var.prefix}cpu-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 100
  alarm_description         = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alarm_sns.arn]
  dimensions = {
    InstanceId = module.web.id
  }
  
  tags = var.tags
}
*/