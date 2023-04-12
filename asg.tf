// user data - user data in launch template should be base64 encoded
data "template_file" "userdata" {
  template = <<-EOF
                #! /bin/bash
                sudo yum update -y
                sudo yum install -y httpd.x86_64
                sudo yum install -y mysql
                sudo yum install -y amazon-linux-extras
                sudo amazon-linux-extras install -y php8.0
                echo "Your IP address is: $(curl http://169.254.169.254/latest/meta-data/local-ipv4)" > /var/www/html/index.php
                sudo systemctl start httpd.service
                sudo systemctl enable httpd.service
                wget -O /tmp/amazon-cloudwatch-agent.rpm 'https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm'
                sudo rpm -U /tmp/amazon-cloudwatch-agent.rpm
                echo '{
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
                }'> /opt/aws/amazon-cloudwatch-agent/bin/config.json
                sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
                sudo systemctl restart amazon-cloudwatch-agent
                sudo yum install -y amazon-efs-utils
                pip3 install botocore
                sudo mkdir -p /usr/bin/efs
                sleep 60
                sudo mount -t efs -o tls ${module.efs.id}:/ /usr/bin/efs > /tmp/user-data.log 2>&1
                sudo touch /usr/bin/efs/test-file.txt
                EOF
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "makena-asg"

  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  target_group_arns   = module.alb.target_group_arns

  // launch template
  launch_template_name        = "makena-template"
  launch_template_description = "template for asg"
  update_default_version      = true

  image_id                             = var.instance["ami"]
  instance_type                        = var.instance["instance_type"]
  key_name                             = var.instance["key_name"]
  enable_monitoring                    = true
  instance_initiated_shutdown_behavior = "terminate"
  security_groups                      = [module.web_sg.security_group_id]
  user_data                            = base64encode(data.template_file.userdata.rendered)

  // IAM role & instance profile
  iam_instance_profile_arn = "arn:aws:iam::281630892023:instance-profile/ec2-acces-s3"

  placement = {
    availability_zone = "us-east-1b"
  }

  tags = var.tags
}