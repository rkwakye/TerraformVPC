
# Create Internet Gateway
resource "aws_internet_gateway" "terraform-igw" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    tags = {
        Name = "terraform-igw"
    }
}

# Create Route table 
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

# Create security group
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

# Create load balancer
resource "aws_lb" "terraform-alb" {
  name               = "terraform-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ssh-allowed.id}"]
#   security_groups    = [aws_security_group.lb_sg.id]
#   subnets            = [for subnet in aws_subnet.public : subnet.id]
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

# Create target group
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

# Create listener
# resource "aws_lb_listener" "terraform-alb-listener" {
#   load_balancer_arn = aws_lb.terraform-alb.id

#   default_action {
#     target_group_arn = aws_lb_target_group.terraform-tg.id
#     type             = "forward"
#   }
# }
# resource "aws_lb_listener" "terraform-alb-listener" {
#   load_balancer_arn = aws_lb.terraform-alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
# #   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.terraform-tg.arn
#   }
# }


# Create autoscaling group for LB
#Autoscaling Attachment
# resource "aws_autoscaling_attachment" "svc_asg_external2" {
#   alb_target_group_arn   = "${aws_alb_target_group.alb_target_group.arn}"
#   alb_target_group_arn   = "${aws_alb_target_group.terraform-tg.arn}"
#   autoscaling_group_name = "${aws_autoscaling_group.svc_asg.id}"
# }

# Alternatively could use an Instance Attachment for the ALB
#Instance Attachment
# resource "aws_alb_target_group_attachment" "svc_physical_external" {
#   target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
#   target_id        = "${aws_instance.svc.id}"  
#   port             = 8080
# }
# # Network Load balancer for 2 IP's 
# resource "aws_lb" "example" {
#   name               = "example"
#   load_balancer_type = "network"

#   subnet_mapping {
#     subnet_id            = aws_subnet.example1.id
#     private_ipv4_address = "10.0.1.15"
#   }

#   subnet_mapping {
#     subnet_id            = aws_subnet.example2.id
#     private_ipv4_address = "10.0.2.15"
#   }
# }