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
