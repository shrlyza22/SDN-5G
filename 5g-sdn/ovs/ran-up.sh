#!/usr/bin/env bash
RAN_DIR=/home/sdn5g/5g-sdn/ueransim-run
C="-f $RAN_DIR/docker-compose.yaml -f $RAN_DIR/compose.ovs.yaml"
cd "$RAN_DIR"
docker compose $C up -d --force-recreate --no-deps gnb
sleep 2
~/5g-sdn/ovs/ovs-attach.sh
sleep 8
docker logs gnb | tail -3
docker compose $C up -d --force-recreate --no-deps ue
sleep 10
docker logs ue | grep -E "Registration|PDU Session|TUN interface"
