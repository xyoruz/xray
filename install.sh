#!/bin/bash
# Installer Xray otomatis untuk Debian/Ubuntu dengan auto menu.sh
set -euo pipefail

# cek OS
if ! grep -Eqi "ubuntu|debian" /etc/os-release; then
  echo "Script ini hanya untuk Debian/Ubuntu"; exit 1
fi

read -rp "Masukkan domain Anda (contoh: example.com): " DOMAIN
if [[ -z "$DOMAIN" ]]; then echo "Domain tidak boleh kosong"; exit 1; fi

echo "==> Update & install dependencies"
apt update -y
apt install -y jq curl wget unzip socat cron iptables iptables-persistent ca-certificates

echo "==> Install acme.sh (Let's Encrypt)"
if [ ! -f "$HOME/.acme.sh/acme.sh" ]; then
  curl -sSf https://get.acme.sh | sh
fi

echo "==> Buat sertifikat TLS untuk $DOMAIN"
~/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone --keylength ec-256
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN"     --key-file /etc/letsencrypt/live/$DOMAIN/privkey.pem     --fullchain-file /etc/letsencrypt/live/$DOMAIN/fullchain.pem

echo "==> Install Xray-core"
XRAY_BIN="/usr/local/bin/xray"
if [ ! -x "$XRAY_BIN" ]; then
  TMPDIR=$(mktemp -d)
  cd "$TMPDIR"
  wget -qO xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
  unzip -o xray.zip
  mv xray /usr/local/bin/xray
  chmod +x /usr/local/bin/xray
  cd -
  rm -rf "$TMPDIR"
fi

echo "==> Setup config & systemd"
mkdir -p /etc/xray /var/log/xray /usr/local/bin
cp -n config/*.json /etc/xray/
cp -n systemd/xray.service /etc/systemd/system/
cp -n scripts/* /usr/local/bin/
chmod +x /usr/local/bin/*

echo "==> Update path TLS di config"
for f in /etc/xray/{vless,trojan}.json; do
  jq --arg cert "/etc/letsencrypt/live/$DOMAIN/fullchain.pem"      --arg key "/etc/letsencrypt/live/$DOMAIN/privkey.pem"      '.inbounds[0].streamSettings.tlsSettings.certificates[0].certificateFile=$cert |
      .inbounds[0].streamSettings.tlsSettings.certificates[0].keyFile=$key' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

echo "==> Enable & start Xray service"
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

# buat systemd auto menu.sh
cat > /etc/systemd/system/xray-menu.service <<EOF
[Unit]
Description=Auto Launch Xray Menu
After=network.target xray.service

[Service]
Type=simple
User=root
WorkingDirectory=/root/${repo}
ExecStart=/bin/bash /root/${repo}/menu.sh
Restart=always
StandardInput=tty
StandardOutput=tty

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xray-menu.service

echo "==> Instalasi selesai. Menu Xray akan otomatis dijalankan setiap reboot."
