variable "AWS_REGION" {
  default = "us-east-1"
}

variable "AMI" {
    type = map
    
    default = {
        us-east-1 = "ami-077f4dcd20ed5ed5d"
        # us-east-1 = "ami-0c2a1acae6667e438"
    }
}

# Create EC2
resource "aws_instance" "terraEC2" {
    ami = "${lookup(var.AMI, var.AWS_REGION)}"
    instance_type = "t2.micro"
    # count = 2 
    # VPC
    subnet_id = "${aws_subnet.terraform-subnet-public-1a.id}"
    # Security Group
    vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]
    # the Public SSH key
    # key_name = "${aws_key_pair.terraform-key-pair.id}"
    key_name = "terraKey"
    # nginx installation
    # provisioner "file" {
    #     source = "nginx.sh"
    #     destination = "/tmp/nginx.sh"
    # }
    # provisioner "remote-exec" {
    #     inline = [
    #          "chmod +x /tmp/nginx.sh",
    #          "sudo /tmp/nginx.sh"
    #     ]
    # }
    # connection {
    #     user = "${var.EC2_USER}"
    #     private_key = "${file("${var.PRIVATE_KEY_PATH}")}"
    # }
# }
// Sends your public key to the instance
# resource "aws_key_pair" "terraform-key-pair" {
#     key_name = "terraform-key-pair"
#     public_key = "${file(var.PUBLIC_KEY_PATH)}"
 tags = {
     name = "terraEC2"
 }
}