#!/usr/bin/env bash
# pemakaian: ./measure.sh LABEL     contoh: ./measure.sh baseline
LABEL=${1:?isi label, contoh: baseline}
OUT=~/5g-sdn/results
mkdir -p "$OUT"

docker rm -f iperf-srv >/dev/null 2>&1
docker run -d --rm --name iperf-srv --network open5gs networkstatic/iperf3 -s >/dev/null
SRV=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' iperf-srv)
sleep 1

echo "== ping UE -> UPF (100 paket) =="
docker exec ue ping -I uesimtun0 -c 100 -i 0.2 10.45.0.1 | tail -2 | tee "$OUT/$LABEL-ping-upf.txt"

echo "== ping UE -> 8.8.8.8 (100 paket) =="
docker exec ue ping -I uesimtun0 -c 100 -i 0.2 8.8.8.8 | tail -2 | tee "$OUT/$LABEL-ping-inet.txt"

for i in 1 2 3; do
  echo "== iperf3 run $i (30 s) =="
  docker run --rm --network container:ue networkstatic/iperf3 \
    -c "$SRV" --bind-dev uesimtun0 -t 30 | tail -4 | tee "$OUT/$LABEL-iperf-$i.txt"
done

docker stop iperf-srv >/dev/null
echo "selesai -> $OUT/$LABEL-*"
