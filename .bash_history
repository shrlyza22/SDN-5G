cd /etc/netplan
ip -br a
sudo nano /etc/netplan/50-cloud-init.yaml
sudo netplan try
sudo nano /etc/netplan/50-cloud-init.yaml
sudo netplan try
sudo nano /etc/netplan/50-cloud-init.yaml
sudo netplan try
sudo netplan apply
sudo nano etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
sudo nano /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
ls -la /etc/cloud/cloud.cfg.d/ | grep disable
sudo reboot
lsb_release -a; uname -r; nproc; free -h; df -h /
sudo apt update && sudo apt upgrade -y
sudo lvextend -r -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
df -h /
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
docker run --rm hello-world
exit
docker exec ue ping -I uesimtun0 -c 5 10.45.0.1
docker exec ue ping -I uesimtun0 -c 100 -i 0.2 10.45.0.1 | tail -3 | tee baseline-ping.txt
groups
docker run --rm hello-world
docker compose version
docker buildx version
sudo apt install -y git make openvswitch-switch iperf3 tcpdump iproute2 iputils-ping lksctp-tools net-tools
sudo modprobe sctp
lsmod | grep sctp
echo sctp | sudo tee -a /etc/modules
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-5g.conf
sudo sysctl --system
sudo systemctl status openvswitch-switch --no-pager
sudo ovs-vsctl show
mkdir -p ~/5g-sdn && cd ~/5g-sdn
git clone https://github.com/Borjis131/docker-open5gs
git clone https://github.com/Borjis131/docker-ueransim
mkdir -p ueransim-run/configs
cd ~/5g-sdn/docker-open5gs
hostname -I
nano .env
grep -n -B2 -A8 "plmn_id" configs/basic/amf.yaml
grep -n -B1 -A3 "tac" configs/basic/amf.yaml
grep -n -B3 -A8 "gtpu" configs/basic/upf.yaml
grep -n -A6 "subnet" configs/basic/smf.yaml
grep -n "db_uri" configs/basic/udr.yaml
sed -i 's/^\(\s*\)advertise: docker-host.external-ip/\1#advertise: docker-host.external-ip/' configs/basic/upf.yaml
grep -n -A3 "gtpu" configs/basic/upf.yaml
make base-open5gs
docker compose -f compose-files/basic/docker-compose.yaml --env-file=.env up -d
docker compose -f compose-files/basic/docker-compose.yaml ps
docker compose -f compose-files/basic/docker-compose.yaml --env-file=.env ps
docker logs nrf | tail -20
docker logs amf | tail -20
docker network inspect open5gs | grep -E "Name|IPv4Address"
ip addr show br-ogs
cd ~/5g-sdn
cat > add-subscriber.js <<'EOF
db.subscribers.deleteMany({ imsi: "001011234567891" })
db.subscribers.insertOne({
  imsi: "001011234567891",
  subscribed_rau_tau_timer: 12,
  network_access_mode: 0,
  subscriber_status: 0,
  access_restriction_data: 32,
  slice: [{
    sst: 1,
    default_indicator: true,
    session: [{
      name: "internet",
      type: 1,
      ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
      qos: { index: 9, arp: { priority_level: 8, pre_emption_capability: 1, pre_emption_vulnerability: 1 } }
    }]
  }],
  ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
  security: {
    k: "00000000000000000000000000000000",
    amf: "8000",
    op: null,
    opc: "00000000000000000000000000000000"
  },
  schema_version: 1,
  __v: 0
})
EOF
EOF
cat > add-subscriber.js <<'EOF'
db.subscribers.deleteMany({ imsi: "001011234567891" })
db.subscribers.insertOne({
  imsi: "001011234567891",
  subscribed_rau_tau_timer: 12,
  network_access_mode: 0,
  subscriber_status: 0,
  access_restriction_data: 32,
  slice: [{
    sst: 1,
    default_indicator: true,
    session: [{
      name: "internet",
      type: 1,
      ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
      qos: { index: 9, arp: { priority_level: 8, pre_emption_capability: 1, pre_emption_vulnerability: 1 } }
    }]
  }],
  ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
  security: {
    k: "00000000000000000000000000000000",
    amf: "8000",
    op: null,
    opc: "00000000000000000000000000000000"
  },
  schema_version: 1,
  __v: 0
})
EOF

docker exec -i db sh -c 'if command -v mongosh >/dev/null; then mongosh --quiet open5gs; else mongo --quiet open5gs; fi' < add-subscriber.js
docker exec db sh -c 'if command -v mongosh >/dev/null; then mongosh --quiet open5gs --eval "db.subscribers.countDocuments({imsi:\"001011234567891\"})"; else mongo --quiet open5gs --eval "db.subscribers.count({imsi:\"001011234567891\"})"; fi'
cd ~/5g-sdn/docker-ueransim
nano docker-bake.hcl
docker buildx bake
docker images --format '{{.Repository}}:{{.Tag}}' | head -20
docker image inspect <IMAGE_GNB> --format 'Entrypoint={{.Config.Entrypoint}} Cmd={{.Config.Cmd}} Workdir={{.Config.WorkingDir}}'
docker image inspect <IMAGE_UE>  --format 'Entrypoint={{.Config.Entrypoint}} Cmd={{.Config.Cmd}} Workdir={{.Config.WorkingDir}}'
docker run --rm --entrypoint sh <IMAGE_GNB> -c "which nr-gnb; which nr-ue; which nr-binder"
docker image inspect gnb:v3.3.0 --format 'Entrypoint={{.Config.Entrypoint}} Cmd={{.Config.Cmd}} Workdir={{.Config.WorkingDir}}'
docker image inspect ue:v3.3.0 --format 'Entrypoint={{.Config.Entrypoint}} Cmd={{.Config.Cmd}} Workdir={{.Config.WorkingDir}}'
docker run --rm --entrypoint sh gnb:v3.3.0 -c "which nr-gnb; which nr-ue; which nr-binder"
cd ~/5g-sdn/ueransim-run
cp ~/5g-sdn/docker-ueransim/configs/gnb.yaml configs/
cp ~/5g-sdn/docker-ueransim/configs/ue.yaml  configs/
nano docker-compose.yaml
grep -n -B1 -A3 "sst" configs/ue.yaml
sed -i '31s/.*/      sst: 1\n      sd: 1/' configs/ue.yaml
sed -i '35s/.*/  - sst: 1\n    sd: 1/' configs/ue.yaml
grep -n -B1 -A3 "sst" configs/ue.yaml
grep -nE "supi|mcc|mnc|key|op|amf" configs/ue.yaml
cd ~/5g-sdn
cat > add-subscriber.js <<'EOF'
db.subscribers.deleteMany({ imsi: "001011234567891" })
db.subscribers.insertOne({
  imsi: "001011234567891",
  subscribed_rau_tau_timer: 12,
  network_access_mode: 0,
  subscriber_status: 0,
  access_restriction_data: 32,
  slice: [{
    sst: 1,
    sd: "000001",
    default_indicator: true,
    session: [{
      name: "internet",
      type: 1,
      ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
      qos: { index: 9, arp: { priority_level: 8, pre_emption_capability: 1, pre_emption_vulnerability: 1 } }
    }]
  }],
  ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
  security: {
    k: "00000000000000000000000000000000",
    amf: "8000",
    op: null,
    opc: "00000000000000000000000000000000"
  },
  schema_version: 1,
  __v: 0
})
EOF

docker exec -i db sh -c 'if command -v mongosh >/dev/null; then mongosh --quiet open5gs; else mongo --quiet open5gs; fi' < add-subscriber.js
docker exec db sh -c 'if command -v mongosh >/dev/null; then mongosh --quiet open5gs --eval "db.subscribers.countDocuments({imsi:\"001011234567891\"})"; else mongo --quiet open5gs --eval "db.subscribers.count({imsi:\"001011234567891\"})"; fi'
cd ~/5g-sdn/ueransim-run
docker compose up -d gnb
docker logs gnb | tail -20
docker logs amf | tail -20
cd ~/5g-sdn/ueransim-run
grep -n -B1 -A3 "sst" configs/gnb.yaml
sed -i 's/^\(\s*\)- sst: 1\s*$/\1- sst: 1\n\1  sd: 1/' configs/gnb.yaml
grep -n -B1 -A3 "sst" configs/gnb.yaml
docker compose up -d --force-recreate gnb
docker logs gnb | tail -10
docker logs amf | tail -5
docker compose up -d ue
docker logs ue | tail -40
docker exec ue ip addr show uesimtun0
sleep 5
docker logs ue | tail -30
docker exec ue ip addr show uesimtun0
docker exec ue ping -I uesimtun0 -c 4 10.45.0.1
docker exec ue ping -I uesimtun0 -c 4 8.8.8.8
docker exec ue curl --interface uesimtun0 -s -o /dev/null -w "%{http_code}\n" https://example.com
docker run --rm --network container:ue curlimages/curl   --interface uesimtun0 -s -o /dev/null -w "%{http_code}\n" https://example.com
docker exec ue ping -I uesimtun0 -c 4 10.45.0.1
docker exec ue ping -I uesimtun0 -c 4 8.8.8.8
docker run --rm --network container:upf nicolaka/netshoot   tcpdump -ni eth0 udp port 2152 -c 10
docker exec ue ping -I uesimtun0 -c 100 -i 0.2 10.45.0.1 | tail -3 | tee baseline-ping.txt
docker network ls | grep open5gs  
docker run -d --rm --name iperf-srv --network <nama_network> networkstatic/iperf3 -s
docker run -d --rm --name iperf-srv --network open5gs networkstatic/iperf3 -s
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' iperf-srv
docker run --rm --network container:ue networkstatic/iperf3   -c 10.33.33.15 --bind-dev uesimtun0 -t 30 | tee baseline-iperf.txt
docker stop iperf-srv
mkdir -p ~/5g-sdn/ovs ~/5g-sdn/results
CORE_DIR=$(docker inspect amf -f '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}')
RAN_DIR=$(docker inspect gnb -f '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}')
echo "CORE_DIR=$CORE_DIR"
echo "RAN_DIR=$RAN_DIR"
du -sh "$CORE_DIR" "$RAN_DIR"
cp -a "$CORE_DIR" "${CORE_DIR}.bak-fase1"
cp -a "$RAN_DIR"  "${RAN_DIR}.bak-fase1"
cd "$CORE_DIR" && docker compose config --services && ls
cd "$RAN_DIR"  && docker compose config --services && ls
cat > ~/5g-sdn/ovs/measure.sh <<'EOF'
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
EOF

chmod +x ~/5g-sdn/ovs/measure.sh
~/5g-sdn/ovs/measure.sh baseline
sudo apt update
sudo apt install -y openvswitch-switch
sudo systemctl enable --now openvswitch-switch
sudo ovs-vsctl --may-exist add-br br-ran
sudo ip link set br-ran up
sudo ovs-vsctl show
which ovs-docker
sudo ovs-appctl dpif/show
cd "$CORE_DIR"
grep -rn "ngap" --include="*.yaml" --include="*.yml" . | head
docker inspect amf --format '{{range .Mounts}}{{.Source}}  ->  {{.Destination}}{{"\n"}}{{end}}'
AMF_YAML=$(docker inspect amf --format '{{range .Mounts}}{{if eq .Destination "/etc/open5gs/custom/amf.yaml"}}{{.Source}}{{end}}{{end}}')
echo "$AMF_YAML"
grep -n "ngap" -A4 "$AMF_YAML"
CFG_DIR=$(dirname "$AMF_YAML")
cp -a "$CFG_DIR" "${CFG_DIR}.bak-fase1"
sed -i '17s/amf\.open5gs\.org/10.10.1.2/' "$AMF_YAML"
grep -n "ngap" -A4 "$AMF_YAML"
UPF_YAML="$CFG_DIR/upf.yaml"
grep -n "gtpu" -B2 -A4 "$UPF_YAML"
sed -i '14s/upf\.open5gs\.org/10.10.1.3/' "$UPF_YAML"
sed -n '1,17p' "$UPF_YAML"
docker inspect gnb --format '{{range .Mounts}}{{.Source}}  ->  {{.Destination}}{{"\n"}}{{end}}'
GNB_YAML=/home/sdn5g/5g-sdn/ueransim-run/configs/gnb.yaml
cp -a "$GNB_YAML" "$GNB_YAML.bak-fase1"
cat -n "$GNB_YAML"
sed -i -e '9s/gnb\.ueransim\.org/10.10.1.10/'        -e '10s/gnb\.ueransim\.org/10.10.1.10/'        -e '13s/amf\.open5gs\.org/10.10.1.2/' "$GNB_YAML"
sed -n '8,14p' "$GNB_YAML"
mkdir -p ~/5g-sdn/ovs ~/5g-sdn/results
~/5g-sdn/ovs/measure.sh baseline
sudo apt update && sudo apt install -y openvswitch-switch
cat > "$CORE_DIR/compose.ovs.yaml" <<'EOF'

services:
  amf:
    sysctls:
      net.ipv4.ip_nonlocal_bind: 1
  upf:
    sysctls:
      net.ipv4.ip_nonlocal_bind: 1
EOF

RAN_DIR=/home/sdn5g/5g-sdn/ueransim-run
docker ps -a --format 'table {{.Names}}\t{{.Status}}' | grep -E 'amf|upf|smf|gnb|ue'
docker logs ue | tail -15
CORE_DIR=/home/sdn5g/5g-sdn/docker-open5gs/compose-files/basic
RAN_DIR=/home/sdn5g/5g-sdn/ueransim-run
CFG_DIR=/home/sdn5g/5g-sdn/docker-open5gs/configs/basic
cp -a "${CFG_DIR}.bak-fase1/amf.yaml" "$CFG_DIR/amf.yaml"
cp -a "${CFG_DIR}.bak-fase1/upf.yaml" "$CFG_DIR/upf.yaml"
cp -a "$RAN_DIR/configs/gnb.yaml.bak-fase1" "$RAN_DIR/configs/gnb.yaml"
grep -n "address" "$CFG_DIR/amf.yaml" | head -3
sed -n '14p' "$CFG_DIR/upf.yaml"
sed -n '8,13p' "$RAN_DIR/configs/gnb.yaml"
cd "$CORE_DIR" && docker compose up -d
sleep 15
cd "$RAN_DIR" && docker compose up -d
sleep 15
docker logs gnb | tail -3
docker exec ue ip addr show uesimtun0
~/5g-sdn/ovs/measure.sh baseline
sed -i '17s/amf\.open5gs\.org/10.10.1.2/' "$CFG_DIR/amf.yaml"
sed -i '14s/upf\.open5gs\.org/10.10.1.3/' "$CFG_DIR/upf.yaml"
sed -i -e '9s/gnb\.ueransim\.org/10.10.1.10/'        -e '10s/gnb\.ueransim\.org/10.10.1.10/'        -e '13s/amf\.open5gs\.org/10.10.1.2/' "$RAN_DIR/configs/gnb.yaml"
cat > ~/5g-sdn/ovs/cfg-ovs.sh <<'EOF'
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
EOF

chmod +x ~/5g-sdn/ovs/cfg-ovs.sh
~/5g-sdn/ovs/cfg-ovs.sh off
docker inspect amf --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}'
docker inspect amf --format '{{ index .Config.Labels "com.docker.compose.project.config_files" }}'
docker inspect amf --format '{{ index .Config.Labels "com.docker.compose.project.environment_file" }}'
ls -a ~/5g-sdn/docker-open5gs | head -30
ls -a "$CORE_DIR"
cd "$CORE_DIR"
docker compose --env-file ~/5g-sdn/docker-open5gs/.env up -d
sleep 20
docker ps --format 'table {{.Names}}\t{{.Status}}'
docker restart gnb ue
sleep 15
docker exec ue ip addr show uesimtun0
~/5g-sdn/ovs/measure.sh baseline
ls -a
docker ps
CORE_DIR=/home/sdn5g/5g-sdn/docker-open5gs/compose-files/basic
RAN_DIR=/home/sdn5g/5g-sdn/ueransim-run
ENVF=/home/sdn5g/5g-sdn/docker-open5gs/.env
RAN_COMPOSE=$(docker inspect gnb --format '{{ index .Config.Labels "com.docker.compose.project.config_files" }}')
echo "$RAN_COMPOSE"
~/5g-sdn/ovs/cfg-ovs.sh on
cat > "$RAN_DIR/compose.ovs.yaml" <<'EOF'
services:
  gnb:
    sysctls:
      net.ipv4.ip_nonlocal_bind: 1
EOF

cat > ~/5g-sdn/ovs/ovs-attach.sh <<'EOF'
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
EOF

chmod +x ~/5g-sdn/ovs/ovs-attach.sh
cd "$CORE_DIR" && docker compose --env-file "$ENVF" -f docker-compose.yaml -f compose.ovs.yaml config 2>/dev/null | grep -B1 -A2 ip_nonlocal_bind
cd "$RAN_DIR"  && docker compose -f "$RAN_COMPOSE" -f compose.ovs.yaml config 2>/dev/null | grep -B1 -A2 ip_nonlocal_bind
cd "$CORE_DIR"
docker compose --env-file "$ENVF" -f docker-compose.yaml -f compose.ovs.yaml   up -d --force-recreate --no-deps amf upf
sleep 3
~/5g-sdn/ovs/ovs-attach.sh
docker restart smf      # supaya SMF membuat ulang asosiasi PFCP ke UPF baru
sleep 10
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'amf|upf|smf'
docker logs amf | grep ngap_server
docker logs amf | tail -20
echo "$RAN_DIR"
echo "$RAN_COMPOSE"
cd "$RAN_DIR"
docker compose -f "$RAN_COMPOSE" -f compose.ovs.yaml up -d --force-recreate gnb
sleep 2
~/5g-sdn/ovs/ovs-attach.sh
sleep 6
docker logs gnb | tail -8
docker compose -f "$RAN_COMPOSE" up -d --force-recreate ue
sleep 10
docker logs ue | grep -E "Registration|PDU Session|TUN interface"
docker exec ue ip addr show uesimtun0
sudo ovs-vsctl show
docker logs amf | grep -E "gNB-N2 accepted|Number of gNBs" | tail -3
docker exec ue ping -I uesimtun0 -c 4 10.45.0.1
docker exec ue ping -I uesimtun0 -c 4 8.8.8.8
docker logs gnb | tail -8
cd "$RAN_DIR"
docker compose -f "$RAN_COMPOSE" -f compose.ovs.yaml up -d --force-recreate gnb
sleep 2
~/5g-sdn/ovs/ovs-attach.sh
sleep 8
docker logs gnb | tail -5
docker compose -f "$RAN_COMPOSE" -f compose.ovs.yaml up -d --force-recreate --no-deps ue
sleep 10
docker logs ue | grep -E "Registration|PDU Session|TUN interface"
docker exec ue ip addr show uesimtun0
cat > ~/5g-sdn/ovs/ran-up.sh <<'EOF'
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
EOF

chmod +x ~/5g-sdn/ovs/ran-up.sh
sudo ovs-vsctl show
docker exec ue ping -I uesimtun0 -c 4 10.45.0.1
docker exec ue ping -I uesimtun0 -c 4 8.8.8.8
docker pull nicolaka/netshoot
(docker exec ue ping -I uesimtun0 -c 20 -i 0.5 10.45.0.1 >/dev/null &)
docker run --rm --network container:upf nicolaka/netshoot tcpdump -ni eth1 udp port 2152 -c 8
sudo ovs-ofctl dump-ports br-ran
sudo ovs-appctl fdb/show br-ran
sudo ovs-ofctl dump-flows br-ran
BR_OGS=$(docker network inspect open5gs -f '{{index .Options "com.docker.network.bridge.name"}}')
[ -z "$BR_OGS" ] && BR_OGS=br-$(docker network inspect open5gs -f '{{.Id}}' | cut -c1-12)
echo "$BR_OGS"
(docker exec ue ping -I uesimtun0 -c 12 -i 0.5 10.45.0.1 >/dev/null &)
timeout 8 sudo tcpdump -ni "$BR_OGS" 'sctp or udp port 2152' -c 5
cat > ~/5g-sdn/ovs/core-up.sh <<'EOF'

#!/usr/bin/env bash
CORE_DIR=/home/sdn5g/5g-sdn/docker-open5gs/compose-files/basic
   ENVF=/home/sdn5g/5g-sdn/docker-open5gs/.env
   cd "$CORE_DIR"
   docker compose --env-file "$ENVF" -f docker-compose.yaml -f compose.ovs.yaml up -d
   docker compose --env-file "$ENVF" -f docker-compose.yaml -f compose.ovs.yaml \
     up -d --force-recreate --no-deps amf upf
   sleep 3
   ~/5g-sdn/ovs/ovs-attach.sh
   docker restart smf
   sleep 10
   docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'amf|upf|smf'
EOF

uptime -s
for c in amf upf smf gnb ue; do echo -n "$c: "; docker inspect -f 'exit={{.State.ExitCode}} oom={{.State.OOMKilled}} restart={{.HostConfig.RestartPolicy.Name}}' $c; done
nano ~/5g-sdn/ovs/setup-autostart.sh 
sudo bash ~/5g-sdn/ovs/setup-autostart.sh
sudo systemctl start 5g-stack
journalctl -u 5g-stack -n 40 --no-pager
docker exec ue ping -I uesimtun0 -c 3 10.45.0.1
sudo reboot
ls
docker ps
docker container ps -a
ls
cd 5g-sdn
ls
cd controller
ls
cat Dockerfile
docker ps
ls
cd 5g-sdn/
ls
cd controller/
ls
cd .. 
cd /ovs
cd .. 
cd /ovs
cd ovs
ls
cd 5g-sdn/n
cd 5g-sdn/
ls
cd ovs
ls
cat setup-autostart.sh 
