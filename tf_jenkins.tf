# AWS Provider information
provider "aws" {
    region = "${var.region}"
    shared_credentials_file = "/usr_share/.aws/credentials"
}
# New VPC to host the subnets for AppServer
resource "aws_vpc" "AppServer_vpc" {
    cidr_block = "${var.vpc_cidr}"
    instance_tenancy = "default"
    enable_dns_hostnames = "true"
    tags = {
        Name = "AppServer_vpc"
    }
}

# Internet Gateway to enable Public Access
resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.AppServer_vpc.id}"
    tags = {
        Name = "IG_for_VPC"
    }
  
}

# Creating Subnet for AppServer EC2 instances
resource "aws_subnet" "AppServer_subnet" {
    vpc_id = "${aws_vpc.AppServer_vpc.id}"
    cidr_block = "${var.subnet_cidr}"
    tags = {
        Name = "AppServer_subnet"
    }
}

# Route Table for AppServer VPC

resource "aws_route_table" "AppServer_Subnet_RT" {
    vpc_id = "${aws_vpc.AppServer_vpc.id}"
    route {
        cidr_block = "${var.cidr_block_all_traffic}"
        gateway_id = "${aws_internet_gateway.default.id}"
    } 
    tags = {
        Name = "AppServer_Subnet_RT"
    }
}

# Route Table Association

resource "aws_route_table_association" "AppServer_Subnet_RT_Assoc" {
    subnet_id = "${aws_subnet.AppServer_subnet.id}"
    route_table_id = "${aws_route_table.AppServer_Subnet_RT.id}"
}

# Security Group for Tomcat Server

resource "aws_security_group" "AppServer-SG" {
    name = "AppServer-SG"
    description = "Security Group for Tomcat App Server"
    vpc_id = "${aws_vpc.AppServer_vpc.id}"

    ingress {
        from_port = "${element(var.ports, 1)}"
        to_port = "${element(var.ports, 1)}"
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block_all_traffic}"]
    }

    ingress {
        from_port = "${element(var.ports, 0)}"
        to_port = "${element(var.ports, 0)}"
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block_all_traffic}"]
    }

    egress {
        from_port = "${element(var.ports, 2)}"
        to_port = "${element(var.ports, 2)}"
        protocol = "-1"
        cidr_blocks = ["${var.cidr_block_all_traffic}"]
    }
    tags = {
        Name = "AppServer-SG"
        description = "Security Group for Tomcat AppServer"
    }
}

# Creating EC2 Instance to run Tomcat Server

resource "aws_instance" "Tomcat_AppServer" {
    ami = "ami-07d0cf3af28718ef8"   
    instance_type = "${var.instance_type}"
    subnet_id = "${aws_subnet.AppServer_subnet.id}"
    vpc_security_group_ids = ["${aws_security_group.AppServer-SG.id}"]
    associate_public_ip_address = "true"
    key_name = "${var.ec2_key_name}"
    tags = {
        Name = "Tomcat_AppServer"
        Env = "DEV"
    }
}
