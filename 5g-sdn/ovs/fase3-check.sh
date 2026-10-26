#!/usr/bin/env bash
echo "== controller =="
sudo ovs-vsctl --columns=target,is_connected list controller
echo "fail-mode: $(sudo ovs-vsctl get-fail-mode br-ran)"
echo
echo "== container =="
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'NAMES|ryu-ctrl|amf|upf|gnb|ue|smf'
docker stats --no-stream --format 'ryu-ctrl CPU={{.CPUPerc}} MEM={{.MemUsage}}' ryu-ctrl 2>/dev/null
echo
echo "== flow per kelas (cookie 0x1=L2, 0x2=N2, 0x3=N3, 0x9=DROP) =="
sudo ovs-ofctl -O OpenFlow13 dump-flows br-ran | grep -oE 'cookie=0x[0-9a-f]+' | sort | uniq -c
echo
echo "== N2 =="
docker logs gnb 2>&1 | grep "NG Setup" | tail -1
docker logs amf 2>&1 | grep -E "Number of gNBs" | tail -1
echo
echo "== N3 (ping UE -> UPF) =="
docker exec ue ping -I uesimtun0 -c 3 10.45.0.1 | tail -2
