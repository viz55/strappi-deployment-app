variable "project_name" {
  type    = string
  default = "strapi-app"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "c7i-flex.large"
}

variable "ami_id" {
  type    = string
  default = "ami-0078a63645c7b8a87"
}

variable "public_key_path" {
  type        = string
  description = "Path to public key on the machine running Terraform (example: ~/.ssh/terraform-key.pub)"
  default     = "~/.ssh/terraform-key.pub"
}

variable "github_repo_url" {
  type    = string
  default = "https://github.com/viz55/strappi-deployment-app.git"
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "db_name" {
  type    = string
  default = "strapidb"
}

variable "db_username" {
  type    = string
  default = "strapiuser"
}

variable "db_password" {
  type      = string
  sensitive = true
  description = "RDS master password (set in terraform.tfvars)"
  default   = "Strapi123Strong"
}

variable "enable_multi_az" {
  type    = bool
  default = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}
