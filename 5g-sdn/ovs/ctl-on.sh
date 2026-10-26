#!/usr/bin/env bash
# Sambungkan br-ran ke controller (out-of-band), fail-mode secure
CTRL=${1:-tcp:127.0.0.1:6653}
sudo ovs-vsctl set bridge br-ran protocols=OpenFlow13 other-config:disable-in-band=true
sudo ovs-vsctl set-controller br-ran "$CTRL"
sudo ovs-vsctl set-fail-mode br-ran secure
sleep 2
sudo ovs-vsctl --columns=target,is_connected list controller
