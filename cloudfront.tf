resource "aws_cloudfront_distribution" "alb_cloudfront" {
  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"
    forwarded_values {
      query_string = false
      headers      = ["*"]

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}cloudfront"
    }
  )
}

resource "aws_sns_topic" "alarm_sns" {
  name = "${var.prefix}sns"
  
  tags = var.tags
}

resource "aws_sns_topic_subscription" "sub_email" {
  topic_arn = aws_sns_topic.alarm_sns.arn
  protocol  = "email"
  endpoint  = "makena.lu@ecloudvalley.com"
}

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
    InstanceId = aws_instance.web.id
  }
  
  tags = var.tags
}