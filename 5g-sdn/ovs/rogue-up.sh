#!/usr/bin/env bash
# Jalankan gNB palsu dan sambungkan ke br-ran (IP 10.10.1.99)
IMG=$(docker inspect gnb -f '{{.Config.Image}}')
EP=$(docker inspect gnb -f '{{join .Config.Entrypoint " "}}')
EP=${EP:-/UERANSIM/nr-gnb}
echo "image=$IMG entrypoint=$EP"

docker rm -f gnb-rogue >/dev/null 2>&1
docker run -d --name gnb-rogue --network none \
  --sysctl net.ipv4.ip_nonlocal_bind=1 \
  -v /home/sdn5g/5g-sdn/controller/gnb-rogue.yaml:/etc/ueransim/custom/gnb.yaml:ro \
  --entrypoint "$EP" "$IMG" -c /etc/ueransim/custom/gnb.yaml
sleep 2
sudo ovs-docker del-ports br-ran gnb-rogue >/dev/null 2>&1 || true
sudo ovs-docker add-port br-ran eth1 gnb-rogue --ipaddress=10.10.1.99/24
sleep 8
docker logs gnb-rogue | tail -6
