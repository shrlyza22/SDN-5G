#!/usr/bin/env bash
# DARURAT / ROLLBACK: kembalikan br-ran ke mode NORMAL tanpa controller
sudo ovs-vsctl --if-exists del-controller br-ran
sudo ovs-vsctl --if-exists del-fail-mode br-ran
sudo ovs-ofctl -O OpenFlow13 del-flows br-ran
sudo ovs-ofctl -O OpenFlow13 add-flow br-ran "priority=0,actions=NORMAL"
sudo ovs-ofctl -O OpenFlow13 dump-flows br-ran
