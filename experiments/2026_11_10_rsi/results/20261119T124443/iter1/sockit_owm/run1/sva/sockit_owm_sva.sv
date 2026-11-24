// SVA checker for sockit_owm (1-wire master, Avalon/32-bit bus, default parameters).
// Sources: doc/sockit_owr.pdf (Sections 2-4, Tables 7, 8, 10, 11, 12) and rtl/sockit_owm.v.
// Defaults elaborated: OVD_E=1, CDR_E=1, BDW=32, OWN=1, BTP_N="5.0", BTP_O="1.0".

module sockit_owm_sva #(
  // enable implementation of optional functionality
  parameter OVD_E =    1,
  parameter CDR_E =    1,
  // interface parameters
  parameter BDW   =   32,
  parameter OWN   =    1,
  parameter BAW   =    1,
  // base time period
  parameter BTP_N = "5.0",
  parameter BTP_O = "1.0",
  // normal mode timing
  parameter T_RSTH_N = (BTP_N == "7.5") ?  64 : (BTP_N == "5.0") ?  96 :  80,
  parameter T_RSTL_N = (BTP_N == "7.5") ?  64 : (BTP_N == "5.0") ?  96 :  80,
  parameter T_RSTP_N = (BTP_N == "7.5") ?  10 : (BTP_N == "5.0") ?  15 :  10,
  parameter T_DAT0_N = (BTP_N == "7.5") ?   8 : (BTP_N == "5.0") ?  12 :  10,
  parameter T_DAT1_N = (BTP_N == "7.5") ?   1 : (BTP_N == "5.0") ?   1 :   1,
  parameter T_BITS_N = (BTP_N == "7.5") ?   2 : (BTP_N == "5.0") ?   3 :   2,
  parameter T_RCVR_N = (BTP_N == "7.5") ?   1 : (BTP_N == "5.0") ?   1 :   1,
  parameter T_IDLE_N = (BTP_N == "7.5") ? 128 : (BTP_N == "5.0") ? 200 : 160,
  // overdrive mode timing
  parameter T_RSTH_O = (BTP_O == "1.0") ?  48 :  96,
  parameter T_RSTL_O = (BTP_O == "1.0") ?  48 :  96,
  parameter T_RSTP_O = (BTP_O == "1.0") ?  10 :  15,
  parameter T_DAT0_O = (BTP_O == "1.0") ?   6 :  12,
  parameter T_DAT1_O = (BTP_O == "1.0") ?   1 :   2,
  parameter T_BITS_O = (BTP_O == "1.0") ?   2 :   3,
  parameter T_RCVR_O = (BTP_O == "1.0") ?   2 :   4,
  parameter T_IDLE_O = (BTP_O == "1.0") ?  96 : 192,
  // clock divider ratios
  parameter CDR_N = 5-1,
  parameter CDR_O = 1-1,
  // widths of internal counters and the line select (same formulas as the RTL)
  parameter SDW = $clog2(OWN),
  parameter CDW = CDR_E ? ((BDW==32) ? 16 : 8) : $clog2(CDR_N),
  parameter TDW = ((T_RSTH_O+T_RSTL_O) > (T_RSTH_N+T_RSTL_N))
                ? $clog2(T_RSTH_O+T_RSTL_O) : $clog2(T_RSTH_N+T_RSTL_N)
)(
  input logic                clk,
  input logic                rst,        // active high, asynchronous (RTL: posedge rst)
  // CPU bus
  input logic                bus_ren,
  input logic                bus_wen,
  input logic [BAW-1:0]      bus_adr,
  input logic [BDW-1:0]      bus_wdt,
  input logic [BDW-1:0]      bus_rdt,
  input logic                bus_irq,
  // 1-wire pins
  input logic [OWN-1:0]      owr_p,
  input logic [OWN-1:0]      owr_e,
  input logic [OWN-1:0]      owr_i,
  // internal state of sockit_owm
  input logic [CDW-1:0]      div,
  input logic [CDW-1:0]      cdr_n,
  input logic [CDW-1:0]      cdr_o,
  input logic                pls,
  input logic                owr_cyc,
  input logic [TDW-1:0]      cnt,
  input logic [SDW-1:0]      owr_sel,    // no reset in RTL (initial block only): checks below guard on owr_sel==0
  input logic [OWN-1:0]      owr_pwr,
  input logic                owr_ovd,
  input logic                owr_rst,
  input logic                owr_dat,
  input logic                owr_smp,
  input logic                owr_oen,
  input logic                irq_ena,
  input logic                irq_sts
);

  default clocking cb @(posedge clk); endclocking
  default disable iff (rst);

  // ---------------------------------------------------------------------------
  // derived constants and event points (same arithmetic as the RTL)
  // cnt counts down from (slot length - 1) to 0; an event fires when cnt equals
  // the value below for the currently latched mode (owr_ovd).
  // ---------------------------------------------------------------------------
  localparam int RST_N = T_RSTL_N + T_RSTH_N;   // reset cycle length, normal mode (base periods)
  localparam int RST_O = T_RSTL_O + T_RSTH_O;   // reset cycle length, overdrive
  localparam int BIT_N = T_DAT0_N + T_RCVR_N;   // write/read slot length, normal
  localparam int BIT_O = T_DAT0_O + T_RCVR_O;   // write/read slot length, overdrive
  localparam int IDL_N = T_IDLE_N;              // timed idle cycle length, normal

  wire [TDW-1:0] c_rel_rst = owr_ovd ? T_RSTH_O : T_RSTH_N;                                   // reset low ends
  wire [TDW-1:0] c_smp_rst = owr_ovd ? (T_RSTH_O - T_RSTP_O) : (T_RSTH_N - T_RSTP_N);         // presence sample
  wire [TDW-1:0] c_rel_w1  = owr_ovd ? (T_DAT0_O - T_DAT1_O + T_RCVR_O)
                                     : (T_DAT0_N - T_DAT1_N + T_RCVR_N);                     // write-1 low ends
  wire [TDW-1:0] c_rel_w0  = owr_ovd ? T_RCVR_O : T_RCVR_N;                                   // write-0 low ends
  wire [TDW-1:0] c_smp_bit = owr_ovd ? (T_DAT0_O - T_BITS_O + T_RCVR_O)
                                     : (T_DAT0_N - T_BITS_N + T_RCVR_N);                     // data bit sample

  // bus decode (32-bit bus: adr[0]==0 is control/status, adr[0]==1 is the divider registers)
  wire ctl_wr  = bus_wen & ~bus_adr[0];
  wire ctl_rd  = bus_ren & ~bus_adr[0];
  wire cdr_wr  = bus_wen &  bus_adr[0];
  wire zero_wr = ctl_wr & (bus_wdt[2:0] == 3'b111);     // ovd=1,rst=1,dat=1: zero-time idle write
  // counter reaches zero on a base pulse; end of an *active* cycle
  wire end_pls = pls & (cnt == 0);
  wire cyc_end = owr_cyc & end_pls;

  // ---------------------------------------------------------------------------
  // reset values (first cycle after reset is released)
  // ---------------------------------------------------------------------------

  // doc Table 10 reset column (ien=0, irq=0, pwr=0, cyc=0, ovd=0, rst=0); RTL resets dat to 0
  // RTL: reset branches of control/status flops
  a_rst_ctl_bits: assert property ($fell(rst) |-> (!irq_ena && !irq_sts && (owr_pwr == 0) &&
                                                   !owr_cyc && !owr_ovd && !owr_rst && !owr_dat));

  // RTL: counter and divider reset to zero
  a_rst_cnt_div: assert property ($fell(rst) |-> (cnt == 0 && div == 0));

  // doc 4.3: after reset all power bits are zero and no line is driven; RTL: owr_oen reset to 0
  a_rst_line_off: assert property ($fell(rst) |-> (owr_e == 0 && owr_p == 0 && !bus_irq));

  // doc 4.2: after reset the divider registers hold CDR_N / CDR_O
  generate if (BDW==32 && CDR_E) begin : g_cdr
    a_rst_cdr: assert property ($fell(rst) |-> (cdr_n == CDR_N && cdr_o == CDR_O));
  end endgenerate

  // ---------------------------------------------------------------------------
  // register read-back (doc Table 10/11: r/w fields; read data reflects written values)
  // ---------------------------------------------------------------------------

  // doc Table 10: ien is r/w; a read after a write returns the written value
  a_rb_ien: assert property (ctl_wr ##1 ctl_rd |-> bus_rdt[7] == $past(bus_wdt[7]));

  // doc Table 10: ovd is r/w
  a_rb_ovd: assert property (ctl_wr ##1 ctl_rd |-> bus_rdt[2] == $past(bus_wdt[2]));

  // doc Table 10: rst is r/w
  a_rb_rst: assert property (ctl_wr ##1 ctl_rd |-> bus_rdt[1] == $past(bus_wdt[1]));

  // doc Table 10/11: dat is r/w; the write is not overwritten by a cycle end one cycle later
  a_rb_dat: assert property (ctl_wr ##1 ctl_rd |-> bus_rdt[0] == $past(bus_wdt[0]));

  // doc Table 10/12: writing cyc=1 starts a cycle that reads back as active,
  // except the zero-time idle code (ovd=rst=dat=1) which never starts one
  a_rb_cyc: assert property (ctl_wr ##1 ctl_rd |->
                             bus_rdt[3] == ($past(bus_wdt[3]) && ($past(bus_wdt[2:0]) != 3'b111)));

  // doc Table 10: cyc read gives the 1-wire cycle status (used for polling)
  a_rb_cyc_status: assert property (ctl_rd |-> bus_rdt[3] == owr_cyc);

  // doc Table 10: bit 5 is reserved (reads as 0 in RTL)
  a_rb_reserved: assert property (ctl_rd |-> !bus_rdt[5]);

  // doc 4.1 / Table 8: the divider registers read back what was written (32-bit bus)
  generate if (BDW==32 && CDR_E) begin : g_cdr_rb
    a_rb_cdr_n: assert property (cdr_wr ##1 (bus_ren && bus_adr[0]) |-> bus_rdt[15:0] == $past(bus_wdt[15:0]));
    a_rb_cdr_o: assert property (cdr_wr ##1 (bus_ren && bus_adr[0]) |-> bus_rdt[31:16] == $past(bus_wdt[31:16]));
  end endgenerate

  // doc 4.3 (OWN=1): the pwr bit lives in control bit 4 and reads back the power state
  // RTL: 1-line build has no separate power/select register, bits 31:8 read as zero
  generate if (BDW==32 && OWN==1) begin : g_own1
    a_rb_pwr: assert property (ctl_wr ##1 ctl_rd |-> bus_rdt[4] == $past(bus_wdt[4]));

    // RTL: unimplemented power[15:0] / select bits of the 32-bit word read as zero for OWN=1
    a_rd_unimpl: assert property (ctl_rd |-> bus_rdt[31:8] == 0);

    // doc 4.3: pwr bit drives the power output
    a_pwr_out: assert property (ctl_wr |=> owr_p[0] == $past(bus_wdt[4]));

    // doc 4.3: power changes only through a control write
    a_pwr_hold: assert property (!ctl_wr |=> $stable(owr_pwr));

    // doc 4.3: "while power to a line is enabled it is not possible to perform 1-wire cycles
    // on the same line"; timed idle cycles are excluded because the doc intends them for power
    // delivery. DOC/RTL DISAGREEMENT: RTL does not gate cycle start on the power bit.
    a_doc_pwr_no_cycle: assert property (owr_pwr[0] && ctl_wr && bus_wdt[4] && bus_wdt[3] &&
                                         (bus_wdt[1:0] != 2'b11) |=> !owr_cyc);

    // doc 4.3 / RTL owr_e = owr_oen << owr_sel: with the line selected (owr_sel==0) the
    // open-collector enable is the cycle output register. Guarded because owr_sel has no reset.
    a_out_e: assert property ((owr_sel == 0) |-> owr_e[0] == owr_oen);
  end endgenerate

  // ---------------------------------------------------------------------------
  // side effects of bus accesses
  // ---------------------------------------------------------------------------

  // RTL: a divider register write does not touch the control/status state, except
  // for a cycle end on the same clock (not expressible with !pls)
  generate if (BDW==32 && CDR_E) begin : g_cdr_se
    a_cdr_wr_ctl_hold: assert property (cdr_wr && !pls |=>
        $stable(irq_ena) && $stable(owr_pwr) && $stable(owr_ovd) && $stable(owr_rst) &&
        $stable(owr_dat) && $stable(owr_cyc) && $stable(owr_oen) && $stable(irq_sts));

    // RTL: the counter is only changed by a control write or a base pulse
    a_cdr_wr_cnt_hold: assert property (cdr_wr && !pls |=> $stable(cnt));

    // RTL: writes to the control register do not change the divider ratios
    a_ctl_wr_cdr_hold: assert property (ctl_wr |=> $stable(cdr_n) && $stable(cdr_o));
  end endgenerate

  // RTL: any bus write restarts the clock divider
  a_wr_restarts_div: assert property (bus_wen |=> div == 0);

  // RTL: the counter moves only on a base pulse or a control write
  a_cnt_pulse_only: assert property (!pls && !ctl_wr |=> $stable(cnt));

  // RTL: a read has no side effect other than clearing irq (checked in the interrupt section)
  a_rd_no_side_effect: assert property (ctl_rd && !ctl_wr && !end_pls |=>
        $stable(owr_cyc) && $stable(owr_ovd) && $stable(owr_rst) && $stable(owr_dat) && $stable(irq_ena));

  // ---------------------------------------------------------------------------
  // cycle control (doc 4.4, Table 12; RTL cnt/owr_cyc logic)
  // ---------------------------------------------------------------------------

  // doc 4.4 (cyc): the cycle starts only with a control write
  a_cyc_rise_on_wr: assert property ($rose(owr_cyc) |-> $past(ctl_wr));

  // RTL: the cycle is cleared only by the end of the counter or by a control write
  a_cyc_fall_on_end: assert property ($fell(owr_cyc) |-> ($past(cyc_end) || $past(ctl_wr)));

  // RTL: an active cycle keeps running until its counter reaches zero
  a_cyc_hold: assert property (owr_cyc && !cyc_end && !ctl_wr |=> owr_cyc);

  // doc 4.4: writing cyc=1 while a cycle is in progress breaks it and starts a new one
  a_cyc_restart: assert property (owr_cyc && ctl_wr && bus_wdt[3] && (bus_wdt[2:0] != 3'b111) |=> owr_cyc);

  // DOC/RTL DISAGREEMENT: doc 4.4 says cyc=0 means "no action" on a write; RTL clears owr_cyc
  // on any control write with cyc=0, aborting a running cycle.
  a_doc_cyc0_no_action: assert property (owr_cyc && ctl_wr && !bus_wdt[3] |=> owr_cyc);

  // doc Table 12: a non-idle cycle (rst/dat not both 1) starts with the line pulled low
  a_start_pulls_low: assert property (ctl_wr && bus_wdt[3] && (bus_wdt[1:0] != 2'b11) |=> owr_oen);

  // doc Table 12 / 4.5 timed idle: the line is not driven during an idle cycle
  a_start_idle_rel: assert property (ctl_wr && bus_wdt[3] && (bus_wdt[1:0] == 2'b11) |=> !owr_oen);

  // doc Table 12: zero-time idle (ovd=1,rst=1,dat=1) gives 0 us, i.e. no cycle at all
  a_zero_no_cycle: assert property (zero_wr |=> !owr_cyc);

  // DOC/RTL DISAGREEMENT (designer intent): the line is driven only during a 1-wire cycle.
  // RTL: a control write with cyc=0 and dat=0 sets owr_oen (pulls the line low) with no cycle running.
  a_idle_line_off: assert property (!owr_cyc |-> !owr_oen);

  // doc Table 12 cycle lengths: counter loads (slot length - 1), normal and overdrive
  a_cnt_load_idle_n: assert property (ctl_wr && bus_wdt[3] && (bus_wdt[2:0] == 3'b011) |=> cnt == IDL_N - 1);
  a_cnt_load_rst_n:  assert property (ctl_wr && bus_wdt[3] && (bus_wdt[2:0] == 3'b010) |=> cnt == RST_N - 1);
  a_cnt_load_bit_n:  assert property (ctl_wr && bus_wdt[3] && (bus_wdt[2:1] == 2'b00) |=> cnt == BIT_N - 1);
  a_cnt_load_rst_o:  assert property (ctl_wr && bus_wdt[3] && (bus_wdt[2:0] == 3'b110) |=> cnt == RST_O - 1);
  a_cnt_load_bit_o:  assert property (ctl_wr && bus_wdt[3] && (bus_wdt[2:1] == 2'b10) |=> cnt == BIT_O - 1);

  // RTL: the counter decrements once per base pulse while a cycle runs
  a_cnt_dec: assert property (owr_cyc && pls && (cnt != 0) && !ctl_wr |=> cnt == $past(cnt) - 1);

  // DOC/RTL DISAGREEMENT (designer intent): with CDR_O=0 (the RTL default) in overdrive mode the
  // pulse is high on every clock, so the counter keeps running while no cycle is active.
  a_idle_cnt_hold: assert property (!owr_cyc && !ctl_wr |=> $stable(cnt));

  // ---------------------------------------------------------------------------
  // clock divider (doc 2.1.3 and 4.2; RTL div/pls logic)
  // ---------------------------------------------------------------------------

  // RTL: the divider is zero whenever no cycle is running
  a_div_idle_zero: assert property (!owr_cyc |-> div == 0);

  // RTL: the divider never exceeds the divisor of the active mode (cdr_o for overdrive, cdr_n for normal)
  a_div_bounded: assert property (owr_cyc && !bus_wen |-> div <= (owr_ovd ? cdr_o : cdr_n));

  // RTL: while a cycle runs the divider counts one step per clock between base pulses
  a_div_count: assert property (owr_cyc && !bus_wen && !pls |=> div == $past(div) + 1);

  // RTL: a base pulse restarts the divider
  a_div_pulse_restart: assert property (owr_cyc && !bus_wen && pls |=> div == 0);

  // RTL: the base pulse comes when the divider reaches the mode's divisor
  a_pls_at_divisor: assert property (owr_cyc && !bus_wen && (div == (owr_ovd ? cdr_o : cdr_n)) |-> pls);

  // DOC/RTL DISAGREEMENT (designer intent): no base pulses while idle. Fails with the RTL default
  // CDR_O=0 once overdrive mode has been selected (see a_idle_cnt_hold).
  a_idle_no_pulse: assert property (!owr_cyc |-> !pls);

  // ---------------------------------------------------------------------------
  // line release points (doc Drawings 5-7, Table 7; RTL owr_oen logic)
  // ---------------------------------------------------------------------------

  // RTL/doc 4.5: every cycle ends with the line released (recovery)
  a_cyc_end_released: assert property (cyc_end && !ctl_wr |-> !owr_oen);

  // doc Table 7: reset low for T_RSTL base periods, then released (cnt == release count)
  a_rst_rel_point: assert property (owr_cyc && owr_rst && pls && (cnt == c_rel_rst) && !ctl_wr |=> !owr_oen);

  // doc Table 7 tDAT1: write-1 / read slot is low for T_DAT1 base periods
  a_w1_rel_point: assert property (owr_cyc && !owr_rst && owr_dat && pls && (cnt == c_rel_w1) && !ctl_wr |=> !owr_oen);

  // doc Table 7 tDAT0: write-0 slot is low for T_DAT0 base periods, then released (recovery)
  a_w0_rel_point: assert property (owr_cyc && !owr_rst && !owr_dat && pls && (cnt == c_rel_w0) && !ctl_wr |=> !owr_oen);

  // doc Drawing 7 / Table 7: the read slot is sampled after the master has released the line
  a_rd_smp_released: assert property (owr_cyc && !owr_rst && owr_dat && pls && (cnt == c_smp_bit) && !ctl_wr |-> !owr_oen);

  // doc 4.5 / Drawing 4: presence is sampled after the reset low time, while the line is released
  a_rst_smp_released: assert property (owr_cyc && owr_rst && pls && (cnt == c_smp_rst) && !ctl_wr |-> !owr_oen);

  // ---------------------------------------------------------------------------
  // sampling and result (doc 2.3, 4.4 bit 0; RTL owr_smp / owr_dat)
  // ---------------------------------------------------------------------------

  generate if (OWN==1) begin : g_smp
    // doc 2.3: the sampled register only changes on base pulses
    a_smp_hold_nopls: assert property (!pls |=> $stable(owr_smp));

    // RTL: the sample register changes only at its sampling points
    a_smp_hold_nonpoint: assert property (pls && !(owr_rst && (cnt == c_smp_rst)) &&
                                          !(!owr_rst && (cnt == c_smp_bit)) |=> $stable(owr_smp));

    // doc 2.3 / 4.4: the presence sample is the line value at the presence point (selected line, owr_sel==0)
    a_smp_rst: assert property (pls && owr_rst && (cnt == c_smp_rst) && (owr_sel == 0) |=>
                                owr_smp == $past(owr_i[0]));

    // doc 2.3 / 4.4: the data sample is the line value at the sampling point (selected line, owr_sel==0)
    a_smp_bit: assert property (pls && !owr_rst && (cnt == c_smp_bit) && (owr_sel == 0) |=>
                                owr_smp == $past(owr_i[0]));
  end endgenerate

  // doc 4.4 (dat read): at cycle end the dat bit holds the sample (read result / presence)
  a_dat_from_smp: assert property (cyc_end && !ctl_wr |=> owr_dat == $past(owr_smp));

  // ---------------------------------------------------------------------------
  // interrupt (doc 4.4 irq/ien, 2.2.1; RTL irq_sts logic)
  // ---------------------------------------------------------------------------

  // RTL: irq is set only at the end of an active cycle
  a_irq_rise_at_end: assert property ($rose(irq_sts) |-> $past(cyc_end));

  // doc Table 10 / 4.4: irq is set at the end of each 1-wire cycle
  a_irq_set_at_end: assert property (cyc_end && !ctl_wr |=> irq_sts);

  // RTL priority: a cycle end sets irq even when the status register is read in the same cycle
  a_irq_set_vs_read: assert property (cyc_end && ctl_rd && !ctl_wr |=> irq_sts);

  // doc Table 10 / 4.4: irq is cleared by a read of the register
  a_irq_read_clear: assert property (irq_sts && ctl_rd && !ctl_wr && !end_pls |=> !irq_sts);

  // doc 4.4: irq stays set until it is read
  a_irq_hold: assert property (irq_sts && !ctl_rd && !ctl_wr && !end_pls |=> irq_sts);

  // doc 4.4: the read returns the current irq status
  a_irq_read_val: assert property (ctl_rd |-> bus_rdt[6] == irq_sts);

  // DOC/RTL DISAGREEMENT: doc Table 10 marks irq as r/c and says it is cleared by a register read,
  // but RTL also clears it on a control write.
  a_doc_irq_wr_no_clear: assert property (irq_sts && ctl_wr && !end_pls |=> irq_sts);

  // doc 4.4 / 2.2.1: the interrupt output is gated by ien and the pending status
  a_irq_bus_off: assert property (!irq_ena |-> !bus_irq);
  a_irq_bus_on:  assert property (irq_ena && irq_sts |-> bus_irq);

endmodule

bind sockit_owm sockit_owm_sva #(
  .OVD_E(OVD_E), .CDR_E(CDR_E), .BDW(BDW), .OWN(OWN), .BAW(BAW),
  .BTP_N(BTP_N), .BTP_O(BTP_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_RSTP_N(T_RSTP_N), .T_DAT0_N(T_DAT0_N),
  .T_DAT1_N(T_DAT1_N), .T_BITS_N(T_BITS_N), .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_RSTP_O(T_RSTP_O), .T_DAT0_O(T_DAT0_O),
  .T_DAT1_O(T_DAT1_O), .T_BITS_O(T_BITS_O), .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O),
  .CDR_N(CDR_N), .CDR_O(CDR_O)
) u_sockit_owm_sva (.*);
