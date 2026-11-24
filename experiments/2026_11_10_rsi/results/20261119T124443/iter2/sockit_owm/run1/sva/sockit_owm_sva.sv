// SVA checker for sockit_owm (1-wire master).
// Specifies the default elaboration: BDW=32, OWN=1, OVD_E=1, CDR_E=1,
// BTP_N="5.0", BTP_O="1.0". Checks that depend on the bus width, line count,
// overdrive or clock-divider configuration are generated only for that case.

`define SVA_CK @(posedge clk) disable iff (rst)

module sockit_owm_sva #(
  parameter OVD_E =    1,
  parameter CDR_E =    1,
  parameter BDW   =   32,
  parameter OWN   =    1,
  parameter BAW   =    1,
  parameter BTP_N = "5.0",
  parameter BTP_O = "1.0",
  parameter T_RSTH_N = (BTP_N == "7.5") ?  64 : (BTP_N == "5.0") ?  96 :  80,
  parameter T_RSTL_N = (BTP_N == "7.5") ?  64 : (BTP_N == "5.0") ?  96 :  80,
  parameter T_RSTP_N = (BTP_N == "7.5") ?  10 : (BTP_N == "5.0") ?  15 :  10,
  parameter T_DAT0_N = (BTP_N == "7.5") ?   8 : (BTP_N == "5.0") ?  12 :  10,
  parameter T_DAT1_N = (BTP_N == "7.5") ?   1 : (BTP_N == "5.0") ?   1 :   1,
  parameter T_BITS_N = (BTP_N == "7.5") ?   2 : (BTP_N == "5.0") ?   3 :   2,
  parameter T_RCVR_N = (BTP_N == "7.5") ?   1 : (BTP_N == "5.0") ?   1 :   1,
  parameter T_IDLE_N = (BTP_N == "7.5") ? 128 : (BTP_N == "5.0") ? 200 : 160,
  parameter T_RSTH_O = (BTP_O == "1.0") ?  48 :  96,
  parameter T_RSTL_O = (BTP_O == "1.0") ?  48 :  96,
  parameter T_RSTP_O = (BTP_O == "1.0") ?  10 :  15,
  parameter T_DAT0_O = (BTP_O == "1.0") ?   6 :  12,
  parameter T_DAT1_O = (BTP_O == "1.0") ?   1 :   2,
  parameter T_BITS_O = (BTP_O == "1.0") ?   2 :   3,
  parameter T_RCVR_O = (BTP_O == "1.0") ?   2 :   4,
  parameter T_IDLE_O = (BTP_O == "1.0") ?  96 : 192,
  parameter CDR_N = 5-1,
  parameter CDR_O = 1-1,
  // derived widths, identical to sockit_owm
  parameter CDW = CDR_E ? ((BDW==32) ? 16 : 8) : $clog2(CDR_N),
  parameter TDW = ((T_RSTH_O+T_RSTL_O) > (T_RSTH_N+T_RSTL_N))
                ? $clog2(T_RSTH_O+T_RSTL_O) : $clog2(T_RSTH_N+T_RSTL_N),
  parameter SDW = $clog2(OWN)
)(
  input logic                clk,
  input logic                rst,
  input logic                bus_ren,
  input logic                bus_wen,
  input logic [BAW-1:0]      bus_adr,
  input logic [BDW-1:0]      bus_wdt,
  input logic [BDW-1:0]      bus_rdt,
  input logic                bus_irq,
  input logic [OWN-1:0]      owr_p,
  input logic [OWN-1:0]      owr_e,
  input logic [OWN-1:0]      owr_i,
  input logic [CDW-1:0]      div,
  input logic [CDW-1:0]      cdr_n,
  input logic [CDW-1:0]      cdr_o,
  input logic                pls,
  input logic                owr_cyc,
  input logic [TDW-1:0]      cnt,
  input logic [SDW-1:0]      owr_sel,
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

  generate if (BDW == 32 && OWN == 1) begin : g_cfg

    // bus decode for BDW=32: adr[0]=0 control/status, adr[0]=1 clock dividers
    wire wen_ctl = bus_wen & ~bus_adr[0];
    wire ren_ctl = bus_ren & ~bus_adr[0];
    wire wen_cdr = bus_wen &  bus_adr[0];
    wire ren_cdr = bus_ren &  bus_adr[0];
    // end of a 1-wire base period with the cycle counter at zero (RTL t_zero)
    wire end_cyc = pls & (cnt == 0);
    // timing points of the current mode (RTL t_dat0, t_dat1, t_bits, t_rsth, t_rstp)
    wire [TDW-1:0] t_rel0 = owr_ovd ? T_RCVR_O : T_RCVR_N;
    wire [TDW-1:0] t_rel1 = owr_ovd ? (T_DAT0_O - T_DAT1_O + T_RCVR_O) : (T_DAT0_N - T_DAT1_N + T_RCVR_N);
    wire [TDW-1:0] t_bits = owr_ovd ? (T_DAT0_O - T_BITS_O + T_RCVR_O) : (T_DAT0_N - T_BITS_N + T_RCVR_N);
    wire [TDW-1:0] t_rsth = owr_ovd ? T_RSTH_O : T_RSTH_N;
    wire [TDW-1:0] t_rstp = owr_ovd ? (T_RSTH_O - T_RSTP_O) : (T_RSTH_N - T_RSTP_N);
    localparam MAXC = (T_IDLE_N > (T_RSTL_N + T_RSTH_N)) ? T_IDLE_N : (T_RSTL_N + T_RSTH_N);

    // ---------------- A. reset values ----------------
    // Table 10, sec 4.3: after reset power is off and all lines are only pulled up
    a01_rst_pwr:     assert property (`SVA_CK $fell(rst) |-> owr_p == '0);
    // Table 10: ien reset 0, so no interrupt request after reset
    a02_rst_ien:     assert property (`SVA_CK $fell(rst) |-> (irq_ena == 1'b0));
    // Table 10: irq status reset 0
    a03_rst_irq:     assert property (`SVA_CK $fell(rst) |-> (irq_sts == 1'b0));
    // Table 10: cyc reset 0, no cycle in progress
    a04_rst_cyc:     assert property (`SVA_CK $fell(rst) |-> !owr_cyc);
    // Table 10: ovd and rst reset 0 (standard speed, data cycle)
    a05_rst_ovd_rst: assert property (`SVA_CK $fell(rst) |-> (!owr_ovd && !owr_rst));
    // RTL reset of dat is 0 (Table 10 lists it as x, so only the RTL value is asserted)
    a06_rst_dat:     assert property (`SVA_CK $fell(rst) |-> !owr_dat);
    // RTL reset of the drive enable: line not pulled down after reset
    a07_rst_oen:     assert property (`SVA_CK $fell(rst) |-> !owr_oen);
    // sec 4.2: clock divider registers reset to the CDR_N / CDR_O parameter values
    if (CDR_E) begin : g_cdr_rst
      a08_rst_cdr:   assert property (`SVA_CK $fell(rst) |-> (cdr_n == CDR_N && cdr_o == CDR_O));
    end
    // RTL reset: divider phase and cycle counter are cleared
    a09_rst_div_cnt: assert property (`SVA_CK $fell(rst) |-> (div == 0 && cnt == 0));

    // ---------------- B. control/status register ----------------
    // Table 10/11: ien is r/w (bit 7); value written is read back on the next cycle
    b01_rb_ien:   assert property (`SVA_CK wen_ctl |=> (ren_ctl |-> bus_rdt[7] == $past(bus_wdt[7])));
    // Table 10: ovd is r/w (bit 2)
    if (OVD_E) begin : g_ovd_rb
      b02_rb_ovd: assert property (`SVA_CK wen_ctl |=> (ren_ctl |-> bus_rdt[2] == $past(bus_wdt[2])));
    end
    // Table 10: rst is r/w (bit 1)
    b03_rb_rst:   assert property (`SVA_CK wen_ctl |=> (ren_ctl |-> bus_rdt[1] == $past(bus_wdt[1])));
    // Table 11: dat is r/w (bit 0) for a write; the read shows the value written
    b04_rb_dat:   assert property (`SVA_CK wen_ctl |=> (ren_ctl |-> bus_rdt[0] == $past(bus_wdt[0])));
    // Table 10: pwr is r/w (bit 4); single-line read gives the line power state
    b05_rb_pwr:   assert property (`SVA_CK wen_ctl |=> (ren_ctl |-> bus_rdt[4] == $past(bus_wdt[4])));
    // Table 10/11: writing cyc=1 starts a cycle, and cyc reads back as 1 while it runs
    b06_rb_cyc:   assert property (`SVA_CK (wen_ctl && bus_wdt[3] && bus_wdt[2:0] != 3'b111) |=> (ren_ctl |-> bus_rdt[3]));
    // Table 12: ovd=rst=dat=1 is a 0 us zero-time idle, so the write starts no cycle
    b07_zero_time_no_cycle: assert property (`SVA_CK wen_ctl && bus_wdt[2:0] == 3'b111 |=> !owr_cyc);
    // Table 11 "0 - no action" for cyc: a write with cyc=0 does not start a cycle (RTL also cancels a running one)
    b08_cyc0_cancels: assert property (`SVA_CK wen_ctl && !bus_wdt[3] |=> !owr_cyc);
    // Table 10: bit 5 is reserved; RTL reads it as 0
    b09_rsv_bit5: assert property (`SVA_CK ren_ctl |-> bus_rdt[5] == 1'b0);
    // sec 4.3 / Table 8: with OWN=1 the power and select fields are not implemented and read as 0
    b10_rsv_hi_bits: assert property (`SVA_CK ren_ctl |-> bus_rdt[31:8] == '0);
    if (CDR_E) begin : g_cdr_rb
      // sec 4.1 / Table 8: writing address 1 sets cdr_n (bits 15..0) and cdr_o (bits 31..16); read back
      b11_cdr_rb: assert property (`SVA_CK wen_cdr |=> (ren_cdr |-> bus_rdt == {$past(bus_wdt[31:16]), $past(bus_wdt[15:0])}));
      // sec 4.1: control/status writes do not touch the clock divider registers (RTL decode)
      b12_ctl_wr_keeps_cdr: assert property (`SVA_CK wen_ctl |=> ($stable(cdr_n) && $stable(cdr_o)));
    end

    // ---------------- C. cycle counter ----------------
    // Table 12 / sec 3.2: write-0 and write-1/read slots are 13 base periods (65 us normal)
    c01_load_w01_norm: assert property (`SVA_CK (wen_ctl && bus_wdt[3] && !bus_wdt[2] && !bus_wdt[1]) |=> cnt == (T_DAT0_N + T_RCVR_N - 1));
    // Table 12: normal reset/presence cycle is T_RSTL+T_RSTH base periods (960 us)
    c02_load_rst_norm: assert property (`SVA_CK (wen_ctl && bus_wdt[3] && !bus_wdt[2] && bus_wdt[1] && !bus_wdt[0]) |=> cnt == (T_RSTL_N + T_RSTH_N - 1));
    // Table 12: normal timed idle cycle is T_IDLE base periods (1000 us)
    c03_load_idle_norm: assert property (`SVA_CK (wen_ctl && bus_wdt[3] && !bus_wdt[2] && bus_wdt[1] && bus_wdt[0]) |=> cnt == (T_IDLE_N - 1));
    if (OVD_E) begin : g_ovd_load
      // Table 12: overdrive write-0 and write-1 slots are 8 base periods (8 us)
      c04_load_w01_ovd: assert property (`SVA_CK (wen_ctl && bus_wdt[3] && bus_wdt[2] && !bus_wdt[1]) |=> cnt == (T_DAT0_O + T_RCVR_O - 1));
      // Table 12: overdrive reset cycle is 96 us
      c05_load_rst_ovd: assert property (`SVA_CK (wen_ctl && bus_wdt[3] && bus_wdt[2] && bus_wdt[1] && !bus_wdt[0]) |=> cnt == (T_RSTL_O + T_RSTH_O - 1));
    end
    // RTL: counter changes only on a base-period pulse or a control write (holds otherwise)
    c06_cnt_hold: assert property (`SVA_CK (!pls && !wen_ctl) |=> $stable(cnt));
    // RTL: on each base period the counter counts down by one
    c07_cnt_dec: assert property (`SVA_CK (pls && !wen_ctl && cnt != 0) |=> cnt == $past(cnt) - 1);
    // RTL: a running cycle never holds a count above the longest loaded value (idle, 200 periods)
    c08_cnt_bound: assert property (`SVA_CK owr_cyc |-> cnt < MAXC);
    // sec 4.4: a cycle runs until its counter has expired (no spontaneous end)
    c09_cyc_holds: assert property (`SVA_CK (owr_cyc && !wen_ctl && !end_cyc) |=> owr_cyc);
    // RTL: a running cycle ends when the counter reaches zero on a base-period pulse
    c10_cyc_ends: assert property (`SVA_CK (owr_cyc && !wen_ctl && end_cyc) |=> !owr_cyc);

    // ---------------- D. clock divider ----------------
    // RTL: any bus write restarts the divider phase
    d01_div_clr_wr: assert property (`SVA_CK bus_wen |=> div == 0);
    // RTL: a base-period pulse restarts the divider
    d02_div_clr_pls: assert property (`SVA_CK (pls && !bus_wen) |=> div == 0);
    // RTL: while a cycle runs the divider counts clocks between base periods
    d03_div_count: assert property (`SVA_CK (owr_cyc && !pls && !bus_wen) |=> div == $past(div) + 1);
    // RTL: the divider holds when no cycle is running
    d04_div_hold: assert property (`SVA_CK (!owr_cyc && !pls && !bus_wen) |=> $stable(div));

    // ---------------- E. 1-wire line drive and sampling ----------------
    // Table 12 / Drawings 5-7: a data or reset cycle pulls the line low at its start
    e01_drive_start: assert property (`SVA_CK (wen_ctl && bus_wdt[3] && !(bus_wdt[1] && bus_wdt[0])) |=> owr_oen);
    // Table 12: the zero-time idle cycle does not drive the line
    e02_zero_time_nodrive: assert property (`SVA_CK (wen_ctl && bus_wdt[2:0] == 3'b111) |=> !owr_oen);
    // RTL: the drive enable changes only on a control write or a base-period pulse
    e03_oen_hold: assert property (`SVA_CK (!pls && !wen_ctl) |=> $stable(owr_oen));
    // Table 6/7, Drawing 5: a write-0 slot holds the line low until its release point (tDAT0)
    e04_w0_low: assert property (`SVA_CK (owr_cyc && !owr_rst && !owr_dat && cnt >= t_rel0 && !wen_ctl) |-> owr_oen);
    // RTL: write-0 releases the line at the tDAT0 counter point, on a base-period pulse
    e05_w0_release: assert property (`SVA_CK (pls && owr_cyc && !owr_rst && !owr_dat && cnt == t_rel0 && !wen_ctl) |=> !owr_oen);
    // Table 6/7, Drawing 7: a write-1/read slot holds the line low for tLOW1 (one base period)
    e06_w1_low: assert property (`SVA_CK (owr_cyc && !owr_rst && owr_dat && cnt >= t_rel1 && !wen_ctl) |-> owr_oen);
    // RTL: write-1/read releases the line at the tLOW1 counter point
    e07_w1_release: assert property (`SVA_CK (pls && owr_cyc && !owr_rst && owr_dat && cnt == t_rel1 && !wen_ctl) |=> !owr_oen);
    // Table 6/7, Drawing 4: a reset cycle holds the line low for tRSTL (96 base periods)
    e08_rst_low: assert property (`SVA_CK (owr_cyc && owr_rst && !owr_dat && cnt >= t_rsth && !wen_ctl) |-> owr_oen);
    // RTL: reset releases the line at the tRSTH counter point
    e09_rst_release: assert property (`SVA_CK (pls && owr_cyc && owr_rst && !owr_dat && cnt == t_rsth && !wen_ctl) |=> !owr_oen);
    // sec 3.2: every release point is reached before the cycle ends, so the line is free at the end
    e10_cyc_end_released: assert property (`SVA_CK (owr_cyc && end_cyc && !wen_ctl) |-> !owr_oen);
    // Output view of the write-0 low phase (sel 0 is the only line when OWN=1)
    e11_out_w0: assert property (`SVA_CK (owr_cyc && !owr_rst && !owr_dat && cnt >= t_rel0 && !wen_ctl && owr_sel == 0) |-> owr_e[0]);
    // Output view of the reset low phase
    e12_out_rst: assert property (`SVA_CK (owr_cyc && owr_rst && !owr_dat && cnt >= t_rsth && !wen_ctl && owr_sel == 0) |-> owr_e[0]);
    // RTL: the sample register changes only at its sampling points (presence or data bit)
    e13_smp_hold: assert property (`SVA_CK !(pls && ((owr_rst && cnt == t_rstp) || (!owr_rst && cnt == t_bits))) |=> $stable(owr_smp));
    // Table 6/7, Drawing 7: data is sampled at tDATS (3 base periods) from the falling edge; sample = line level
    e14_data_sample: assert property (`SVA_CK (pls && !owr_rst && cnt == t_bits && owr_sel == 0) |=> owr_smp == $past(owr_i[0]));
    // Table 11 / sec 3.2: presence is sampled at the presence point (tRSTP before reset release)
    e15_pres_sample: assert property (`SVA_CK (pls && owr_rst && cnt == t_rstp && owr_sel == 0) |=> owr_smp == $past(owr_i[0]));
    // Table 11: at the end of a cycle the sampled bit is latched into dat (read data / presence status)
    e16_dat_latch: assert property (`SVA_CK (owr_cyc && pls && cnt == 0 && !wen_ctl) |=> owr_dat == $past(owr_smp));
    // RTL: dat changes only on a control write or at the end of a cycle
    e17_dat_hold: assert property (`SVA_CK (!(pls && cnt == 0) && !wen_ctl) |=> $stable(owr_dat));
    // Output view of the zero-time idle: no line drive
    e18_zero_time_out: assert property (`SVA_CK (wen_ctl && bus_wdt[2:0] == 3'b111) |=> owr_e == '0);

    // ---------------- G. power ----------------
    // Table 10/11, sec 4.3: pwr bit sets line power on the power output
    g01_pwr_write: assert property (`SVA_CK wen_ctl |=> owr_p[0] == $past(bus_wdt[4]));
    // Table 10: power output changes only on a control write
    g02_pwr_hold: assert property (`SVA_CK !wen_ctl |=> $stable(owr_p));

    // ---------------- H. interrupt ----------------
    // Table 10/11: irq is set at the end of a 1-wire cycle
    h01_irq_set_end: assert property (`SVA_CK (owr_cyc && end_cyc && !wen_ctl) |=> irq_sts);
    // RTL: a control write clears the interrupt status
    h02_irq_clr_wr: assert property (`SVA_CK wen_ctl |=> !irq_sts);
    // Table 11: irq is cleared by a register read
    h03_irq_clr_rd: assert property (`SVA_CK (ren_ctl && !wen_ctl && !end_cyc) |=> !irq_sts);
    // Table 10/11: irq reads back in bit 6
    h04_irq_rd_data: assert property (`SVA_CK ren_ctl |-> bus_rdt[6] == irq_sts);
    // RTL priority: a cycle end in the same cycle as a read keeps the status set
    h05_irq_end_beats_rd: assert property (`SVA_CK (ren_ctl && !wen_ctl && owr_cyc && end_cyc) |=> irq_sts);
    // Table 10/11: with ien set, the end of a cycle raises the interrupt request
    h06_irq_raise: assert property (`SVA_CK (owr_cyc && end_cyc && !wen_ctl && irq_ena) |=> bus_irq);
    // Table 11: ien=0 disables the interrupt request
    h07_irq_masked: assert property (`SVA_CK !irq_ena |-> !bus_irq);

  end endgenerate

endmodule

bind sockit_owm sockit_owm_sva #(
  .OVD_E(OVD_E), .CDR_E(CDR_E), .BDW(BDW), .OWN(OWN), .BAW(BAW),
  .BTP_N(BTP_N), .BTP_O(BTP_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_RSTP_N(T_RSTP_N),
  .T_DAT0_N(T_DAT0_N), .T_DAT1_N(T_DAT1_N), .T_BITS_N(T_BITS_N),
  .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_RSTP_O(T_RSTP_O),
  .T_DAT0_O(T_DAT0_O), .T_DAT1_O(T_DAT1_O), .T_BITS_O(T_BITS_O),
  .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O),
  .CDR_N(CDR_N), .CDR_O(CDR_O)
) u_sockit_owm_sva (
  .clk(clk), .rst(rst),
  .bus_ren(bus_ren), .bus_wen(bus_wen), .bus_adr(bus_adr),
  .bus_wdt(bus_wdt), .bus_rdt(bus_rdt), .bus_irq(bus_irq),
  .owr_p(owr_p), .owr_e(owr_e), .owr_i(owr_i),
  .div(div), .cdr_n(cdr_n), .cdr_o(cdr_o),
  .pls(pls), .owr_cyc(owr_cyc), .cnt(cnt), .owr_sel(owr_sel),
  .owr_ovd(owr_ovd), .owr_rst(owr_rst), .owr_dat(owr_dat),
  .owr_smp(owr_smp), .owr_oen(owr_oen),
  .irq_ena(irq_ena), .irq_sts(irq_sts)
);
