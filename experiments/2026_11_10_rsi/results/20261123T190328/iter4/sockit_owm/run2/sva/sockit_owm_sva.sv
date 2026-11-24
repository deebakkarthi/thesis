// SVA checker for sockit_owm (1-wire master), default parameters:
// OVD_E=1, CDR_E=1, BDW=32, OWN=1, BTP_N="5.0", BTP_O="1.0"
// => CDR_N=4, CDR_O=0, normal-mode tick = 5 clocks, overdrive tick = 1 clock.
// Sources: doc sections 2.2, 4.1-4.5 and Tables 8-12 (datasheet), rtl/sockit_owm.v.
//
// Timing reference used below: a control write with cyc=1 is sampled at edge E0.
// qc (auxiliary) equals k-1 at the sample of edge Ek when no bus write occurred
// in E1..E(k-1). Cycle length in clocks is (ticks) * (ratio+1):
//   normal write-0/write-1 : 13 ticks x 5 = 65 clocks (tDAT0+tREC)
//   normal reset           : 192 ticks x 5 = 960 clocks (tRSTL+tRSTH, 960us)
//   normal timed idle      : 200 ticks x 5 = 1000 clocks (tDLY, 1000us)
//   overdrive write-0/1    : 8 ticks x 1 = 8 clocks (8us)
//   overdrive reset        : 96 ticks x 1 = 96 clocks (96us)
module sockit_owm_sva #(
  parameter BDW   = 32,
  parameter BAW   = 1,
  parameter OWN   = 1,
  parameter OVD_E = 1,
  parameter CDW   = 16,
  parameter TDW   = 8,
  parameter CDR_N = 4,
  parameter CDR_O = 0
)(
  input                clk,
  input                rst,
  input                bus_ren,
  input                bus_wen,
  input  [BAW-1:0]     bus_adr,
  input  [BDW-1:0]     bus_wdt,
  input  [BDW-1:0]     bus_rdt,
  input                bus_irq,
  input  [OWN-1:0]     owr_p,
  input  [OWN-1:0]     owr_e,
  input  [OWN-1:0]     owr_pwr,
  input                owr_ovd,
  input                owr_rst,
  input                owr_dat,
  input                owr_cyc,
  input                owr_oen,
  input                irq_ena,
  input                irq_sts,
  input  [CDW-1:0]     div,
  input  [CDW-1:0]     cdr_n,
  input  [CDW-1:0]     cdr_o,
  input  [TDW-1:0]     cnt,
  input                pls
);

default clocking @(posedge clk); endclocking
default disable iff (rst);

//////////////////////////////////////////////////////////////////////////////
// auxiliary logic
//////////////////////////////////////////////////////////////////////////////

// control/status register write (address 0)
wire ctl_wr = bus_wen && (bus_adr == 0);

// clocks since the last bus write (saturating)
reg [10:0] qc;
// type of the last bus write if it started a 1-wire cycle with default ratios
// 0 none, 1 normal write0, 2 normal write1, 3 normal reset, 4 normal timed idle,
// 5 overdrive write0, 6 overdrive write1, 7 overdrive reset
reg [2:0]  kind;

wire dflt_n = (cdr_n == CDR_N);
wire dflt_o = (cdr_o == CDR_O);
wire [2:0] wc = bus_wdt[2:0];   // {ovd, rst, dat}
wire [2:0] k_of_wr =
    !(ctl_wr && bus_wdt[3])          ? 3'd0 :
    (wc == 3'd0 && dflt_n)           ? 3'd1 :
    (wc == 3'd1 && dflt_n)           ? 3'd2 :
    (wc == 3'd2 && dflt_n)           ? 3'd3 :
    (wc == 3'd3 && dflt_n)           ? 3'd4 :
    (wc == 3'd4 && dflt_o)           ? 3'd5 :
    (wc == 3'd5 && dflt_o)           ? 3'd6 :
    (wc == 3'd6 && dflt_o)           ? 3'd7 : 3'd0;   // 3'd7 = zero-time idle, no cycle

wire k_nb0 = (kind == 3'd1);
wire k_nb1 = (kind == 3'd2);
wire k_nb  = k_nb0 || k_nb1;
wire k_nr  = (kind == 3'd3);
wire k_ni  = (kind == 3'd4);
wire k_ob0 = (kind == 3'd5);
wire k_ob1 = (kind == 3'd6);
wire k_ob  = k_ob0 || k_ob1;
wire k_or  = (kind == 3'd7);

always @(posedge clk) begin
  if (rst) begin
    qc   <= 11'd0;
    kind <= 3'd0;
  end else begin
    qc <= bus_wen ? 11'd0 : ((qc == 11'h7ff) ? qc : qc + 11'd1);
    if (bus_wen) kind <= k_of_wr;
  end
end

//////////////////////////////////////////////////////////////////////////////
// reset values (datasheet Table 10 reset column, Table 8/4.2 for dividers)
//////////////////////////////////////////////////////////////////////////////

// Source: Table 10 (ien, irq, pwr, cyc, ovd, rst reset 0); RTL reset branches.
a_rst_ctl_regs: assert property (
  $past(rst) |-> (!irq_ena && !irq_sts && owr_pwr == 0 && !owr_cyc &&
                  !owr_ovd && !owr_rst && !owr_oen));

// Source: Section 4.2 - divider ratio registers reset to CDR_N / CDR_O.
a_rst_cdr: assert property ($past(rst) |-> (cdr_n == CDR_N && cdr_o == CDR_O));

// Source: RTL reset of divider/counter; reset state is idle.
a_rst_div_cnt: assert property ($past(rst) |-> (div == 0 && cnt == 0));

// Source: Section 2.2.2 / Table 10 - outputs are inactive after reset (owr_p=pwr=0,
// owr_e follows owr_oen which is 0, interrupt masked).
a_rst_outputs: assert property ($past(rst) |-> (owr_p == 0 && owr_e == 0 && bus_irq == 0));

//////////////////////////////////////////////////////////////////////////////
// control register writes (Table 11)
//////////////////////////////////////////////////////////////////////////////

// Source: Table 11 bit 7 (ien). Written value is stored.
a_wr_ien: assert property (ctl_wr |=> irq_ena == $past(bus_wdt[7]));

// Source: Table 11 bit 6 (irq is cleared by a write - write-clear has priority
// over the end-of-cycle set, so irq is 0 after any control write).
a_wr_irq_clr: assert property (ctl_wr |=> !irq_sts);

// Source: Table 11 bit 1 (rst select).
a_wr_rst: assert property (ctl_wr |=> owr_rst == $past(bus_wdt[1]));

// Source: Table 11 bit 2 (ovd); overdrive is only enabled when OVD_E.
a_wr_ovd: assert property (ctl_wr |=> owr_ovd == ($past(bus_wdt[2]) && OVD_E));

// Source: Table 11 bit 4 (pwr); for OWN=1 the write drives owr_p[0].
a_wr_pwr: assert property (ctl_wr |=> owr_p[0] == $past(bus_wdt[4]));

// Source: Table 11 bit 0 (dat write data).
a_wr_dat: assert property (ctl_wr |=> owr_dat == $past(bus_wdt[0]));

// Source: Table 11 bit 3 / Table 12 - writing cyc=1 with a non-zero-time
// cycle type starts (or restarts, breaking a running cycle) a 1-wire cycle.
a_wr_cyc_start: assert property (
  ctl_wr && bus_wdt[3] && (bus_wdt[2:0] != 3'b111) |=> owr_cyc);

// Source: Table 12 last row - overdrive ovd=rst=dat=1 is a 0us idle cycle: it
// does not start a cycle and does not drive the line.
a_wr_zero_time: assert property (
  ctl_wr && (bus_wdt[2:0] == 3'b111) |=> (!owr_cyc && !owr_oen));

//////////////////////////////////////////////////////////////////////////////
// read-back of control register and clock divider (end-to-end)
//////////////////////////////////////////////////////////////////////////////

// Source: Table 11. A control write followed by a control read returns the
// written ien, pwr, ovd, rst, dat bits; irq and the reserved bit read 0 (the write
// cleared irq). cyc (bit 3) is covered by a_wr_cyc_start / a_wr_zero_time.
a_rd_ctl_after_wr: assert property (
  ctl_wr ##1 (bus_ren && bus_adr == 0) |->
    (bus_rdt[7] == $past(bus_wdt[7]) && bus_rdt[6] == 1'b0 && bus_rdt[5] == 1'b0 &&
     bus_rdt[4] == $past(bus_wdt[4]) &&
     bus_rdt[2] == ($past(bus_wdt[2]) && OVD_E) &&
     bus_rdt[1] == $past(bus_wdt[1]) && bus_rdt[0] == $past(bus_wdt[0])));

// Source: Table 8 - bits 31..8 of the control/status address are not implemented
// for OWN=1 and read 0.
a_rd_ctl_unused: assert property (bus_ren && bus_adr == 0 |-> bus_rdt[31:8] == 0);

// Source: Section 4.2 / Table 8 - address 1 holds {cdr_o, cdr_n}; a write then a
// read returns the written word.
a_rd_cdr_after_wr: assert property (
  (bus_wen && bus_adr == 1) ##1 (bus_ren && bus_adr == 1) |-> (bus_rdt == $past(bus_wdt)));

//////////////////////////////////////////////////////////////////////////////
// hold behaviour
//////////////////////////////////////////////////////////////////////////////

// Source: Section 4.4 - ien, rst, ovd, pwr are only changed by a control write.
a_hold_cfg: assert property (
  !ctl_wr |=> ($stable(irq_ena) && $stable(owr_rst) && $stable(owr_ovd) && $stable(owr_pwr)));

// Source: Section 4.2 - divider ratios are only changed by a write to address 1.
a_hold_cdr: assert property (
  !(bus_wen && bus_adr == 1) |=> ($stable(cdr_n) && $stable(cdr_o)));

//////////////////////////////////////////////////////////////////////////////
// clock divider and cycle counter
//////////////////////////////////////////////////////////////////////////////

// Source: Section 4.2 / RTL divider - any bus write restarts the divider phase.
a_div_restart: assert property (bus_wen |=> div == 0);

// Source: RTL divider - a divider tick restarts the divider.
a_div_pls: assert property ((pls && !bus_wen) |=> div == 0);

// Source: RTL divider - the divider counts clocks only while a cycle is in progress.
a_div_count: assert property (
  (!bus_wen && !pls && owr_cyc) |=> (div == $past(div) + 1'b1));

// Source: RTL divider - the divider is frozen when idle (no cycle, no tick).
a_div_idle_hold: assert property (
  (!bus_wen && !pls && !owr_cyc) |=> $stable(div));

// Source: RTL cycle counter - it only changes on a control write or a divider tick.
a_cnt_hold: assert property ((!pls && !ctl_wr) |=> $stable(cnt));

// Source: RTL cycle counter - it counts down by one on each tick (wraps).
a_cnt_step: assert property ((pls && !ctl_wr) |=> (cnt == $past(cnt) - 1'b1));

//////////////////////////////////////////////////////////////////////////////
// interrupt
//////////////////////////////////////////////////////////////////////////////

// Source: Table 11 bit 7 - ien=0 masks the interrupt request.
a_irq_mask_off: assert property (!irq_ena |-> !bus_irq);

// Source: Section 2.2.1 - an enabled, pending status drives the interrupt request.
a_irq_mask_on: assert property ((irq_ena && irq_sts) |-> bus_irq);

// Source: Section 2.2.1 / Table 11 bit 6 - a read of the control register clears
// the status, unless a cycle ends in the same clock (end-of-cycle wins) or a
// control write happens (write wins).
a_irq_rd_clr: assert property (
  (bus_ren && bus_adr == 0 && !ctl_wr && !(pls && cnt == 0)) |=> !irq_sts);

// Source: Table 11 bit 6 - the status is set at the end of every 1-wire cycle
// (divider tick with cnt==0), unless a control write occurs in the same clock.
a_irq_tick_set: assert property (
  (!ctl_wr && pls && cnt == 0 && owr_cyc) |=> irq_sts);

// Source: Table 11 bit 6 - normal write0/write1 cycle (65 clocks) raises the status
// at its end.
a_irq_end_nb: assert property ((!bus_wen && k_nb && qc == 11'd65) |-> irq_sts);

// Source: Table 11 bit 6 - overdrive write0/write1 cycle (8 clocks) raises the status
// at its end.
a_irq_end_ob: assert property ((!bus_wen && k_ob && qc == 11'd8) |-> irq_sts);

// Source: Table 11 bit 6 - the status stays 0 during a normal bit cycle until it ends.
a_irq_quiet_nb: assert property ((!bus_wen && k_nb && qc <= 11'd64) |-> !irq_sts);

//////////////////////////////////////////////////////////////////////////////
// cycle duration (Table 7 / Table 12, in clocks)
//////////////////////////////////////////////////////////////////////////////

// Source: Table 12 normal write0/write1 65us, Table 7 tDAT0+tREC = 13 ticks.
// A cycle is busy from the write until 65 clocks have passed.
a_nb_busy: assert property ((!bus_wen && k_nb && qc <= 11'd64) |-> owr_cyc);
a_nb_end:  assert property ((!bus_wen && k_nb && qc == 11'd65) |-> !owr_cyc);

// Source: Table 12 normal reset 960us, Table 7 tRSTL+tRSTH = 192 ticks.
a_nr_busy: assert property ((!bus_wen && k_nr && qc <= 11'd959) |-> owr_cyc);
a_nr_end:  assert property ((!bus_wen && k_nr && qc == 11'd960) |-> !owr_cyc);

// Source: Table 12 normal timed idle 1000us, RTL t_idl = 200 ticks.
a_ni_busy: assert property ((!bus_wen && k_ni && qc <= 11'd999) |-> owr_cyc);
a_ni_end:  assert property ((!bus_wen && k_ni && qc == 11'd1000) |-> !owr_cyc);

// Source: Table 12 overdrive write0/write1 8us, 8 ticks of 1 clock each.
a_ob_busy: assert property ((!bus_wen && k_ob && qc <= 11'd7) |-> owr_cyc);
a_ob_end:  assert property ((!bus_wen && k_ob && qc == 11'd8) |-> !owr_cyc);

// Source: Table 12 overdrive reset 96us, 96 ticks of 1 clock each.
a_or_busy: assert property ((!bus_wen && k_or && qc <= 11'd95) |-> owr_cyc);
a_or_end:  assert property ((!bus_wen && k_or && qc == 11'd96) |-> !owr_cyc);

//////////////////////////////////////////////////////////////////////////////
// 1-wire line drive (owr_oen) timing (Table 7, RTL output-register chain)
//////////////////////////////////////////////////////////////////////////////

// Source: Table 7 tDAT0 = 60us = 12 ticks: write0 pulls the line low, released
// at the 12th tick (clock 60).
a_nb0_oen_hi:  assert property ((!bus_wen && k_nb0 && qc <= 11'd59) |-> owr_oen);
a_nb0_oen_rel: assert property ((!bus_wen && k_nb0 && qc == 11'd60) |-> !owr_oen);

// Source: Table 7 tDAT1 = 5us = 1 tick: write1 pulls the line low for one tick.
a_nb1_oen_hi:  assert property ((!bus_wen && k_nb1 && qc <= 11'd4) |-> owr_oen);
a_nb1_oen_rel: assert property ((!bus_wen && k_nb1 && qc == 11'd5) |-> !owr_oen);

// Source: Table 7 tRSTL = 480us = 96 ticks: reset pulls the line low, released at
// the 96th tick (clock 480).
a_nr_oen_hi:  assert property ((!bus_wen && k_nr && qc <= 11'd479) |-> owr_oen);
a_nr_oen_rel: assert property ((!bus_wen && k_nr && qc == 11'd480) |-> !owr_oen);

// Source: Section 4.4 / RTL - a timed idle cycle never drives the line.
a_ni_oen_lo: assert property ((!bus_wen && k_ni) |-> !owr_oen);

// Source: Table 7 overdrive tDAT0 = 6us = 6 ticks.
a_ob0_oen_hi:  assert property ((!bus_wen && k_ob0 && qc <= 11'd5) |-> owr_oen);
a_ob0_oen_rel: assert property ((!bus_wen && k_ob0 && qc == 11'd6) |-> !owr_oen);

// Source: Table 7 overdrive tDAT1 = 1us = 1 tick.
a_ob1_oen_hi:  assert property ((!bus_wen && k_ob1 && qc == 11'd0) |-> owr_oen);
a_ob1_oen_rel: assert property ((!bus_wen && k_ob1 && qc == 11'd1) |-> !owr_oen);

// Source: Table 7 overdrive tRSTL = 48us = 48 ticks.
a_or_oen_hi:  assert property ((!bus_wen && k_or && qc <= 11'd47) |-> owr_oen);
a_or_oen_rel: assert property ((!bus_wen && k_or && qc == 11'd48) |-> !owr_oen);

// Source: Section 4.3 / RTL - owr_e is owr_oen shifted by the (unassigned) select;
// a set owr_e bit implies the enable is set, for any select value.
a_e_implies_oen: assert property (owr_e |-> owr_oen);

//////////////////////////////////////////////////////////////////////////////
// data hold during a write cycle
//////////////////////////////////////////////////////////////////////////////

// Source: Section 4.5.1 / RTL - the data bit is only replaced at the end of the
// cycle, so a write0 keeps dat=0 until the cycle ends.
a_nb0_dat_hold: assert property ((!bus_wen && k_nb0 && qc <= 11'd64) |-> !owr_dat);

// Source: Section 4.5.1 / RTL - a write1 keeps dat=1 until the cycle ends.
a_nb1_dat_hold: assert property ((!bus_wen && k_nb1 && qc <= 11'd64) |-> owr_dat);

endmodule

// Bind to the design's top module. Parameters take the design's own values.
bind sockit_owm sockit_owm_sva #(
  .BDW(BDW), .BAW(BAW), .OWN(OWN), .OVD_E(OVD_E),
  .CDW(CDW), .TDW(TDW), .CDR_N(CDR_N), .CDR_O(CDR_O)
) u_sockit_owm_sva (.*);
