#!/bin/bash
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; NC="\e[0m"
pause(){ read -rp "Tekan Enter untuk kembali..." ; }
banner(){
  clear
  echo -e "${CYAN}============================================${NC}"
  echo -e "${GREEN}         XRAY AUTO MANAGEMENT MENU          ${NC}"
  echo -e "${CYAN}============================================${NC}"
  echo -e "${YELLOW}Server: $(hostname) | Date: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
  echo
}
show_clients(){
  TYPE=$1
  CONF="/etc/xray/${TYPE}.json"
  if [ ! -f "$CONF" ]; then echo "Config $CONF tidak ditemukan"; return; fi
  echo "Clients in $TYPE:"
  case "$TYPE" in
    vmess|vless) jq -r '.inbounds[0].settings.clients[] | "\(.email // "-") 	 ID:\(.id)"' "$CONF" 2>/dev/null || echo "Tidak ada user";;
    trojan) jq -r '.inbounds[0].settings.clients[] | "Password: \(.password // "-")"' "$CONF" 2>/dev/null || echo "Tidak ada user";;
  esac
}
main_menu(){
  while true; do
    banner
    echo "1) Kelola VMESS"
    echo "2) Kelola VLESS"
    echo "3) Kelola TROJAN"
    echo "4) Auto-fix Error Config"
    echo "5) Jalankan Limit IP Manual"
    echo "6) Jalankan Lock Multi-login Manual"
    echo "7) Status & Restart Xray"
    echo "8) Exit"
    read -rp "Pilih: " opt
    case $opt in
      1) bash /usr/local/bin/add-user.sh vmess ; pause ;;
      2) bash /usr/local/bin/add-user.sh vless ; pause ;;
      3) bash /usr/local/bin/add-user.sh trojan ; pause ;;
      4) bash /usr/local/bin/xray-fix.sh ; pause ;;
      5) bash /usr/local/bin/xray-limit.sh ; pause ;;
      6) bash /usr/local/bin/xray-lock.sh ; pause ;;
      7) systemctl status xray --no-pager; read -rp "Restart xray? (y/N) " r && [[ $r =~ ^[Yy]$ ]] && systemctl restart xray ; pause ;;
      8) exit 0 ;;
      *) echo "Pilihan tidak valid"; sleep 1 ;;
    esac
  done
}
main_menu
