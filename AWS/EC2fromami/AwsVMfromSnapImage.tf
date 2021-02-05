## VARIABLE BLOCK ##

variable "ami_id" {
  description = "The id of your ami"
  default     = "ami-01c4a1f80619834c4"
}

variable "vpc_id" {
  description = "The ID of your desired VPC"
  default     = "vpc-7be7af1f"
}

variable "vm_number" {
  description = "The amount of VMs you need to create from a snapshot"
  default     = 1
}

variable "subnet_name" {
  description = "The name of your Subnet ID"
  default     = "subnet-fccfd09b"
}

variable "owner" {
  description = "Your email address"
  default     = "ohl@qlik.com"
}

variable "vm_key" {
  description = "The Key name for your ec2"
  default     = "OHLWINKEY"
}

variable "vm_size" {
  description = "The instance type you want your EC2 instance to use"
  default     = "t2.micro"
}

variable "vm_name" {
  description = "The name of your VM"
  default     = "test-vm"
}

variable "associate_public_ip_address" {
  description = "Wether to use a Public IP"
  default     = false
}

variable "region" {
  description = "The region your snapshot is in"
  default     = "eu-west-1"
}

## LOCALS BLOCK ##

locals {
  sg_name = "${var.vm_name}-sg"
}

## PROVIDER BLOCK ##

provider "aws" {
  region  = var.region
  profile = "098204959161_AdministratorAccess"
}

## RESOURCES BLOCK ##

resource "aws_security_group" "public_sg" {
  count       = var.associate_public_ip_address ? 1 : 0
  name        = "security_group"
  description = "public security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["14.98.59.168/29", "182.74.33.8/29", "188.65.156.32/28", "206.196.17.32/27", "194.90.96.176/29", "213.57.84.160/29"]
  }
  ingress {
    description = "rdp"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["14.98.59.168/29", "182.74.33.8/29", "188.65.156.32/28", "206.196.17.32/27", "194.90.96.176/29", "213.57.84.160/29"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "public_sg"
    Owner = var.owner
  }
}

resource "aws_security_group" "private_sg" {
  count       = var.associate_public_ip_address ? 0 : 1
  name        = "security_group"
  description = "Private security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "All Trafic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.0.0/16", "172.16.0.0/12", "10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "private_sg"
    Owner = var.owner
  }
}

data "aws_security_group" "security_group" {
  name       = "security_group"
  depends_on = [aws_security_group.private_sg, aws_security_group.public_sg]

}


module "ec2_cluster" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 2.0"
  associate_public_ip_address = var.associate_public_ip_address

  name           = var.vm_name
  instance_count = var.vm_number

  ami                    = var.ami_id
  instance_type          = var.vm_size
  key_name               = var.vm_key
  monitoring             = true
  vpc_security_group_ids = [data.aws_security_group.security_group.id]
  subnet_id              = var.subnet_name

  tags = {
    Owner  = var.owner
    "24x7" = ""
  }
}

