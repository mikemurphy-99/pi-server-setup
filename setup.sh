#!/bin/bash

# Raspberry Pi Server Setup Script

echo "📦 Updating system and installing Docker + Docker Compose..."
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io docker-compose -y
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker <<EONG

echo "📁 Creating Data directories..."
mkdir -p ~/Data/Backup ~/Data/Downloads ~/Data/Media/{Movies,Photos,"Music Videos"}
sudo chmod -R 777 ~/Data

# --- Samba ---
echo "📂 Setting up Samba..."
mkdir -p ~/samba && cd ~/samba
cat <<EOF > docker-compose.yml
version: "3.8"
services:
  samba:
    image: dperson/samba
    container_name: samba
    restart: unless-stopped
    ports:
      - "139:139"
      - "445:445"
    volumes:
      - /home/pi/Data:/mount
    command: >
      -u "mike;passey"
      -s "PiServerData;/mount;yes;no;no;mike"
EOF
docker-compose up -d

# --- MeTube ---
echo "📥 Setting up MeTube..."
mkdir -p ~/metube && cd ~/metube
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  metube:
    image: alexta69/metube
    container_name: metube
    restart: unless-stopped
    ports:
      - "8081:8081"
    volumes:
      - /home/pi/Data/Downloads:/downloads
    environment:
      - DOWNLOAD_DIR=/downloads
EOF
docker-compose up -d

# --- Transmission ---
echo "📡 Setting up Transmission..."
mkdir -p ~/transmission && cd ~/transmission
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  transmission:
    image: linuxserver/transmission
    container_name: transmission
    restart: unless-stopped
    ports:
      - "9091:9091"
      - "51413:51413"
      - "51413:51413/udp"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
    volumes:
      - /home/pi/Data/Downloads:/downloads
      - ./transmission-config:/config
EOF
docker-compose up -d

# --- Nextcloud ---
echo "☁️  Setting up Nextcloud..."
mkdir -p ~/nextcloud && cd ~/nextcloud
cat <<EOF > docker-compose.yml
version: '3'
services:
  db:
    image: mariadb:latest
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: your_root_password
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
      MYSQL_PASSWORD: your_nextcloud_password
    volumes:
      - db_data:/var/lib/mysql
      - /home/pi/Data/Downloads:/mnt/downloads
      - /home/pi/Data/Backup:/mnt/backup
      - /home/pi/Data/Media:/mnt/media
    networks:
      - nextcloud_network
  nextcloud:
    image: nextcloud:latest
    restart: always
    ports:
      - "8080:80"
    environment:
      - PUID=1000
      - PGID=1000
      - MYSQL_HOST=db
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=your_nextcloud_password
    volumes:
      - nextcloud_data:/var/www/html
      - /home/pi/Data/Downloads:/mnt/downloads
      - /home/pi/Data/Backup:/mnt/backup
      - /home/pi/Data/Media:/mnt/media
    depends_on:
      - db
    networks:
      - nextcloud_network
volumes:
  db_data:
  nextcloud_data:
networks:
  nextcloud_network:
    driver: bridge
EOF
docker-compose up -d

# --- Jellyfin ---
echo "🎞️  Setting up Jellyfin..."
mkdir -p ~/jellyfin && cd ~/jellyfin
cat <<EOF > docker-compose.yml
version: "3.8"
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    user: 1000:1000
    network_mode: "host"
    restart: unless-stopped
    volumes:
      - /home/pi/Data/Media/Movies:/media/Movies
      - "/home/pi/Data/Media/Music Videos:/media/MusicVideos"
      - /home/pi/Data/Media/Photos:/media/Photos
      - jellyfin_config:/config
      - jellyfin_cache:/cache
    environment:
      - TZ=America/Halifax
volumes:
  jellyfin_config:
  jellyfin_cache:
EOF
docker-compose up -d

# --- Portainer ---
echo "🛠️  Setting up Portainer..."
mkdir -p ~/portainer && cd ~/portainer
cat <<EOF > docker-compose.yml
version: "3.8"
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - 9000:9000
      - 9443:9443
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
volumes:
  portainer_data:
EOF
docker-compose up -d

# --- Nginx Proxy Manager ---
echo "🌐 Setting up Nginx Proxy Manager..."
mkdir -p ~/nginx && cd ~/nginx
cat <<EOF > docker-compose.yml
version: "3.8"
services:
  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: npm
    restart: unless-stopped
    ports:
      - 80:80
      - 81:81
      - 443:443
    environment:
      DB_SQLITE_FILE: "/data/database.sqlite"
    volumes:
      - npm_data:/data
      - npm_letsencrypt:/etc/letsencrypt
volumes:
  npm_data:
  npm_letsencrypt:
EOF
docker-compose up -d

# --- WireGuard ---
echo "🔐 Setting up WireGuard..."
mkdir -p ~/wireguard && cd ~/wireguard
cat <<EOF > docker-compose.yml
version: "3.8"
services:
  wg-easy:
    image: weejewel/wg-easy
    container_name: wg-easy
    restart: unless-stopped
    network_mode: "host"
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - WG_HOST=wireguard.mikespi.ddns.net
      - PASSWORD=uRspc3QJqJkAntXcLyXE
      - WG_PORT=51820
      - WG_ALLOWED_IPS=0.0.0.0/0, ::/0
      - WG_DEFAULT_ADDRESS=10.8.0.x
      - WG_INTERFACE=wg0
      - LANG=en
    volumes:
      - wg_easy_data:/etc/wireguard
volumes:
  wg_easy_data:
EOF
docker-compose up -d

# --- Mealie ---
echo "🍲 Setting up Mealie..."
mkdir -p ~/mealie && cd ~/mealie
cat <<EOF > docker-compose.yml
version: "3.8"
services:
  mealie:
    image: hkotel/mealie:latest
    container_name: mealie
    restart: unless-stopped
    ports:
      - "9925:9000"
    environment:
      - ALLOW_SIGNUP=true
      - PUID=1000
      - PGID=1000
      - TZ=America/Halifax
      - BASE_URL=http://192.168.0.10:9925
    volumes:
      - mealie_data:/app/data
volumes:
  mealie_data:
EOF
docker-compose up -d

# --- Minecraft Bedrock ---
echo "🎮 Setting up Minecraft Bedrock..."
mkdir -p ~/minecraft && cd ~/minecraft
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  bedrock-server:
    image: itzg/minecraft-bedrock-server
    container_name: bedrock-server
    ports:
      - "19132:19132/udp"
    environment:
      EULA: "TRUE"
      GAMEMODE: "survival"
      DIFFICULTY: "normal"
      SERVER_NAME: "Elijah's Minecraft Server"
      MAX_PLAYERS: 10
      ALLOW_CHEATS: "true"
    volumes:
      - ./bedrock-data:/data
    restart: unless-stopped
  bedrock-backup:
    image: itzg/mc-backup
    container_name: bedrock-backup
    environment:
      BACKUP_INTERVAL: "6h"
      PRUNE_BACKUPS_DAYS: "30"
      RCON_HOST: bedrock-server
      RCON_PORT: 19132
      RCON_PASSWORD: ""
      INITIAL_DELAY: "5m"
    volumes:
      - ./bedrock-data:/data:ro
      - ./backups:/backups
    depends_on:
      - bedrock-server
    restart: unless-stopped
EOF
docker-compose up -d

EONG

LOCAL_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ Raspberry Pi Server setup complete!"
echo ""
echo "🌐 Access your services:"
echo "📁 Nextcloud:         http://$LOCAL_IP:8080"
echo "🌀 Transmission:      http://$LOCAL_IP:9091"
echo "📥 MeTube:            http://$LOCAL_IP:8081"
echo "🎞️  Jellyfin:          http://$LOCAL_IP:8096"
echo "🛠️  Portainer:         http://$LOCAL_IP:9000"
echo "🌐 Nginx Proxy Mgr:   http://$LOCAL_IP:81"
echo "🔐 WireGuard UI:      http://$LOCAL_IP:51821"
echo "🍲 Mealie Recipes:    http://$LOCAL_IP:9925"
echo "🎮 Minecraft Bedrock: Port 19132 (UDP)"