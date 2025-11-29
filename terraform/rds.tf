resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet"
  subnet_ids = aws_subnet.private[*].id
  tags = { Name = "${var.project_name}-db-subnet" }
}

resource "aws_db_instance" "strapi" {
  identifier = "${var.project_name}-db"
  engine     = "postgres"
  engine_version = "16.1"
  instance_class = var.db_instance_class
  allocated_storage = 20

  name     = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  publicly_accessible = false
  multi_az = var.enable_multi_az
  storage_type = "gp3"
  backup_retention_period = 7
  skip_final_snapshot = true

  tags = { Name = "${var.project_name}-rds" }
}

output "rds_endpoint" {
  value = aws_db_instance.strapi.address
}
