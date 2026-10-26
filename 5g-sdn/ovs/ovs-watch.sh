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
