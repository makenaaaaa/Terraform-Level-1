/*
resource "local_file" "cwagent_config" {
  content = <<-EOF
    {
    	"agent": {
    		"metrics_collection_interval": 60,
    		"run_as_user": "root"
    	},
    	"logs": {
    		"logs_collected": {
    			"files": {
    				"collect_list": [
    					{
    						"file_path": "/var/log/httpd/access_log",
    						"log_group_name": "makena-accesslog",
    						"log_stream_name": "makena-webec2",
    						"retention_in_days": 14
    					}
    				]
    			}
    		}
    	},
    	"metrics": {
    		"aggregation_dimensions": [
    			[
    				"InstanceId"
    			]
    		],
    		"append_dimensions": {
    			"AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
    			"ImageId": "$${aws:ImageId}",
    			"InstanceId": "$${aws:InstanceId}",
    			"InstanceType": "$${aws:InstanceType}"
    		},
    		"metrics_collected": {
    			"disk": {
    				"measurement": [
    					"used_percent"
    				],
    				"metrics_collection_interval": 60,
    				"resources": [
    					"*"
    				]
    			},
    			"mem": {
    				"measurement": [
    					"mem_used_percent"
    				],
    				"metrics_collection_interval": 60
    			}
    		}
    	}
    }
  EOF

  filename = "config.json"
}
*/

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

  tags = {
    Name = "makena-cloudfront"
  }
}

resource "aws_sns_topic" "alarm_sns" {
  name = "makena-sns"
}

resource "aws_sns_topic_subscription" "sub_email" {
  topic_arn = aws_sns_topic.alarm_sns.arn
  protocol  = "email"
  endpoint  = "makena.lu@ecloudvalley.com"
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name                = "makena-cpu-alarm"
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
}

/*
resource "null_resource" "copy_pem" {
  provisioner "local-exec" {
    command = "scp -i makena-test.pem makena-test.pem config.json ec2-user@${aws_instance.bastion.public_ip}:~"
  }
  
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("makena-test.pem")
      host        = aws_instance.bastion.public_ip
    }
    
    inline = [
      "chmod 400 ~/makena-test.pem"
    ]
  }
}

resource "null_resource" "run_config" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("makena-test.pem")
    host        = aws_instance.bastion.public_ip
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("makena-test.pem")
      host        = aws_instance.web.private_ip
    }
    source      = "config.json"
    destination = "/opt/aws/amazon-cloudwatch-agent/bin/config.json"
  }
  
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("makena-test.pem")
      host        = aws_instance.web.private_ip
    }

    inline = [
      "#!/bin/bash",
      "mkdir -p /usr/share/collectd",
      "touch /usr/share/collectd/types.db",
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s",
      "sudo systemctl restart amazon-cloudwatch-agent"
    ]
  }
}
*/