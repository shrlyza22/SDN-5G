#!/usr/bin/env bash
# setup-autostart.sh
#
# Menjalankan SEKALI untuk membuat konfigurasi permanen supaya stack 5G + OVS:
#   1. otomatis hidup lagi bila container mati        (restart: unless-stopped)
#   2. otomatis menyala saat VM boot                  (systemd: 5g-stack.service)
#   3. port OVS br-ran otomatis dipasang ulang        (systemd: ovs-5g-watch.service)
#
# Cara pakai:   sudo bash setup-autostart.sh
#
# Asumsi path (sesuaikan kalau berbeda di VM kamu):
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Jalankan dengan sudo:  sudo bash $0"
  exit 1
fi

U=sdn5g
H=/home/$U
CORE_DIR=$H/5g-sdn/docker-open5gs/compose-files/basic
ENVF=$H/5g-sdn/docker-open5gs/.env
CFG_DIR=$H/5g-sdn/docker-open5gs/configs/basic
RAN_DIR=$H/5g-sdn/ueransim-run
OVS_DIR=$H/5g-sdn/ovs
mkdir -p "$OVS_DIR"

# ---------------------------------------------------------------------------
# 1) Override compose: restart policy untuk semua service + sysctl untuk amf/upf/gnb
# ---------------------------------------------------------------------------
gen_override() {   # gen_override DIR "service_yang_butuh_sysctl" ARGUMEN_COMPOSE...
  local dir="$1" sysctl_svcs="$2"
  shift 2
  local out="$dir/compose.ovs.yaml" services s t
  cd "$dir"
  services=$(docker compose "$@" config --services)
  {
    echo "services:"
    for s in $services; do
      echo "  $s:"
      echo "    restart: unless-stopped"
      for t in $sysctl_svcs; do
        if [ "$s" = "$t" ]; then
          echo "    sysctls:"
          echo "      net.ipv4.ip_nonlocal_bind: 1"
        fi
      done
    done
  } > "$out"
  echo "[ok] $out"
}

gen_override "$CORE_DIR" "amf upf" --env-file "$ENVF" -f docker-compose.yaml
gen_override "$RAN_DIR"  "gnb"     -f "$RAN_DIR/docker-compose.yaml"

if ! grep -q "10.10.1.2" "$CFG_DIR/amf.yaml"; then
  echo "PERINGATAN: $CFG_DIR/amf.yaml belum memakai 10.10.1.2."
  echo "            Jalankan dulu: $OVS_DIR/cfg-ovs.sh on"
fi

# Terapkan restart policy ke container yang sudah ada sekarang juga
for c in $(docker ps -a --format '{{.Names}}'); do
  docker update --restart unless-stopped "$c" >/dev/null 2>&1 || true
done
echo "[ok] restart policy diterapkan ke container yang ada"

# ---------------------------------------------------------------------------
# 2) ovs-attach.sh (pasang manual, dipakai sebagai cadangan)
# ---------------------------------------------------------------------------
cat > "$OVS_DIR/ovs-attach.sh" <<'EOF'
#!/usr/bin/env bash
BR=br-ran

attach() {
  local c="$1" ip="$2"
  if [ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" != "true" ]; then
    echo "[skip] $c tidak running"; return
  fi
  sudo ovs-docker del-ports "$BR" "$c" >/dev/null 2>&1 || true
  if sudo ovs-docker add-port "$BR" eth1 "$c" --ipaddress="$ip"; then
    echo "[ok] $c -> $ip"
  else
    echo "[GAGAL] $c"
  fi
}

attach amf 10.10.1.2/24
attach upf 10.10.1.3/24
attach gnb 10.10.1.10/24
EOF

# ---------------------------------------------------------------------------
# 3) ovs-watch.sh: pasang ulang port OVS setiap amf/upf/gnb (re)start
# ---------------------------------------------------------------------------
cat > "$OVS_DIR/ovs-watch.sh" <<'EOF'
#!/usr/bin/env bash
BR=br-ran

ip_of() {
  case "$1" in
    amf) echo 10.10.1.2/24 ;;
    upf) echo 10.10.1.3/24 ;;
    gnb) echo 10.10.1.10/24 ;;
    *)   echo "" ;;
  esac
}

has_ip() { docker exec "$1" grep -q -- "-- $2\$" /proc/net/fib_trie 2>/dev/null; }

attach_one() {
  local c="$1" ip
  ip=$(ip_of "$c")
  [ -z "$ip" ] && return 0
  sleep 1
  ovs-docker del-ports "$BR" "$c" >/dev/null 2>&1 || true
  if ovs-docker add-port "$BR" eth1 "$c" --ipaddress="$ip"; then
    logger -t ovs-5g-watch "attached $c -> $ip"
  else
    logger -t ovs-5g-watch "GAGAL attach $c"
  fi
}

until docker info >/dev/null 2>&1; do sleep 2; done
ovs-vsctl --may-exist add-br "$BR"
ip link set "$BR" up

# container yang sudah jalan tapi belum terpasang
for c in amf upf gnb; do
  if [ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" = "true" ]; then
    ip=$(ip_of "$c")
    has_ip "$c" "${ip%/*}" || attach_one "$c"
  fi
done

# container yang (re)start berikutnya
docker events --filter type=container --filter event=start \
  --format '{{.Actor.Attributes.name}}' | while read -r name; do
  attach_one "$name"
done
EOF

# ---------------------------------------------------------------------------
# 4) stack-up.sh: nyalakan / perbaiki seluruh stack (aman dijalankan berulang)
# ---------------------------------------------------------------------------
cat > "$OVS_DIR/stack-up.sh" <<'EOF'
#!/usr/bin/env bash
CORE_DIR=/home/sdn5g/5g-sdn/docker-open5gs/compose-files/basic
ENVF=/home/sdn5g/5g-sdn/docker-open5gs/.env
RAN_DIR=/home/sdn5g/5g-sdn/ueransim-run
OVS_DIR=/home/sdn5g/5g-sdn/ovs

log() { echo "[stack-up $(date +%H:%M:%S)] $*"; }
running() { [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = "true" ]; }
has_ip() { docker exec "$1" grep -q -- "-- $2\$" /proc/net/fib_trie 2>/dev/null; }

ensure_attached() {   # ensure_attached NAMA IP
  local c="$1" ip="$2" i
  for i in $(seq 1 20); do
    if has_ip "$c" "$ip"; then log "$c sudah terpasang di br-ran ($ip)"; return 0; fi
    sleep 1
  done
  log "$c belum terpasang ke br-ran, attach manual"
  "$OVS_DIR/ovs-attach.sh"
}

until docker info >/dev/null 2>&1; do sleep 2; done
ovs-vsctl --may-exist add-br br-ran
ip link set br-ran up

# 1) core
upf_was_up=false
running upf && upf_was_up=true
cd "$CORE_DIR"
log "menyalakan core"
docker compose --env-file "$ENVF" -f docker-compose.yaml -f compose.ovs.yaml up -d
ensure_attached amf 10.10.1.2
ensure_attached upf 10.10.1.3
if [ "$upf_was_up" = false ]; then
  log "UPF baru dinyalakan -> restart SMF agar PFCP tersambung ulang"
  docker restart smf >/dev/null
fi
sleep 5

# 2) RAN (gNB + UE)
cd "$RAN_DIR"
log "menyalakan gNB dan UE"
docker compose -f docker-compose.yaml -f compose.ovs.yaml up -d
ensure_attached gnb 10.10.1.10

# 3) tunggu UE mendapat uesimtun0 (restart UE sekali kalau perlu)
tun_ok() { docker exec ue ip addr show uesimtun0 >/dev/null 2>&1; }
for i in $(seq 1 15); do tun_ok && break; sleep 2; done
if ! tun_ok; then
  log "uesimtun0 belum ada -> restart UE"
  docker restart ue >/dev/null
  for i in $(seq 1 20); do tun_ok && break; sleep 2; done
fi
if tun_ok; then
  log "OK: UE punya uesimtun0"
else
  log "GAGAL: uesimtun0 belum muncul, cek: docker logs ue ; docker logs gnb ; docker logs amf"
fi
docker ps --format 'table {{.Names}}\t{{.Status}}'
EOF

chmod +x "$OVS_DIR/ovs-attach.sh" "$OVS_DIR/ovs-watch.sh" "$OVS_DIR/stack-up.sh"

# ---------------------------------------------------------------------------
# 5) systemd
# ---------------------------------------------------------------------------
cat > /etc/systemd/system/ovs-5g-watch.service <<EOF
[Unit]
Description=Pasang ulang port OVS br-ran untuk container 5G (amf, upf, gnb)
After=docker.service openvswitch-switch.service
Requires=docker.service openvswitch-switch.service

[Service]
ExecStart=$OVS_DIR/ovs-watch.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/5g-stack.service <<EOF
[Unit]
Description=Stack 5G (Open5GS + UERANSIM) dengan OVS br-ran
After=docker.service openvswitch-switch.service ovs-5g-watch.service
Requires=docker.service
Wants=ovs-5g-watch.service

[Service]
Type=oneshot
RemainAfterExit=yes
TimeoutStartSec=900
ExecStart=$OVS_DIR/stack-up.sh

[Install]
WantedBy=multi-user.target
EOF

chown -R "$U:$U" "$OVS_DIR" "$CORE_DIR/compose.ovs.yaml" "$RAN_DIR/compose.ovs.yaml"

systemctl daemon-reload
systemctl enable docker openvswitch-switch >/dev/null 2>&1 || true
systemctl enable --now ovs-5g-watch.service
systemctl enable 5g-stack.service

echo
echo "SELESAI. Yang sudah dibuat:"
echo "  - $CORE_DIR/compose.ovs.yaml   (restart policy + sysctl amf/upf)"
echo "  - $RAN_DIR/compose.ovs.yaml    (restart policy + sysctl gnb)"
echo "  - $OVS_DIR/{ovs-attach,ovs-watch,stack-up}.sh"
echo "  - ovs-5g-watch.service (aktif sekarang) dan 5g-stack.service (aktif saat boot)"
echo
echo "Langkah berikutnya:"
echo "  sudo systemctl start 5g-stack      # jalankan sekarang dan lihat hasilnya"
echo "  journalctl -u 5g-stack -n 40 --no-pager"
