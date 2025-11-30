#!/bin/bash

exec > /var/log/userdata.log 2>&1
echo "===== Starting User Data Execution ====="

# Update system
apt update -y
apt install -y docker.io

# Enable Docker
systemctl start docker
systemctl enable docker

echo "Waiting for Docker to be ready..."
sleep 10

# Pull Strapi image
echo "Pulling Docker image: ${docker_image}"
docker pull ${docker_image}

echo "Waiting for RDS to be ready..."
# Wait until DB accepts connections
for i in {1..20}; do
  if nc -z ${db_host} 5432; then
    echo "RDS is UP!"
    break
  fi
  echo "RDS not up yet... retrying"
  sleep 10
done

# Run Strapi
echo "Running Strapi container..."
docker run -d \
  --name strapi \
  --restart unless-stopped \
  -e DATABASE_CLIENT=postgres \
  -e DATABASE_HOST=${db_host} \
  -e DATABASE_PORT=5432 \
  -e DATABASE_USERNAME=${db_user} \
  -e DATABASE_PASSWORD=${db_password} \
  -e DATABASE_NAME=${db_name} \
  -e HOST=0.0.0.0 \
  -p 1337:1337 \
  ${docker_image}

echo "===== User Data Finished ====="
