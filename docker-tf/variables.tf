
variable "region" { default = "us-east-1" }
variable "ami" { description = "EC2 AMI" }
variable "docker_image" { description = "Docker image to run" }
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}
