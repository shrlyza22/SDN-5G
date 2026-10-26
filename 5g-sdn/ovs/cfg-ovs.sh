#!/usr/bin/env bash
# pemakaian: cfg-ovs.sh on | off
CFG_DIR=/home/sdn5g/5g-sdn/docker-open5gs/configs/basic
RAN_DIR=/home/sdn5g/5g-sdn/ueransim-run
case "$1" in
  on)
    sed -i '17s/amf\.open5gs\.org/10.10.1.2/' "$CFG_DIR/amf.yaml"
    sed -i '14s/upf\.open5gs\.org/10.10.1.3/' "$CFG_DIR/upf.yaml"
    sed -i -e '9s/gnb\.ueransim\.org/10.10.1.10/' -e '10s/gnb\.ueransim\.org/10.10.1.10/' \
           -e '13s/amf\.open5gs\.org/10.10.1.2/' "$RAN_DIR/configs/gnb.yaml"
    echo "config: OVS (10.10.1.x)";;
  off)
    cp -a "${CFG_DIR}.bak-fase1/amf.yaml" "$CFG_DIR/amf.yaml"
    cp -a "${CFG_DIR}.bak-fase1/upf.yaml" "$CFG_DIR/upf.yaml"
    cp -a "$RAN_DIR/configs/gnb.yaml.bak-fase1" "$RAN_DIR/configs/gnb.yaml"
    echo "config: asli (hostname)";;
  *) echo "pakai: $0 on|off";;
esac
