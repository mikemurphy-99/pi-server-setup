# Raspberry Pi Home Server Setup Script 🏠📦

This project contains a one-command setup script to turn your Raspberry Pi into a powerful home server running multiple services in Docker containers — with everything neatly organized, easy to maintain, and accessible on your local network.

---

## ✅ Features

The script automatically installs and configures the following:

| Service                | Description                           | Port / URL                        |
|------------------------|---------------------------------------|-----------------------------------|
| **Nextcloud**          | Self-hosted file sync and sharing     | `http://<pi-ip>:8080`             |
| **Transmission**       | BitTorrent client                     | `http://<pi-ip>:9091`             |
| **MeTube**             | YouTube downloader frontend           | `http://<pi-ip>:8081`             |
| **Samba**              | Windows-compatible file sharing       | `\\<pi-ip>\PiServerData`          |
| **Jellyfin**           | Media streaming server                | `http://<pi-ip>:8096`             |
| **Portainer**          | Docker container manager              | `http://<pi-ip>:9000`             |
| **Nginx Proxy Manager**| Reverse proxy & SSL manager           | `http://<pi-ip>:81`               |
| **WireGuard (wg-easy)**| Simple VPN server                     | `http://<pi-ip>:51821`            |
| **Mealie**             | Recipe management web app             | `http://<pi-ip>:9925`             |
| **Minecraft Bedrock**  | Multiplayer Minecraft server          | Port `19132/udp`                  |

All data is stored under a top-level `~/Data` directory for easy access and backups.

---

## ⚙️ Requirements

- Raspberry Pi running 64-bit Raspberry Pi OS (or similar Debian-based distro)
- Internet connection
- Recommended: External storage or SSD for persistent storage

---

## 🚀 Installation

Run the script with a single command:

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/pi-server-setup/main/setup.sh)
