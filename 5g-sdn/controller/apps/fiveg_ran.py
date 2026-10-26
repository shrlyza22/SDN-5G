"""Controller 5G untuk OVS br-ran (N2 + N3). OpenFlow 1.3 / Ryu."""
import os
import time

from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import (CONFIG_DISPATCHER, MAIN_DISPATCHER,
                                    DEAD_DISPATCHER, set_ev_cls)
from ryu.lib import hub
from ryu.lib.packet import packet, ethernet, ipv4, udp, ether_types, in_proto
from ryu.ofproto import ofproto_v1_3

AMF_IP = os.environ.get("AMF_IP", "10.10.1.2")
UPF_IP = os.environ.get("UPF_IP", "10.10.1.3")
ALLOWED_GNB = set(os.environ.get("ALLOWED_GNB", "10.10.1.10").split(","))
N3_PORT = 2152
N3_RATE_KBPS = int(os.environ.get("N3_RATE_KBPS", "0"))   # 0 = tanpa meter
STATS_INTERVAL = int(os.environ.get("STATS_INTERVAL", "10"))
IDLE_TIMEOUT = 30

C_L2, C_N2, C_N3, C_DROP = 0x1, 0x2, 0x3, 0x9
NAMES = {C_L2: "L2", C_N2: "N2", C_N3: "N3", C_DROP: "DROP"}
P_L2, P_5G, P_DROP = 1, 10, 20
METER_ID = 1


class FiveGRan(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(FiveGRan, self).__init__(*args, **kwargs)
        self.mac_to_port = {}
        self.datapaths = {}
        self.prev = {}
        self.logger.info("FiveGRan: AMF=%s UPF=%s gNB diizinkan=%s N3 rate=%s kbps",
                         AMF_IP, UPF_IP, sorted(ALLOWED_GNB), N3_RATE_KBPS)
        hub.spawn(self._monitor)

    # ---------- util ----------
    def _add_flow(self, dp, priority, match, actions, cookie=0, idle=0, meter=False):
        ofp, parser = dp.ofproto, dp.ofproto_parser
        inst = []
        if meter and N3_RATE_KBPS > 0:
            inst.append(parser.OFPInstructionMeter(METER_ID))
        if actions:
            inst.append(parser.OFPInstructionActions(ofp.OFPIT_APPLY_ACTIONS, actions))
        dp.send_msg(parser.OFPFlowMod(datapath=dp, cookie=cookie, priority=priority,
                                      match=match, instructions=inst,
                                      idle_timeout=idle))

    def _reset(self, dp):
        """Hapus semua flow, pasang meter (jika perlu) dan table-miss."""
        ofp, parser = dp.ofproto, dp.ofproto_parser
        self.mac_to_port.pop(dp.id, None)
        dp.send_msg(parser.OFPFlowMod(datapath=dp, table_id=ofp.OFPTT_ALL,
                                      command=ofp.OFPFC_DELETE,
                                      out_port=ofp.OFPP_ANY, out_group=ofp.OFPG_ANY,
                                      match=parser.OFPMatch()))
        if N3_RATE_KBPS > 0:
            dp.send_msg(parser.OFPMeterMod(datapath=dp, command=ofp.OFPMC_DELETE,
                                           flags=ofp.OFPMF_KBPS, meter_id=METER_ID))
            burst = max(N3_RATE_KBPS // 10, 1000)
            band = parser.OFPMeterBandDrop(rate=N3_RATE_KBPS, burst_size=burst)
            dp.send_msg(parser.OFPMeterMod(datapath=dp, command=ofp.OFPMC_ADD,
                                           flags=ofp.OFPMF_KBPS, meter_id=METER_ID,
                                           bands=[band]))
        miss = [parser.OFPActionOutput(ofp.OFPP_CONTROLLER, ofp.OFPCML_NO_BUFFER)]
        self._add_flow(dp, 0, parser.OFPMatch(), miss)

    # ---------- event OpenFlow ----------
    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def _features(self, ev):
        self._reset(ev.msg.datapath)

    @set_ev_cls(ofp_event.EventOFPStateChange, [MAIN_DISPATCHER, DEAD_DISPATCHER])
    def _state_change(self, ev):
        dp = ev.datapath
        if ev.state == MAIN_DISPATCHER:
            self.datapaths[dp.id] = dp
            self.logger.info("switch terhubung: dpid=%016x", dp.id)
        elif dp.id in self.datapaths:
            del self.datapaths[dp.id]
            self.logger.info("switch terputus: dpid=%016x", dp.id)

    @set_ev_cls(ofp_event.EventOFPPortStatus, MAIN_DISPATCHER)
    def _port_status(self, ev):
        self.logger.info("port berubah (reason=%s) -> reset flow", ev.msg.reason)
        self._reset(ev.msg.datapath)

    @set_ev_cls(ofp_event.EventOFPErrorMsg, [CONFIG_DISPATCHER, MAIN_DISPATCHER])
    def _error(self, ev):
        self.logger.warning("OpenFlow error type=0x%02x code=0x%02x",
                            ev.msg.type, ev.msg.code)

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def _packet_in(self, ev):
        msg = ev.msg
        dp = msg.datapath
        ofp, parser = dp.ofproto, dp.ofproto_parser
        in_port = msg.match["in_port"]
        pkt = packet.Packet(msg.data)
        eth = pkt.get_protocols(ethernet.ethernet)[0]
        if eth.ethertype == ether_types.ETH_TYPE_LLDP:
            return
        ip = pkt.get_protocol(ipv4.ipv4)

        # ACL N2: hanya gNB yang diizinkan boleh berbicara SCTP ke AMF
        if (ip and ip.proto == in_proto.IPPROTO_SCTP
                and ip.dst == AMF_IP and ip.src not in ALLOWED_GNB):
            self.logger.warning("DROP N2 dari sumber tak dikenal %s (port %s)",
                                ip.src, in_port)
            match = parser.OFPMatch(eth_type=0x0800, ip_proto=in_proto.IPPROTO_SCTP,
                                    ipv4_src=ip.src, ipv4_dst=AMF_IP)
            self._add_flow(dp, P_DROP, match, [], cookie=C_DROP, idle=IDLE_TIMEOUT)
            return

        # learning L2
        self.mac_to_port.setdefault(dp.id, {})[eth.src] = in_port
        out_port = self.mac_to_port[dp.id].get(eth.dst, ofp.OFPP_FLOOD)
        actions = [parser.OFPActionOutput(out_port)]

        if out_port != ofp.OFPP_FLOOD:
            u = pkt.get_protocol(udp.udp)
            if ip and ip.proto == in_proto.IPPROTO_SCTP:
                match = parser.OFPMatch(in_port=in_port, eth_type=0x0800,
                                        ip_proto=in_proto.IPPROTO_SCTP,
                                        ipv4_src=ip.src, ipv4_dst=ip.dst)
                self._add_flow(dp, P_5G, match, actions, cookie=C_N2, idle=IDLE_TIMEOUT)
            elif ip and u and u.dst_port == N3_PORT:
                match = parser.OFPMatch(in_port=in_port, eth_type=0x0800,
                                        ip_proto=in_proto.IPPROTO_UDP,
                                        ipv4_src=ip.src, ipv4_dst=ip.dst,
                                        udp_dst=N3_PORT)
                self._add_flow(dp, P_5G, match, actions, cookie=C_N3,
                               idle=IDLE_TIMEOUT, meter=True)
            else:
                match = parser.OFPMatch(in_port=in_port, eth_dst=eth.dst, eth_src=eth.src)
                self._add_flow(dp, P_L2, match, actions, cookie=C_L2, idle=IDLE_TIMEOUT)

        data = msg.data if msg.buffer_id == ofp.OFP_NO_BUFFER else None
        dp.send_msg(parser.OFPPacketOut(datapath=dp, buffer_id=msg.buffer_id,
                                        in_port=in_port, actions=actions, data=data))

    # ---------- monitoring ----------
    def _monitor(self):
        while True:
            for dp in list(self.datapaths.values()):
                parser, ofp = dp.ofproto_parser, dp.ofproto
                dp.send_msg(parser.OFPFlowStatsRequest(dp))
                dp.send_msg(parser.OFPPortStatsRequest(dp, 0, ofp.OFPP_ANY))
            hub.sleep(STATS_INTERVAL)

    @set_ev_cls(ofp_event.EventOFPFlowStatsReply, MAIN_DISPATCHER)
    def _flow_stats(self, ev):
        dpid = ev.msg.datapath.id
        now = time.time()
        tot = {}
        for st in ev.msg.body:
            if st.priority == 0:
                continue
            t = tot.setdefault(st.cookie, [0, 0])
            t[0] += st.packet_count
            t[1] += st.byte_count
        parts = []
        for ck in sorted(tot):
            pk, by = tot[ck]
            key = ("f", dpid, ck)
            old = self.prev.get(key)
            self.prev[key] = (pk, by, now)
            if old and by >= old[1] and now > old[2]:
                dt = now - old[2]
                parts.append("%s=%.2f Mbit/s %d pkt/s" % (
                    NAMES.get(ck, hex(ck)), (by - old[1]) * 8 / dt / 1e6,
                    (pk - old[0]) / dt))
        if parts:
            self.logger.info("[FLOW] " + " | ".join(parts))

    @set_ev_cls(ofp_event.EventOFPPortStatsReply, MAIN_DISPATCHER)
    def _port_stats(self, ev):
        dpid = ev.msg.datapath.id
        now = time.time()
        parts = []
        for st in sorted(ev.msg.body, key=lambda s: s.port_no):
            if st.port_no > 0xffffff00:      # port LOCAL
                continue
            key = ("p", dpid, st.port_no)
            old = self.prev.get(key)
            self.prev[key] = (st.rx_bytes, st.tx_bytes, now)
            if old and now > old[2]:
                dt = now - old[2]
                rx = (st.rx_bytes - old[0]) * 8 / dt / 1e6
                tx = (st.tx_bytes - old[1]) * 8 / dt / 1e6
                if rx < 0 or tx < 0:
                    continue
                if rx >= 0.01 or tx >= 0.01:
                    parts.append("port%d rx=%.2f tx=%.2f" % (st.port_no, rx, tx))
        if parts:
            self.logger.info("[PORT Mbit/s] " + " | ".join(parts))
