
######################### Create Internet Gateway ###########################################
resource "aws_internet_gateway" "terraform-igw" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    tags = {
        Name = "terraform-igw"
    }
}
#############################################################################################


################################# Create Route table######################################### 
resource "aws_route_table" "terraform-public-rt" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //Route Table uses this IGW to reach internet
        gateway_id = "${aws_internet_gateway.terraform-igw.id}" 
    }
    
    tags = {
        Name = "terraform-public-RT"
    }
}

resource "aws_route_table_association" "terraform-rt-public-subnet-1"{
    subnet_id = "${aws_subnet.terraform-subnet-public-1a.id}"
    route_table_id = "${aws_route_table.terraform-public-rt.id}"
}

###############################################################################################

#######################################Create security group####################################
resource "aws_security_group" "ssh-allowed" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        // This means, all ip address are allowed to ssh ! 
        // Do not do it in the production. 
        // Put your office or home address in it!
        cidr_blocks = ["0.0.0.0/0"]
    }
    //If you do not add this rule, you can not reach the NGIX  
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "ssh-allowed"
    }
}

######################### Create load balancer######################################################
resource "aws_lb" "terraform-alb" {
  name               = "terraform-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ssh-allowed.id}"]
  subnets            = ["${aws_subnet.terraform-subnet-public-1a.id}","${aws_subnet.terraform-subnet-public-1b.id}"]

  enable_deletion_protection = false

#   access_logs {
#     bucket  = aws_s3_bucket.lb_logs.bucket
#     prefix  = "test-lb"
#     enabled = true
#   }

  tags = {
    Environment = "Terraform-Test"
  }
}
##################################################################################################



################################## Create listener#############################################
resource "aws_lb_listener" "terraform-alb-listener" {
   load_balancer_arn = aws_lb.terraform-alb.id
     port              = "80"
     protocol          = "HTTP"
     #ssl_policy        = "ELBSecurityPolicy-2016-08"
     #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"
   default_action {
     target_group_arn = aws_lb_target_group.terraform-tg.id
     type             = "forward"
   }
 }



############################ Create Launch Template############################################
resource "aws_launch_template" "Terraform_Launch_Template" {
  name = "Terraform_Launch_Template"
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
    }
  }
  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }
  cpu_options {
    core_count       = 4
    threads_per_core = 2
  }
  credit_specification {
    cpu_credits = "standard"
  }
  disable_api_termination = true
  ebs_optimized = true
  elastic_gpu_specifications {
    type = "test"
  }
  elastic_inference_accelerator {
    type = "eia1.medium"
  }
  iam_instance_profile {
    name = "ansible-role"
  }
  image_id = "${lookup(var.AMI, var.AWS_REGION)}"
  instance_initiated_shutdown_behavior = "terminate"
  instance_market_options {
    market_type = "spot"
  }
  instance_type = "t2.micro" 
  #kernel_id = "test"
  key_name = "terraKey"
  #license_specification {
  #  license_configuration_arn = "arn:aws:license-manager:eu-east-1:123456789012:license-configuration:lic-0123456789abcdef0123456789abcdef"
  #}
  #metadata_options {
  #  http_endpoint               = "enabled"
  #  http_tokens                 = "required"
  #  http_put_response_hop_limit = 1
  #  instance_metadata_tags      = "enabled"
  #}
  monitoring {
    enabled = true
  }
  network_interfaces {
    associate_public_ip_address = true
  }
  placement {
    availability_zone = "us-east-1a"
  }
  #ram_disk_id = "test"
  # vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]
  security_group_names = ["${aws_security_group.ssh-allowed.id}"]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "test"
    }
  }
#  user_data = <<EOF
#  #!/bin/sh
#  yum -y install httpd
#  systemctl enable httpd
#  systemctl start httpd.service
#  echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
  
#  EOF
}

################### Create a target group #############################################

resource "aws_lb_target_group" "terraform-tg" {
  name     = "terraform-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.terraform-vpc.id}"

  health_check {
    port     = 80
    protocol = "HTTP"
  }
}

#########################################################################################
# Create ASG to launch 2 EC's
# resource "aws_placement_group" "test" {
#   name     = "test"
#   strategy = "cluster"
# }
# # try replacing this with a target group
# resource "aws_autoscaling_group" "terraformASG" {
#   name                      = "terraformASG"
#   max_size                  = 3
#   min_size                  = 1
#   health_check_grace_period = 300
#   health_check_type         = "EC2"
#   desired_capacity          = 2
#   force_delete              = true
#   placement_group           = aws_placement_group.test.id
#   #launch_configuration      = aws_launch_configuration.foobar.name
#   launch_template           = aws_launch_template.Terraform_Launch_Template.id 
#   vpc_zone_identifier       = "${aws_subnet.terraform-subnet-private-1a.id}"
  

#   initial_lifecycle_hook {
#     name                 = "foobar"
#     default_result       = "CONTINUE"
#     heartbeat_timeout    = 2000
#     lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

#     notification_metadata = <<EOF
# {
#   "foo": "bar"
# }
# EOF

#     notification_target_arn = "arn:aws:sqs:us-east-1:444455556666:queue1*"
#     role_arn                = "arn:aws:iam::123456789012:role/S3Access"
#   }

#   # tag {
#   #   key                 = "foo"
#   #   value               = "bar"
#   #   propagate_at_launch = true
#   # }

#   timeouts {
#     delete = "15m"
#   }

#   # tag {
#   #   key                 = "lorem"
#   #   value               = "ipsum"
#   #   propagate_at_launch = false
#   # }
# }
resource "aws_launch_template" "foobar" {
  name_prefix   = "foobar"
  image_id = "${lookup(var.AMI, var.AWS_REGION)}"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "bar" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 2
  max_size           = 3
  min_size           = 1

  launch_template {
    id      = aws_launch_template.foobar.id
    version = "$Latest"
  }
}


#########################################################################################
#Create EC2's in Target Group using launch template

#########################################################################################


########### Register EC2s with the target group##########################################

##########################################################################################
# Create a listener that forwards requests to the previously created target group.

