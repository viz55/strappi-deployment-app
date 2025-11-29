# Strapi Terraform Deployment (EC2 + Nginx + Multi-AZ RDS)

This package provisions a Strapi application on an EC2 instance with:
- Ubuntu AMI (user-specified)
- Node.js 20 + Yarn + PM2
- Nginx as reverse proxy
- Multi-AZ RDS PostgreSQL
- VPC with public/private subnets
- Security groups and IAM instance profile (SSM)

**Important: this ZIP intentionally does NOT embed your SSH public key.**
You must paste your SSH public key into `ec2.tf` as described below before running `terraform apply`.

## Files
- variables.tf
- provider.tf
- vpc.tf
- security_groups.tf
- iam.tf
- rds.tf
- ec2.tf               <-- Edit: paste your SSH public key here (see section below)
- user_data.sh.tpl    <-- Edit: add Strapi secrets if you want custom values (placeholders provided)
- outputs.tf
- terraform.tfvars.example

## Where to edit (minimal required changes)
1. **Paste your SSH public key** into `ec2.tf` at the `aws_key_pair` resource (public_key = "..."). Use the **public** key only (contents of your `.pub` file). Keep it quoted.

2. **Update terraform.tfvars**:
   - db_password = "YOUR_STRONG_DB_PASSWORD"
   - (optional) adjust instance_type, ami_id, region

3. **(Optional) Edit user_data.sh.tpl** to change repo/branch or provide pre-generated secrets. The script will generate random secrets if left as-is.

## How to run (on a machine with AWS credentials)
1. Copy this folder to the machine where you'll run Terraform (you said you'll use an EC2 to run Terraform).
2. Ensure `~/.ssh/terraform-key.pub` exists or paste your public key into `ec2.tf`.
3. `terraform init`
4. `terraform apply` (or `terraform plan` then `apply`)

Outputs will include `ec2_public_ip` and `rds_endpoint`.
