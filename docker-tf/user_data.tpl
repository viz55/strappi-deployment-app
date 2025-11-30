#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "=== User-data started ==="

# Debug: print passed variables
echo "Docker image: ${docker_image}"
echo "DB host: ${db_host}"
echo "DB user: ${db_user}"
echo "DB name: ${db_name}"

# Update packages and install dependencies
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release netcat

# Install Docker
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
> /etc/apt/sources.list.d/docker.list

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

# Enable and start Docker
sudo systemctl enable --now docker

# Wait for Docker to be ready
echo "Waiting for Docker daemon..."
until docker info >/dev/null 2>&1; do
    sleep 3
done

# Wait for Postgres to be reachable
echo "Waiting for DB at ${db_host}:5432..."
until nc -z ${db_host} 5432; do
    echo "DB not reachable yet, sleeping..."
    sleep 5
done
echo "DB reachable!"

# Remove old Strapi container if exists
docker rm -f strapi || true

# Pull and run Strapi container
echo "Pulling Docker image ${docker_image}..."
docker pull ${docker_image}

echo "Running Strapi container..."
docker run -d \
  --name strapi \
  -p 1337:1337 \
  --restart unless-stopped \
  -e DATABASE_CLIENT=postgres \
  -e DATABASE_HOST=${db_host} \
  -e DATABASE_PORT=5432 \
  -e DATABASE_USERNAME=${db_user} \
  -e DATABASE_PASSWORD=${db_password} \
  -e DATABASE_NAME=${db_name} \
  -e HOST=0.0.0.0 \
  ${docker_image}

# Debug: confirm container is running
echo "Docker containers:"
docker ps -a

echo "=== User-data completed ==="

