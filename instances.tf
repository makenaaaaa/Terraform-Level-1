resource "aws_instance" "bastion" {
  ami                         = var.instance["ami"]
  instance_type               = var.instance["instance_type"]
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.instance["key_name"]
  associate_public_ip_address = "true"

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}bastion"
    }
  )
}

resource "aws_instance" "web" {
  ami                    = var.instance["ami"]
  instance_type          = var.instance["instance_type"]
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.instance["key_name"]
  iam_instance_profile   = "ec2-acces-s3"

  user_data = <<-EOF
                #! /bin/bash
                sudo yum update -y
                sudo yum install -y httpd.x86_64
                sudo yum install -y mysql
                sudo yum install -y amazon-linux-extras
                sudo amazon-linux-extras install -y php8.0
                #sudo yum install -y php80
                echo "Your IP address is: <?php echo \$_SERVER['REMOTE_ADDR']; ?>" > /var/www/html/index.php
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
                }' > /opt/aws/amazon-cloudwatch-agent/bin/config.json
                sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
                sudo systemctl restart amazon-cloudwatch-agent
                sudo yum install -y amazon-efs-utils
                pip3 install botocore
                sudo mkdir -p /usr/bin/efs
                sudo mount -t efs -o tls ${aws_efs_file_system.efs.id}:/ /usr/bin/efs
                sudo touch /usr/bin/efs/test-file.txt
                EOF
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}web"
    }
  )
  
  depends_on = [
    aws_route_table.private
  ]
}