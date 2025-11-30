
#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu

systemctl start docker
systemctl enable docker

echo "Pulling Docker image: ${docker_image}"
docker pull ${docker_image}

docker run -d   -e DATABASE_CLIENT=postgres   -e DATABASE_HOST=${db_host}   -e DATABASE_PORT=5432   -e DATABASE_USERNAME=${db_user}   -e DATABASE_PASSWORD=${db_password}   -e DATABASE_NAME=${db_name}   -p 1337:1337   ${docker_image}
