variable "region" {
    default = "us-east-1"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "subnet_cidr" {
    default = "10.0.1.1/24"
}

variable "instance_type" {
    default = "t2.micro" 
}

variable "cidr_block_all_traffic" {
    default = "0.0.0.0/0"
}

variable "ec2_key_name" {
    default = "IAC_practice"  
}

variable "ports" {
    type = "list"
    default = ["22", "8080", 0]
}
