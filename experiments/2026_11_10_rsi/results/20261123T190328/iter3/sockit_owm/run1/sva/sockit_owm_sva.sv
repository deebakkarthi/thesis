// SVA checker for sockit_owm (1-wire master), specified for the default
// parameter set (OVD_E=1, CDR_E=1, BDW=32, OWN=1, BAW=1, BTP_N="5.0", BTP_O="1.0").
// Sources: datasheet sections 2.2, 4.1-4.5 (Tables 8-12), and RTL.
// Internal signals used:
//  - owr_sel is never assigned for OWN=1, so owr_e (when owr_oen=1), owr_iln and
//    owr_smp are arbitrary; no property asserts their values.
module sockit_owm_sva #(
  parameter OVD_E    = 1,
  parameter CDR_E    = 1,
  parameter BDW      = 32,
  parameter OWN      = 1,
  parameter BAW      = 1,
  parameter CDR_N    = 4,
  parameter CDR_O    = 0,
  parameter T_RSTH_N = 96,
  parameter T_RSTL_N = 96,
  parameter T_DAT0_N = 12,
  parameter T_DAT1_N = 1,
  parameter T_RCVR_N = 1,
  parameter T_IDLE_N = 200,
  parameter T_RSTH_O = 48,
  parameter T_RSTL_O = 48,
  parameter T_DAT0_O = 6,
  parameter T_DAT1_O = 1,
  parameter T_RCVR_O = 2,
  parameter T_IDLE_O = 96,
  parameter CDW = CDR_E ? ((BDW == 32) ? 16 : 8) : $clog2(CDR_N),
  parameter TDW = ((T_RSTH_O + T_RSTL_O) > (T_RSTH_N + T_RSTL_N)) ?
                  $clog2(T_RSTH_O + T_RSTL_O) : $clog2(T_RSTH_N + T_RSTL_N)
)(
  input logic              clk,
  input logic              rst,
  input logic              bus_ren,
  input logic              bus_wen,
  input logic [BAW-1:0]    bus_adr,
  input logic [BDW-1:0]    bus_wdt,
  input logic [BDW-1:0]    bus_rdt,
  input logic              bus_irq,
  input logic [OWN-1:0]    owr_e,
  input logic [OWN-1:0]    owr_p,
  input logic              pls,
  input logic [TDW-1:0]    cnt,
  input logic              owr_cyc,
  input logic              owr_ovd,
  input logic              owr_rst,
  input logic              owr_dat,
  input logic              owr_oen,
  input logic              irq_ena,
  input logic              irq_sts,
  input logic [CDW-1:0]    cdr_n,
  input logic [CDW-1:0]    cdr_o
);

  // ------------------------------------------------------------------------
  // Derived constants (datasheet Table 7 / RTL timing functions)
  // PN, PO: clocks per base period (divider ratio + 1).
  // LN_*, LO_*: base periods from a control write until cycle end.
  // MN_*, MO_*: base period (pulse) index at which the line is released.
  // ------------------------------------------------------------------------
  localparam int PN      = CDR_N + 1;
  localparam int PO      = CDR_O + 1;
  localparam int LN_BIT  = T_DAT0_N + T_RCVR_N;          // 13
  localparam int LN_RST  = T_RSTH_N + T_RSTL_N;          // 192
  localparam int LN_IDL  = T_IDLE_N;                     // 200
  localparam int LO_BIT  = T_DAT0_O + T_RCVR_O;          // 8
  localparam int LO_RST  = T_RSTH_O + T_RSTL_O;          // 96
  localparam int MN_W0   = LN_BIT - T_RCVR_N;            // 12 (release at t_dat0)
  localparam int MN_W1   = LN_BIT - (T_DAT0_N - T_DAT1_N + T_RCVR_N); // 1
  localparam int MN_RST  = LN_RST - T_RSTH_N;            // 96 (release at t_rsth)
  localparam int MO_W0   = LO_BIT - T_RCVR_O;            // 6
  localparam int MO_W1   = LO_BIT - (T_DAT0_O - T_DAT1_O + T_RCVR_O); // 1
  localparam int MO_RST  = LO_RST - T_RSTH_O;            // 48
  // clock-cycle counts used in sequences
  localparam int K_N_BIT = LN_BIT * PN;                  // 65
  localparam int K_N_RST = LN_RST * PN;                  // 960
  localparam int K_N_IDL = LN_IDL * PN;                  // 1000
  localparam int K_O_BIT = LO_BIT * PO;                  // 8
  localparam int K_O_RST = LO_RST * PO;                  // 96
  localparam int R_N_W0  = MN_W0 * PN;                   // 60
  localparam int R_N_W1  = MN_W1 * PN;                   // 5
  localparam int R_N_RST = MN_RST * PN;                  // 480
  localparam int R_O_W0  = MO_W0 * PO;                   // 6
  localparam int R_O_W1  = MO_W1 * PO;                   // 1
  localparam int R_O_RST = MO_RST * PO;                  // 48

  // ------------------------------------------------------------------------
  // Decodes
  // ------------------------------------------------------------------------
  wire ctl_wr  = bus_wen && !bus_adr[0];                 // control/status write
  wire cdr_wr  = bus_wen &&  bus_adr[0];                 // clock divider write
  wire ctl_rd  = bus_ren && !bus_adr[0];                 // control/status read
  wire cyc_end = pls && (cnt == '0);                     // end-of-cycle pulse (RTL t_zero)
  wire ok_n    = (cdr_n == CDR_N);                       // normal divider at default
  wire ok_o    = (cdr_o == CDR_O);                       // overdrive divider at default

  // cycle-start writes, selected by the written cyc/ovd/rst/dat bits [3:0]
  wire go_n_w0  = ctl_wr && (bus_wdt[3:0] == 4'b1000);   // normal write 0
  wire go_n_w1  = ctl_wr && (bus_wdt[3:0] == 4'b1001);   // normal write 1 / read
  wire go_n_rst = ctl_wr && (bus_wdt[3:0] == 4'b1010);   // normal reset/presence
  wire go_n_idl = ctl_wr && (bus_wdt[3:0] == 4'b1011);   // normal timed idle (1 ms)
  wire go_o_w0  = ctl_wr && (bus_wdt[3:0] == 4'b1100);   // overdrive write 0
  wire go_o_w1  = ctl_wr && (bus_wdt[3:0] == 4'b1101);   // overdrive write 1 / read
  wire go_o_rst = ctl_wr && (bus_wdt[3:0] == 4'b1110);   // overdrive reset/presence
  wire go_o_idl = ctl_wr && (bus_wdt[3:0] == 4'b1111);   // overdrive zero-time idle

  default clocking @(posedge clk); endclocking
  default disable iff (rst);

  // ------------------------------------------------------------------------
  // 1. Reset values. Source: datasheet Table 10 (reset column) and RTL reset.
  // ------------------------------------------------------------------------

  // Table 10: ien resets to 0.
  a_rst_irq_ena: assert property ($past(rst) |-> !irq_ena);
  // Table 10: irq resets to 0.
  a_rst_irq_sts: assert property ($past(rst) |-> !irq_sts);
  // Table 10: cyc resets to 0 (no cycle in progress).
  a_rst_cyc: assert property ($past(rst) |-> !owr_cyc);
  // Table 10: ovd resets to 0.
  a_rst_ovd: assert property ($past(rst) |-> !owr_ovd);
  // Table 10: rst resets to 0.
  a_rst_rst: assert property ($past(rst) |-> !owr_rst);
  // RTL reset branch of owr_dat (datasheet says x; RTL resets to 0).
  a_rst_dat: assert property ($past(rst) |-> !owr_dat);
  // Table 10: pwr resets to 0, so the power output is off.
  a_rst_pwr: assert property ($past(rst) |-> owr_p == '0);
  // RTL reset of owr_oen: line driver off, and owr_e = owr_oen << sel is 0 for any sel.
  a_rst_oen: assert property ($past(rst) |-> owr_e == '0);
  // RTL reset of the cycle counter.
  a_rst_cnt: assert property ($past(rst) |-> cnt == '0);
  // Section 4.2: divider registers reset to CDR_N / CDR_O.
  a_rst_cdr_n: assert property ($past(rst) |-> cdr_n == CDR_N);
  a_rst_cdr_o: assert property ($past(rst) |-> cdr_o == CDR_O);
  // Section 4.4: after reset the control/status register reads all zero.
  a_rst_rdt_ctl: assert property ($past(rst) && !bus_adr[0] |-> bus_rdt == '0);

  // ------------------------------------------------------------------------
  // 2. Register map and read-back. Sources: Table 8 (address map), Table 10/11.
  // ------------------------------------------------------------------------

  // Table 8: with OWN=1 the power/select fields are not implemented, so the
  // control/status read at address 0 returns zero in bits 31:8.
  a_map_ctl_hi0: assert property (!bus_adr[0] |-> bus_rdt[31:8] == '0);
  // Table 10: bit 5 of the control/status register is reserved and reads 0.
  a_map_ctl_rsv: assert property (!bus_adr[0] |-> !bus_rdt[5]);
  // Table 11 bit 7 (ien): a control write is read back in the next cycle.
  a_rb_ien: assert property (ctl_wr ##1 !bus_adr[0] |-> bus_rdt[7] == $past(bus_wdt[7]));
  // Table 11 bit 4 (pwr, OWN=1): a control write is read back in the next cycle.
  a_rb_pwr: assert property (ctl_wr ##1 !bus_adr[0] |-> bus_rdt[4] == $past(bus_wdt[4]));
  // Table 11 bit 2 (ovd): a control write is read back in the next cycle.
  a_rb_ovd: assert property (ctl_wr ##1 !bus_adr[0] |-> bus_rdt[2] == $past(bus_wdt[2]));
  // Table 11 bit 1 (rst): a control write is read back in the next cycle.
  a_rb_rst: assert property (ctl_wr ##1 !bus_adr[0] |-> bus_rdt[1] == $past(bus_wdt[1]));
  // Table 11 bit 0 (dat): read back the written bit. No cycle can end in the
  // cycle right after a control write, because the loaded counter is at least 7.
  a_rb_dat: assert property (ctl_wr ##1 !bus_adr[0] |-> bus_rdt[0] == $past(bus_wdt[0]));
  // Table 8/4.2: a divider write is read back at address 1 (cdr_o high, cdr_n low).
  a_rb_cdr: assert property (cdr_wr ##1 bus_adr[0] |-> bus_rdt == $past(bus_wdt));

  // ------------------------------------------------------------------------
  // 3. Hold / update events. Each register changes only on the events listed.
  // ------------------------------------------------------------------------

  // Section 4.2: divider registers change only on a divider write.
  h_cdr: assert property (!cdr_wr |=> ($stable(cdr_n) && $stable(cdr_o)));
  // ien changes only on a control write.
  h_ien: assert property (!ctl_wr |=> $stable(irq_ena));
  // pwr changes only on a control write.
  h_pwr: assert property (!ctl_wr |=> $stable(owr_p));
  // ovd changes only on a control write.
  h_ovd: assert property (!ctl_wr |=> $stable(owr_ovd));
  // rst changes only on a control write.
  h_rst: assert property (!ctl_wr |=> $stable(owr_rst));
  // cyc changes only on a control write or at the end-of-cycle pulse.
  h_cyc: assert property (!ctl_wr && !cyc_end |=> $stable(owr_cyc));
  // dat changes only on a control write or at the end-of-cycle pulse.
  h_dat: assert property (!ctl_wr && !cyc_end |=> $stable(owr_dat));
  // irq changes only on a control write, a control read, or the end-of-cycle pulse.
  h_irq: assert property (!ctl_wr && !ctl_rd && !cyc_end |=> $stable(irq_sts));
  // The cycle counter changes only on a control write or a pulse.
  h_cnt: assert property (!ctl_wr && !pls |=> $stable(cnt));
  // Line driver enable rises only on a control write (Section 4.4 / RTL).
  h_oen_up: assert property (!owr_oen && !ctl_wr |=> !owr_oen);
  // Line driver enable falls only on a pulse (RTL pulse-driven release).
  h_oen_dn: assert property (owr_oen && !ctl_wr && !pls |=> owr_oen);

  // ------------------------------------------------------------------------
  // 4. Outputs.
  // ------------------------------------------------------------------------

  // Section 2.2.2 / Table 4: the power output follows the written pwr bit (OWN=1).
  a_pwr_out: assert property (ctl_wr |=> owr_p[0] == $past(bus_wdt[4]));
  // Section 4.3 / Table 4: the line driver enable is off whenever owr_oen is off.
  a_e_gate: assert property (!owr_oen |-> owr_e == '0);
  // Section 4.4: an idle cycle (rst=1, dat=1) does not drive the line.
  a_idle_quiet: assert property ((ctl_wr && bus_wdt[1:0] == 2'b11) |=> owr_e == '0);

  // ------------------------------------------------------------------------
  // 5. Interrupt / cycle status flag.
  // Sources: Table 11 bits 6 and 3, Section 2.2.1 and 4.4.
  // ------------------------------------------------------------------------

  // Table 11 bit 6: any control write clears the interrupt status.
  a_irq_wr_clr: assert property (ctl_wr |=> !irq_sts);
  // Table 11 bit 6: a control read clears the interrupt status (unless the cycle ends now).
  a_irq_rd_clr: assert property ((ctl_rd && !ctl_wr && !cyc_end) |=> !irq_sts);
  // The interrupt output is low after the status is cleared by a read.
  a_irq_rd_bus: assert property ((ctl_rd && !ctl_wr && !cyc_end) |=> !bus_irq);

  // ------------------------------------------------------------------------
  // 6. Cycle start, duration, and line release. Each cycle type is checked
  // from a start write with the divider at its default value (no bus write
  // in the window, which keeps the divider and counter untouched).
  // Source: Table 12 (cycle types), Table 7 (timing), RTL counter/release logic.
  // ------------------------------------------------------------------------

  // ---- normal mode, write 0 (cyc=1, ovd=0, rst=0, dat=0) : 65 us = 13 base periods
  a_n_w0_start: assert property (go_n_w0 |=> (owr_cyc && !irq_sts && owr_oen));
  a_n_w0_busy:  assert property ((go_n_w0 && ok_n) ##1 (!bus_wen)[*K_N_BIT] |-> owr_cyc);
  a_n_w0_end:   assert property ((go_n_w0 && ok_n) ##1 (!bus_wen)[*K_N_BIT] |=> (!owr_cyc && irq_sts));
  // Table 7 tDAT0: line low for 12 base periods, then released.
  a_n_w0_low:   assert property ((go_n_w0 && ok_n) ##1 (!bus_wen)[*R_N_W0] |-> owr_oen);
  a_n_w0_rel:   assert property ((go_n_w0 && ok_n) ##1 (!bus_wen)[*R_N_W0] |=> !owr_oen);
  // Table 11 bit 7 / Section 2.2.1: an enabled cycle end raises the interrupt output.
  a_n_w0_irq_en:  assert property ((go_n_w0 && ok_n && bus_wdt[7]) ##1 (!bus_wen)[*K_N_BIT] |=> bus_irq);
  a_n_w0_irq_dis: assert property ((go_n_w0 && ok_n && !bus_wdt[7]) ##1 (!bus_wen)[*K_N_BIT] |=> !bus_irq);
  // Table 11 bit 6: the status is readable after the cycle end and shows the interrupt.
  a_n_w0_irq_rd:  assert property ((go_n_w0 && ok_n) ##1 (!bus_wen)[*K_N_BIT] ##1 ctl_rd |-> bus_rdt[6]);

  // ---- normal mode, write 1 / read (cyc=1, ovd=0, rst=0, dat=1) : 65 us
  a_n_w1_start: assert property (go_n_w1 |=> (owr_cyc && !irq_sts && owr_oen));
  a_n_w1_busy:  assert property ((go_n_w1 && ok_n) ##1 (!bus_wen)[*K_N_BIT] |-> owr_cyc);
  a_n_w1_end:   assert property ((go_n_w1 && ok_n) ##1 (!bus_wen)[*K_N_BIT] |=> (!owr_cyc && irq_sts));
  // Table 7 tDAT1: line low for 1 base period, then released.
  a_n_w1_low:   assert property ((go_n_w1 && ok_n) ##1 (!bus_wen)[*R_N_W1] |-> owr_oen);
  a_n_w1_rel:   assert property ((go_n_w1 && ok_n) ##1 (!bus_wen)[*R_N_W1] |=> !owr_oen);

  // ---- normal mode, reset/presence (cyc=1, ovd=0, rst=1, dat=0) : 960 us
  a_n_rst_start: assert property (go_n_rst |=> (owr_cyc && !irq_sts && owr_oen));
  a_n_rst_busy:  assert property ((go_n_rst && ok_n) ##1 (!bus_wen)[*K_N_RST] |-> owr_cyc);
  a_n_rst_end:   assert property ((go_n_rst && ok_n) ##1 (!bus_wen)[*K_N_RST] |=> (!owr_cyc && irq_sts));
  // Table 7 tRSTL: line low for 480 us (96 base periods), then released.
  a_n_rst_low:   assert property ((go_n_rst && ok_n) ##1 (!bus_wen)[*R_N_RST] |-> owr_oen);
  a_n_rst_rel:   assert property ((go_n_rst && ok_n) ##1 (!bus_wen)[*R_N_RST] |=> !owr_oen);

  // ---- normal mode, timed idle (cyc=1, ovd=0, rst=1, dat=1) : 1 ms, no line drive
  a_n_idl_start: assert property (go_n_idl |=> (owr_cyc && !irq_sts && !owr_oen));
  a_n_idl_busy:  assert property ((go_n_idl && ok_n) ##1 (!bus_wen)[*K_N_IDL] |-> owr_cyc);
  a_n_idl_end:   assert property ((go_n_idl && ok_n) ##1 (!bus_wen)[*K_N_IDL] |=> (!owr_cyc && irq_sts));

  // ---- overdrive, write 0 (cyc=1, ovd=1, rst=0, dat=0) : 8 us
  a_o_w0_start: assert property (go_o_w0 |=> (owr_cyc && !irq_sts && owr_oen));
  a_o_w0_busy:  assert property ((go_o_w0 && ok_o) ##1 (!bus_wen)[*K_O_BIT] |-> owr_cyc);
  a_o_w0_end:   assert property ((go_o_w0 && ok_o) ##1 (!bus_wen)[*K_O_BIT] |=> (!owr_cyc && irq_sts));
  // Table 7 overdrive tDAT0: line low for 6 us, then released.
  a_o_w0_low:   assert property ((go_o_w0 && ok_o) ##1 (!bus_wen)[*R_O_W0] |-> owr_oen);
  a_o_w0_rel:   assert property ((go_o_w0 && ok_o) ##1 (!bus_wen)[*R_O_W0] |=> !owr_oen);
  a_o_w0_irq_en:  assert property ((go_o_w0 && ok_o && bus_wdt[7]) ##1 (!bus_wen)[*K_O_BIT] |=> bus_irq);
  a_o_w0_irq_dis: assert property ((go_o_w0 && ok_o && !bus_wdt[7]) ##1 (!bus_wen)[*K_O_BIT] |=> !bus_irq);

  // ---- overdrive, write 1 / read (cyc=1, ovd=1, rst=0, dat=1) : 8 us
  a_o_w1_start: assert property (go_o_w1 |=> (owr_cyc && !irq_sts && owr_oen));
  a_o_w1_busy:  assert property ((go_o_w1 && ok_o) ##1 (!bus_wen)[*K_O_BIT] |-> owr_cyc);
  a_o_w1_end:   assert property ((go_o_w1 && ok_o) ##1 (!bus_wen)[*K_O_BIT] |=> (!owr_cyc && irq_sts));
  // Table 7 overdrive tDAT1: line low for 1 us, then released.
  a_o_w1_low:   assert property ((go_o_w1 && ok_o) ##1 (!bus_wen)[*R_O_W1] |-> owr_oen);
  a_o_w1_rel:   assert property ((go_o_w1 && ok_o) ##1 (!bus_wen)[*R_O_W1] |=> !owr_oen);

  // ---- overdrive, reset/presence (cyc=1, ovd=1, rst=1, dat=0) : 96 us
  a_o_rst_start: assert property (go_o_rst |=> (owr_cyc && !irq_sts && owr_oen));
  a_o_rst_busy:  assert property ((go_o_rst && ok_o) ##1 (!bus_wen)[*K_O_RST] |-> owr_cyc);
  a_o_rst_end:   assert property ((go_o_rst && ok_o) ##1 (!bus_wen)[*K_O_RST] |=> (!owr_cyc && irq_sts));
  // Table 7 overdrive tRSTL: line low for 48 us, then released.
  a_o_rst_low:   assert property ((go_o_rst && ok_o) ##1 (!bus_wen)[*R_O_RST] |-> owr_oen);
  a_o_rst_rel:   assert property ((go_o_rst && ok_o) ##1 (!bus_wen)[*R_O_RST] |=> !owr_oen);

  // ---- overdrive zero-time idle (cyc=1, ovd=1, rst=1, dat=1): no cycle in progress.
  // Table 12 / Table 10 cyc: the write does not start a cycle (cyc reads 0).
  a_o_idl_nocyc: assert property (go_o_idl |=> !owr_cyc);

  // ---- restart: a control write with cyc=1 starts a new cycle, whatever state it
  // was in (the start properties above have no prior-state precondition).

endmodule

bind sockit_owm sockit_owm_sva #(
  .OVD_E(OVD_E), .CDR_E(CDR_E), .BDW(BDW), .OWN(OWN), .BAW(BAW),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_DAT0_N(T_DAT0_N),
  .T_DAT1_N(T_DAT1_N), .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_DAT0_O(T_DAT0_O),
  .T_DAT1_O(T_DAT1_O), .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);
