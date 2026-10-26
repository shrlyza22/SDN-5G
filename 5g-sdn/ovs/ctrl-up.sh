#!/usr/bin/env bash
# pemakaian: ctrl-up.sh APP [VAR=NILAI ...]
#   APP: ryu.app.simple_switch_13   atau   /app/apps/fiveg_ran.py
#   contoh: ctrl-up.sh /app/apps/fiveg_ran.py N3_RATE_KBPS=100000
APP=${1:?isi APP, contoh: ryu.app.simple_switch_13}
shift
ENVARGS=()
for kv in "$@"; do ENVARGS+=(-e "$kv"); done

docker rm -f ryu-ctrl >/dev/null 2>&1
docker run -d --name ryu-ctrl --restart unless-stopped \
  --memory 256m \
  --log-opt max-size=10m --log-opt max-file=2 \
  -p 127.0.0.1:6653:6653 \
  -v /home/sdn5g/5g-sdn/controller/apps:/app/apps:ro \
  "${ENVARGS[@]}" \
  ryu-5g ryu-manager --ofp-tcp-listen-port 6653 "$APP"
sleep 3
docker logs ryu-ctrl 2>&1 | tail -8
