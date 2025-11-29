\
#!/bin/bash
set -e
# Bootstrap for Strapi server (Ubuntu)

# Update packages
apt update -y
apt upgrade -y

# Install base packages
apt install -y nginx git curl build-essential ca-certificates

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install Yarn
npm install -g yarn

# Install PM2
npm install -g pm2

# Create app directory and clone/pull repo
mkdir -p /opt/app
cd /opt
if [ ! -d "app" ]; then
  git clone "${github_repo}" app
else
  cd app
  git pull
fi
cd app
git checkout ${github_branch} || true

# Install dependencies (prefer yarn if yarn.lock exists)
if [ -f yarn.lock ]; then
  yarn install --production=false
else
  npm install
fi

# Create .env file (placeholders for secrets)
cat > .env <<EOF
DATABASE_CLIENT=postgres
DATABASE_HOST=${db_host}
DATABASE_PORT=5432
DATABASE_NAME=${db_name}
DATABASE_USERNAME=${db_user}
DATABASE_PASSWORD=${db_pass}
HOST=0.0.0.0
PORT=1337
NODE_ENV=production
# Replace the following with secure values if you wish, or they will be generated later
APP_KEYS=${APP_KEYS:-""}
API_TOKEN_SALT=${API_TOKEN_SALT:-""}
ADMIN_JWT_SECRET=${ADMIN_JWT_SECRET:-""}
JWT_SECRET=${JWT_SECRET:-""}
EOF

# If APP_KEYS etc are empty, generate random ones and inject into .env
if grep -q 'APP_KEYS=' .env && [ -z "$(grep '^APP_KEYS=' .env | cut -d= -f2)" ]; then
  sed -i "/^APP_KEYS=/c\APP_KEYS=$(openssl rand -hex 32)" .env
fi
if grep -q 'API_TOKEN_SALT=' .env && [ -z "$(grep '^API_TOKEN_SALT=' .env | cut -d= -f2)" ]; then
  sed -i "/^API_TOKEN_SALT=/c\API_TOKEN_SALT=$(openssl rand -hex 16)" .env
fi
if grep -q 'ADMIN_JWT_SECRET=' .env && [ -z "$(grep '^ADMIN_JWT_SECRET=' .env | cut -d= -f2)" ]; then
  sed -i "/^ADMIN_JWT_SECRET=/c\ADMIN_JWT_SECRET=$(openssl rand -hex 32)" .env
fi
if grep -q 'JWT_SECRET=' .env && [ -z "$(grep '^JWT_SECRET=' .env | cut -d= -f2)" ]; then
  sed -i "/^JWT_SECRET=/c\JWT_SECRET=$(openssl rand -hex 32)" .env
fi

# Build admin with increased memory if needed
export NODE_OPTIONS="--max-old-space-size=4096"
if [ -f yarn.lock ]; then
  yarn build
else
  npm run build
fi

# Create systemd service for Strapi (uses npm start)
cat > /etc/systemd/system/strapi.service <<'SERVICE'
[Unit]
Description=Strapi CMS
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/app
Environment=NODE_ENV=production
ExecStart=/usr/bin/yarn start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now strapi

# Configure nginx reverse proxy
cat > /etc/nginx/sites-available/strapi <<'NGINX'
server {
  listen 80;
  server_name _;

  location / {
    proxy_pass http://127.0.0.1:1337;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
NGINX

ln -sf /etc/nginx/sites-available/strapi /etc/nginx/sites-enabled/strapi
rm -f /etc/nginx/sites-enabled/default || true
systemctl restart nginx || true
