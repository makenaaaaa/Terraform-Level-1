data "aws_vpc" "main_vpc" {
  id = aws_vpc.main.id
}

data "aws_subnet" "public1" {
  id = aws_subnet.public1.id
}

data "aws_subnet" "public2" {
  id = aws_subnet.public2.id
}

data "aws_subnet" "private1" {
  id = aws_subnet.private1.id
}

data "aws_subnet" "private2" {
  id = aws_subnet.private2.id
}

data "aws_route_table" "private_rt" {
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "security group for bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "makena-bastion"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "security group for web"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    //cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "makena-web"
  }
}

resource "aws_security_group" "alb" {
  name        = "alb"
  description = "security group for alb"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name = "makena-alb"
  }
}

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

resource "aws_instance" "bastion" {
  ami                         = "ami-005f9685cb30f234b"
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.public1.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = "makena-test"
  associate_public_ip_address = "true"

  tags = {
    Name = "makena-bastion"
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-005f9685cb30f234b"
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = "makena-test"
  iam_instance_profile   = "ec2-acces-s3"

  user_data = <<-EOF
                #! /bin/bash
                sudo yum update -y
                sudo yum install -y httpd.x86_64
                sudo yum install -y mysql
                sudo amazon_linux-extras install php8.0
                echo "Your IP address is: <?php echo \$_SERVER['REMOTE_ADDR']; ?>" > /var/www/html/index.php
                sudo systemctl start httpd.service
                sudo systemctl enable httpd.service
                wget -O /tmp/amazon-cloudwatch-agent.rpm 'https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm'
                sudo rpm -U /tmp/amazon-cloudwatch-agent.rpm
                echo "{"agent": {"metrics_collection_interval": 60,"run_as_user": "root"},"logs": {"logs_collected": {"files": {"collect_list": [{"file_path": "/var/log/httpd/access_log","log_group_name": "makena-accesslog","log_stream_name": "makena-webec2"}]}}},"metrics": {"append_dimensions": {"AutoScalingGroupName": "$${aws:AutoScalingGroupName}","ImageId": "$${aws:ImageId}","InstanceId": "$${aws:InstanceId}","InstanceType": "$${aws:InstanceType}"},"metrics_collected": {"disk": {"measurement": ["used_percent"],"metrics_collection_interval": 60,"resources": ["*"]},"mem": {"measurement": ["mem_used_percent"],"metrics_collection_interval": 60}}}}" > /opt/aws/amazon-cloudwatch-agent/bin/config.json
                sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
                sudo systemctl restart amazon-cloudwatch-agent
                EOF
  
  tags = {
    Name = "makena-web"
  }
  
  depends_on = [
    data.aws_route_table.private_rt
  ]
}

resource "aws_ami_from_instance" "web_ami" {
  name               = "makena-ami"
  source_instance_id = aws_instance.web.id

  tags = {
    Name = "makena-ami"
  }
}

resource "aws_launch_template" "asg_template" {
  name        = "makena-template"
  description = "template for asg"

  image_id = aws_ami_from_instance.web_ami.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t2.micro"

  key_name = "makena-test"
  
  iam_instance_profile {
    name = "ec2-acces-s3"
  }

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  update_default_version = true

  tags = {
    Name = "makena-template"
  }
}

resource "aws_autoscaling_group" "myasg" {
  name                = "makena-asg"
  vpc_zone_identifier = [data.aws_subnet.private1.id, data.aws_subnet.private2.id]
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.asg_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "makena-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "makena-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main_vpc.id

  health_check {
    enabled = true
    path    = "/index.php"
  }
}

resource "aws_lb" "alb" {
  name               = "makena-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [data.aws_subnet.public1.id, data.aws_subnet.public2.id]

  tags = {
    Name = "makena-alb"
  }
}

resource "aws_lb_listener" "alb_tg_listen" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "instance" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

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