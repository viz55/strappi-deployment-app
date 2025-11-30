
#!/bin/bash
apt-get update -y
apt-get install -y docker.io

systemctl start docker
systemctl enable docker

docker run -d   -e DATABASE_CLIENT=postgres   -e DATABASE_HOST=${db_host}   -e DATABASE_PORT=5432   -e DATABASE_USERNAME=${db_user}   -e DATABASE_PASSWORD=${db_password}   -e DATABASE_NAME=${db_name}   -p 1337:1337   ${docker_image}
