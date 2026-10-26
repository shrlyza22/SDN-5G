#!/usr/bin/env bash
# pemakaian: run-all-measure.sh NOMOR_SESI     contoh: run-all-measure.sh 1
S=${1:+-s$1}
OVS=/home/sdn5g/5g-sdn/ovs

run() {   # run LABEL APP [VAR=NILAI]
  local label="$1"; shift
  echo "##### $label$S"
  $OVS/ctrl-up.sh "$@" >/dev/null
  sleep 8
  $OVS/ran-up.sh >/dev/null
  sleep 5
  if ! docker exec ue ping -I uesimtun0 -c 3 10.45.0.1 >/dev/null 2>&1; then
    echo "GAGAL pra-cek untuk $label, dilewati"; return 1
  fi
  $OVS/measure.sh "$label$S"
}

run ryu-simple      ryu.app.simple_switch_13
run ryu-5g          /app/apps/fiveg_ran.py
run ryu-5g-meter100 /app/apps/fiveg_ran.py N3_RATE_KBPS=100000
run ryu-5g-meter50  /app/apps/fiveg_ran.py N3_RATE_KBPS=50000

echo "##### kembali ke konfigurasi final"
$OVS/ctrl-up.sh /app/apps/fiveg_ran.py >/dev/null
sleep 8
$OVS/ran-up.sh >/dev/null
$OVS/fase3-check.sh
