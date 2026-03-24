variable "aws_region" {
  default = "us-east-1"
}

variable "secondary_region" {
  default = "us-west-2"
}

variable "environments" {
  default = ["prod", "staging", "dev"]
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_cidrs" {
  default = {
    prod    = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    dev     = "10.2.0.0/16"
  }
}

variable "db_password" {
  default   = "ChangeMePlease123!"
  sensitive = true
}

variable "app_count" {
  default = 10
}


variable "instance_types" {
  default = {
    prod    = "m5.2xlarge"
    staging = "m5.large"
    dev     = "t3.medium"
  }
}

variable "rds_instance_classes" {
  default = {
    prod    = "db.r5.2xlarge"
    staging = "db.m5.large"
    dev     = "db.t3.medium"
  }
}
