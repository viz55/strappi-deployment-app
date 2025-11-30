variable "aws_region" { default = "ap-south-1" }
variable "ami" { description = "EC2 AMI" }
variable "docker_image" { default = "viz55/strapi-app:latest" }
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}
variable "app_keys" {}
variable "api_token_salt" {}
variable "admin_jwt_secret" {}
variable "jwt_secret" {}
variable "admin_auth_secret" {}
