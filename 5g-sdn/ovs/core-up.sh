
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
