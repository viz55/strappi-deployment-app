output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.strapi.public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.strapi.address
}
