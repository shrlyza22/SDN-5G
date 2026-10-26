#!/usr/bin/env bash
# Pastikan controller Ryu hidup dan tersambung ke br-ran SEBELUM gNB/UE dinyalakan.
# Aman dijalankan berulang. Kalau ryu-ctrl belum pernah dibuat, dilewati.
log() { echo "[ctrl-wait $(date +%H:%M:%S)] $*"; }

if ! docker inspect ryu-ctrl >/dev/null 2>&1; then
  log "ryu-ctrl belum ada, dilewati"; exit 0
fi

if [ "$(docker inspect -f '{{.State.Running}}' ryu-ctrl)" != "true" ]; then
  log "ryu-ctrl mati, dinyalakan"
  docker start ryu-ctrl >/dev/null
fi

if [ -z "$(ovs-vsctl get-controller br-ran 2>/dev/null)" ]; then
  log "controller belum diset di br-ran, dipasang"
  ovs-vsctl set bridge br-ran protocols=OpenFlow13 other-config:disable-in-band=true
  ovs-vsctl set-controller br-ran tcp:127.0.0.1:6653
  ovs-vsctl set-fail-mode br-ran secure
fi

for i in $(seq 1 45); do
  if [ "$(ovs-vsctl get controller br-ran is_connected 2>/dev/null)" = "true" ]; then
    log "controller tersambung"
    sleep 3        # beri waktu Ryu mereset flow dan memasang table-miss
    exit 0
  fi
  sleep 2
done
log "PERINGATAN: controller belum tersambung setelah 90 detik"
exit 0
