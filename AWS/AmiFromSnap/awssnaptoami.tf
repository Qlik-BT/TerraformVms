## VARIABLE BLOCK ##

variable "snapshot_id" {
  description = "The id of your snapshot"
  default     = ""
}

variable "ami_name" {
  description = "The desired name of your AMI"
  default     = ""
}

variable "region" {
  description = "The region your snapshot is in"
  default     = ""
}

## PROVIDER BLOCK ##

provider "aws" {
  region  = var.region
  profile = ""
}

## RESOURCES BLOCK ##

 resource "aws_ami" "snap_ami" {

  name = var.ami_name
  ena_support = true
  virtualization_type = "hvm"
  root_device_name = "/dev/sda1"
  ebs_block_device {
    device_name = "/dev/sda1"
    snapshot_id = var.snapshot_id
    volume_type = "gp2"
  }

}