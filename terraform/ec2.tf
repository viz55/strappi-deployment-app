# IMPORTANT: This file contains a placeholder for your SSH public key.
# Paste your SSH PUBLIC KEY (contents of your .pub file) into the public_key value below before running Terraform.
# Example:
# public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAAB... user@host"

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = "" # <-- PASTE YOUR SSH PUBLIC KEY HERE (quoted)
}

resource "aws_instance" "strapi" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name      = aws_key_pair.deployer.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    github_repo = var.github_repo_url,
    github_branch = var.github_branch,
    db_host     = aws_db_instance.strapi.address,
    db_name     = var.db_name,
    db_user     = var.db_username,
    db_pass     = var.db_password
  })

  tags = { Name = "${var.project_name}-ec2" }
}

output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}
