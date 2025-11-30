#!/bin/bash
set -e
exec > /var/log/userdata.log 2>&1
date; echo "user-data start"

# install essentials
apt-get update -y
apt-get install -y docker.io netcat-openbsd

systemctl enable --now docker

# wait until docker socket active
for i in {1..10}; do
  if sudo systemctl is-active --quiet docker; then
    echo "docker active"
    break
  fi
  echo "waiting for docker..."
  sleep 3
done

# pull image
echo "pull ${docker_image}"
docker pull ${docker_image}

# wait for RDS to accept connections (20 attempts)
for i in {1..20}; do
  if nc -z ${db_host} 5432; then
    echo "rds reachable"
    break
  fi
  echo "waiting for rds..."
  sleep 10
done

# remove previous container if present
docker rm -f strapi || true

# run container with restart policy
docker run -d \
  --name strapi \
  --restart unless-stopped \
  -p 1337:1337 \
  -e DATABASE_CLIENT=postgres \
  -e DATABASE_HOST=${db_host} \
  -e DATABASE_PORT=5432 \
  -e DATABASE_USERNAME=${db_user} \
  -e DATABASE_PASSWORD=${db_password} \
  -e DATABASE_NAME=${db_name} \
  -e HOST=0.0.0.0 \
  ${docker_image}

echo "user-data end: $(date)"
