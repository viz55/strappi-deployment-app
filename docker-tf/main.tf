
provider "aws" {
  region = var.aws_region
}

############################
# VPC
############################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
}


resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}


############################
# RDS Security Group
############################
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow EC2 to access Postgres"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# EC2 Security Group
############################
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow inbound HTTP"
  vpc_id      = aws_vpc.main.id

ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# RDS PostgreSQL
############################
resource "aws_db_subnet_group" "db_subnets" {
  name       = "strapi-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "strapi-db-subnet-group"
  }
}


resource "aws_db_instance" "postgres" {
  identifier              = "strapi-db"
  engine                  = "postgres"
  engine_version          = "16.6"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = var.db_name
  username                = var.db_user
  password                = var.db_password
  publicly_accessible     = false
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnets.name
}

############################
# EC2 with Docker
############################
data "template_file" "userdata" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    db_host     = aws_db_instance.postgres.address
    db_user     = var.db_user
    db_password = var.db_password
    db_name     = var.db_name
    docker_image = var.docker_image

    app_keys             = var.app_keys
    api_token_salt       = var.api_token_salt
    admin_jwt_secret     = var.admin_jwt_secret
    jwt_secret           = var.jwt_secret
    transfer_token_salt  = var.transfer_token_salt

  }
}

resource "aws_instance" "strapi_ec2" {
  ami           = var.ami
  instance_type = "c7i-flex.large"
 # Root volume configuration
  root_block_device {
    volume_size = 20        # Size in GB
    volume_type = "gp3"     # gp2, gp3, io1, etc.
    delete_on_termination = true
  }
  subnet_id     = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = data.template_file.userdata.rendered

  tags = {
    Name = "strapi-ec2"
  }
}
