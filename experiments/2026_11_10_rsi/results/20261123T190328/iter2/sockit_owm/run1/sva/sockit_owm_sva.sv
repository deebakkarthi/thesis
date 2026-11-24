// ============================================================================
// SVA checker for sockit_owm (1-wire master, Avalon-style 32-bit bus).
// Specified configuration: default parameters (BDW=32, OWN=1, CDR_E=1,
// OVD_E=1, BTP_N="5.0", BTP_O="1.0"). Reset is active high (rst).
//
// Cycle durations are counted in divider pulses ("base periods"), so they
// hold for any clock-divider ratio. Properties that depend on the actual
// base period in clocks are restricted to the reset value of cdr_n.
//
// Items deliberately NOT specified (see report):
//  - bus_rdt bit 0 after a cycle, owr_smp / owr_iln / owr_e and the value
//    loaded into owr_dat at end of cycle: OWN=1 leaves owr_sel undriven, so
//    the line select and everything sampled through it is unconstrained.
//  - owr_e as an output: it is owr_oen shifted by the undriven owr_sel.
// ============================================================================
module sockit_owm_sva #(
  parameter BAW      = 1,
  parameter BDW      = 32,
  parameter OWN      = 1,
  parameter CDW      = 16,
  parameter TDW      = 8,
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
  parameter T_RCVR_O = 2
)(
  input                  clk,
  input                  rst,
  input                  bus_wen,
  input                  bus_ren,
  input  [BAW-1:0]       bus_adr,
  input  [BDW-1:0]       bus_wdt,
  input  [BDW-1:0]       bus_rdt,
  input                  bus_irq,
  input  [OWN-1:0]       owr_p,
  input  [CDW-1:0]       div,
  input  [CDW-1:0]       cdr_n,
  input  [CDW-1:0]       cdr_o,
  input                  pls,
  input  [TDW-1:0]      cnt,
  input                  owr_cyc,
  input  [OWN-1:0]       owr_pwr,
  input                  owr_ovd,
  input                  owr_rst,
  input                  owr_dat,
  input                  owr_smp,
  input                  owr_oen,
  input                  irq_ena,
  input                  irq_sts
);

// ----------------------------------------------------------------------------
// Derived constants (base periods per cycle, from the datasheet Table 12 and
// the RTL cycle-length logic: cycle = DAT0+RCVR, RSTL+RSTH, IDLE, ...).
// ----------------------------------------------------------------------------
localparam integer LW_N   = T_DAT0_N + T_RCVR_N;   // normal write 0/1 cycle  (65us)
localparam integer LR_N   = T_RSTL_N + T_RSTH_N;   // normal reset cycle      (960us)
localparam integer LI_N   = T_IDLE_N;              // normal timed idle       (1000us)
localparam integer LW_O   = T_DAT0_O + T_RCVR_O;   // overdrive write cycle   (8us)
localparam integer LR_O   = T_RSTL_O + T_RSTH_O;   // overdrive reset cycle   (96us)
// base periods for which the line is pulled down (owr_oen high)
localparam integer LO_W0_N = T_DAT0_N;             // write 0: low for tDAT0
localparam integer LO_W1_N = T_DAT1_N;             // write 1/read: low for tDAT1
localparam integer LO_R_N  = T_RSTL_N;             // reset: low for tRSTL
localparam integer LO_W0_O = T_DAT0_O;
localparam integer LO_W1_O = T_DAT1_O;
localparam integer LO_R_O  = T_RSTL_O;

// ----------------------------------------------------------------------------
// Event helpers (interface events, not RTL conditions)
// ----------------------------------------------------------------------------
wire e_wctl = bus_wen && !bus_adr[0];     // write of control/status register
wire e_rctl = bus_ren && !bus_adr[0];     // read of control/status register
wire e_wcdr = bus_wen && bus_adr[0];      // write of clock divider register
wire e_rcdr = bus_ren && bus_adr[0];      // read of clock divider register
wire e_end  = pls && (cnt == 0);          // pulse at which a counted cycle ends

default clocking @(posedge clk); endclocking
default disable iff (rst);

// ============================================================================
// 1. Reset values (datasheet Table 10 and section 4.2/4.3)
//    Evaluated in the first cycle after reset is released.
// ============================================================================

// Table 10: all control/status bits reset to 0 (dat/bit5 are "x" in the table).
// The read-back of address 0 is therefore all zero (bits 31..8 are the unused
// power/select field, which reads 0 for OWN=1).
// Source: datasheet Table 10 / Table 8; RTL reset branches of irq_ena, irq_sts,
// owr_pwr, owr_cyc, owr_ovd, owr_rst, owr_dat.
a_rst_ctl: assert property (
  ((!rst && $past(rst)) && !bus_adr[0]) |-> (bus_rdt == 32'h0));

// Section 4.2: after reset the clock divider ratios equal CDR_N / CDR_O.
// Source: datasheet 4.2; RTL reset branch of cdr_n / cdr_o.
a_rst_cdr: assert property (
  ((!rst && $past(rst)) && bus_adr[0]) |-> (bus_rdt == {16'(CDR_O), 16'(CDR_N)}));

// Section 4.3: after reset all power bits are zero, so every line is only
// weakly pulled up (owr_p is the power enable).
// Source: datasheet 4.3; RTL reset of owr_pwr.
a_rst_pwr: assert property (
  (!rst && $past(rst)) |-> (owr_p == '0));

// Output enable and counters reset to idle. Source: RTL reset branches of
// owr_oen, div and cnt (no cycle in progress after reset).
a_rst_idle: assert property (
  (!rst && $past(rst)) |-> (!owr_oen && div == 0 && cnt == 0));

// ============================================================================
// 2. Bus read-back of written values (end-to-end)
// ============================================================================

// Table 10/11: a write to the control/status register is visible on the next
// read. Bits 7 (ien), 4 (pwr), 2 (ovd), 1 (rst), 0 (dat) are the written bits;
// bit 3 (cyc) reads back the new cycle request, and bit 6 (irq) is cleared by
// any control write. Write of 111 in bits 2..0 is a zero-time idle, which
// does not start a cycle (see section 3).
// Source: datasheet Table 10/11 and the write-priority of the control bits.
property p_wr_ctl_rb;
  logic [BDW-1:0] v;
  (e_wctl, v = bus_wdt) ##1 e_rctl |->
    (bus_rdt == {24'h0, v[7], 1'b0, 1'b0, v[4], v[3] & ~(&v[2:0]), v[2], v[1], v[0]});
endproperty
a_wr_ctl_rb: assert property (p_wr_ctl_rb);

// Section 4.2: the clock divider register written at address 1 reads back the
// same 32-bit word (cdr_o is bits 31..16, cdr_n is bits 15..0).
// Source: datasheet 4.2 and Table 8; RTL cdr_n / cdr_o write.
property p_wr_cdr_rb;
  logic [BDW-1:0] v;
  (e_wcdr, v = bus_wdt) ##1 e_rcdr |-> (bus_rdt == v);
endproperty
a_wr_cdr_rb: assert property (p_wr_cdr_rb);

// ============================================================================
// 3. Hold / stability (state changes only on interface events)
// ============================================================================

// Table 10 control bits and the power register are only written by a write to
// the control/status register.
// Source: datasheet 4.4 (bits are stored); RTL enables of irq_ena, owr_ovd,
// owr_rst and owr_pwr.
a_ctl_hold: assert property (
  !e_wctl |=> ($stable(irq_ena) && $stable(owr_ovd) && $stable(owr_rst) && $stable(owr_pwr)));

// Section 4.2: the clock divider ratios are only changed by a write to address 1.
// Source: datasheet 4.2; RTL enables bus_wen_cdr_n / bus_wen_cdr_o.
a_cdr_hold: assert property (
  !e_wcdr |=> ($stable(cdr_n) && $stable(cdr_o)));

// Data bit: changes only by a control write or by the end of a counted cycle
// (the value loaded is the sampled line state).
// Source: datasheet Table 11 (dat is the write data, then the read result at
// the end of the slot); RTL owr_dat enables.
a_dat_hold: assert property (
  (!e_wctl && !e_end) |=> $stable(owr_dat));

// The cycle status bit only changes by a control write or by the end of a
// counted cycle. Source: datasheet Table 11 (cyc); RTL owr_cyc enables.
a_cyc_hold: assert property (
  (!e_wctl && !e_end) |=> $stable(owr_cyc));

// Output enable only changes by a control write or by a base period pulse.
// Source: RTL owr_oen enables (state machine advances only on pulses).
a_oen_hold: assert property (
  (!e_wctl && !pls) |=> $stable(owr_oen));

// Counter: holds between pulses, loads on control write, decrements on pulse.
// Source: datasheet 3.1 (counter steps on each base period); RTL cnt block.
a_cnt_hold: assert property ((!e_wctl && !pls) |=> $stable(cnt));
a_cnt_step: assert property ((!e_wctl && pls) |=> ((cnt + 1'b1) == $past(cnt)));

// Sample register is only updated on a base period pulse.
// Source: datasheet 2.3 (the line is sampled at the sampling point, i.e. on a
// base period); RTL owr_smp enable.
a_smp_hold: assert property (!pls |=> $stable(owr_smp));

// ============================================================================
// 4. Clock divider (datasheet 3.1 / 4.2)
// ============================================================================

// A bus write restarts the divider.
// Source: RTL div block (bus_wen clears div).
a_div_wr: assert property (bus_wen |=> (div == 0));

// A base period pulse restarts the divider.
// Source: datasheet 3.1 (clock generator produces a pulse every base period).
a_div_pls: assert property ((!bus_wen && pls) |=> (div == 0));

// While a cycle is in progress, the divider counts one step per clock.
// Source: datasheet 3.1; RTL div increment on owr_cyc.
a_div_cnt: assert property ((!bus_wen && !pls && owr_cyc) |=> (div == ($past(div) + 1'b1)));

// Idle: the divider holds (no cycle, no pulse, no write).
// Source: datasheet 3.1; RTL div hold when owr_cyc is low.
a_div_idle: assert property ((!bus_wen && !pls && !owr_cyc) |=> $stable(div));

// Normal mode base period: with the reset ratio CDR_N (base period 5 us for
// a 1 MHz divided clock, datasheet Table 7), a normal-mode cycle's first pulse
// comes CDR_N+1 clocks after the start write and pulses repeat every CDR_N+1
// clocks. Restricted to cdr_n == CDR_N because the ratio is programmable.
// Source: datasheet 2.1.3 / Table 7; RTL pls = (div == cdr_n).
a_div_first_n: assert property (
  (e_wctl && bus_wdt[3] && !bus_wdt[2] && (cdr_n == CDR_N)) |=>
    ((!bus_wen && !pls)[*CDR_N]) ##1 pls);

a_div_next_n: assert property (
  (pls && owr_cyc && !owr_ovd && (cnt != 0) && !bus_wen && (cdr_n == CDR_N)) |=>
    ((!bus_wen && !pls)[*CDR_N]) ##1 pls);

// ============================================================================
// 5. Cycle timing (datasheet Table 12 and section 3.2). A cycle lasts exactly
//    the number of base periods given in Table 12: the pulse that completes the
//    count clears owr_cyc, and no bus write may interrupt it.
//    Durations: write0 normal 13 (65us), write1/read normal 13 (65us),
//    reset normal 192 (960us), timed idle normal 200 (1000us);
//    write0 overdrive 8 (8us), write1/read overdrive 8 (8us),
//    reset overdrive 96 (96us). Overdrive zero-time idle starts no cycle.
// ============================================================================

// Source: datasheet Table 12 row ovd=0 rst=0 dat=0 (65 us write 0 cycle).
a_cyc_w0_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1000)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LW_N]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=0 rst=0 dat=1 (65 us write 1/read cycle).
a_cyc_w1_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1001)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LW_N]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=0 rst=1 dat=0 (960 us reset cycle).
a_cyc_rst_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1010)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LR_N]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=0 rst=1 dat=1 (1000 us timed idle).
a_cyc_idl_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1011)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LI_N]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=1 rst=0 dat=0 (8 us overdrive write 0).
a_cyc_w0_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1100)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LW_O]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=1 rst=0 dat=1 (8 us overdrive write 1/read).
a_cyc_w1_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1101)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LW_O]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=1 rst=1 dat=0 (96 us overdrive reset).
a_cyc_rst_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1110)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LR_O]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=1 rst=1 dat=1 (0 us zero-time idle):
// writing cyc with this pattern starts no cycle.
a_cyc_zero: assert property (
  (e_wctl && (&bus_wdt[2:0])) |=> !owr_cyc);

// Source: datasheet 3.1 / Table 10 (cyc=0 on write means no cycle is started).
// RTL owr_cyc <= wdt[3] & ~&wdt[2:0].
a_cyc_nostart: assert property ((e_wctl && !bus_wdt[3]) |=> !owr_cyc);

// ============================================================================
// 6. Line drive (owr_oen) within each cycle (datasheet Table 12, 3.2).
//    Pulled down for the Table 7 low time, then released at the next cycle.
// ============================================================================

// Source: datasheet 3.2 / Table 7 (tDAT0 low for write 0).
a_drv_w0_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1000)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_W0_N]) ##1 !owr_oen));

// Source: datasheet 3.2 / Table 7 (tDAT1 low for write 1).
a_drv_w1_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1001)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_W1_N]) ##1 !owr_oen));

// Source: datasheet 3.2 / Table 7 (tRSTL low for reset).
a_drv_rst_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1010)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_R_N]) ##1 !owr_oen));

// Source: datasheet 3.2 (timed idle drives nothing).
a_drv_idl_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1011)) |=>
    ((!owr_oen && !bus_wen) throughout pls[->LI_N]));

// Source: datasheet 3.2 / Table 7 overdrive low times.
a_drv_w0_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1100)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_W0_O]) ##1 !owr_oen));

a_drv_w1_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1101)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_W1_O]) ##1 !owr_oen));

a_drv_rst_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1110)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_R_O]) ##1 !owr_oen));

// Source: datasheet Table 12 (zero-time idle drives nothing); RTL owr_oen <= ~&wdt[1:0].
a_drv_zero: assert property ((e_wctl && (&bus_wdt[2:0])) |=> !owr_oen);

// ============================================================================
// 7. Interrupt / status flag (datasheet Table 11 bit 6, 4.5.2)
// ============================================================================

// Source: datasheet Table 11 bit 6: status is set at the end of each 1-wire
// cycle; a control write takes priority over the set (RTL irq_sts).
a_irq_set: assert property ((owr_cyc && e_end && !e_wctl) |=> irq_sts);

// Source: datasheet Table 11 bit 6: "cleared by bus read" of the
// control/status register. A read clears unless a cycle ends in the same clock.
a_irq_rd_clr: assert property ((e_rctl && !e_end) |=> !irq_sts);

// Source: RTL irq_sts block: a control write clears the status.
a_irq_wr_clr: assert property (e_wctl |=> !irq_sts);

// Source: datasheet Table 11 bit 7 (ien: 0 disables the interrupt).
a_irq_en_lo: assert property (!irq_ena |-> !bus_irq);

// Source: datasheet Table 11 bit 6/7: a set, enabled status is an interrupt.
a_irq_en_hi: assert property ((irq_ena && irq_sts) |-> bus_irq);

// Source: datasheet 4.5.1 (polling uses cyc to detect end of cycle, and the
// status bit is visible after it). Next read after the end shows irq=1, cyc=0.
a_irq_poll: assert property (
  (owr_cyc && e_end && !e_wctl) ##1 e_rctl |-> (bus_rdt[6] && !bus_rdt[3]));

// Source: datasheet Table 11 bit 3 / 4.5.1: the end of a cycle clears cyc.
a_cyc_end: assert property ((owr_cyc && e_end && !e_wctl) |=> !owr_cyc);

// ============================================================================
// 8. Power output (datasheet 2.2.2 / 4.3, OWN=1)
// ============================================================================

// Source: datasheet 4.3 (power bit 4 drives owr_p; for OWN=1 the write value of
// pwr directly controls owr_p[0]).
a_pwr_hi: assert property ((e_wctl && bus_wdt[4]) |=> owr_p[0]);
a_pwr_lo: assert property ((e_wctl && !bus_wdt[4]) |=> !owr_p[0]);

endmodule

bind sockit_owm sockit_owm_sva #(
  .BAW(BAW), .BDW(BDW), .OWN(OWN), .CDW(CDW), .TDW(TDW),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_DAT0_N(T_DAT0_N), .T_DAT1_N(T_DAT1_N),
  .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_DAT0_O(T_DAT0_O), .T_DAT1_O(T_DAT1_O),
  .T_RCVR_O(T_RCVR_O)
) u_sockit_owm_sva (.*);
