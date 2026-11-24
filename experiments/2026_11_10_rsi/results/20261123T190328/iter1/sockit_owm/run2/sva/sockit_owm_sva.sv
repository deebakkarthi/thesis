//////////////////////////////////////////////////////////////////////////////
// SVA checker for sockit_owm (1-wire master, 32bit Avalon-style CPU bus).
//
// Sources:
//   doc/sockit_owr.pdf  sections 2.2, 4.1-4.5, Tables 8-12 (register map,
//                       control/status bits, cycle table), Table 7 (timing)
//   rtl/sockit_owm.v    timing block, counter, cycle/state logic
//
// Timing model used below (default parameters, BP = base period = CDR+1 clocks):
//   a started cycle keeps owr_cyc high for D clocks, its line-low phase
//   lasts RL clocks, the presence/read sample is taken SL clocks after the
//   start write, and the status/dat update happens at the end. The checker
//   tracks the clocks since the starting write with `el` (cycle t+k has
//   el==k). Any bus write (ctl or cdr) cancels the tracking (`act`), because
//   it resets the divider and may restart or abort the cycle.
//////////////////////////////////////////////////////////////////////////////
module sockit_owm_sva #(
  parameter  CDR_E    =  1,
  parameter  BDW      = 32,
  parameter  OWN      =  1,
  parameter  BAW      =  1,
  parameter  CDR_N    =  5-1,
  parameter  CDR_O    =  1-1,
  parameter  T_RSTH_N = 96,
  parameter  T_RSTL_N = 96,
  parameter  T_RSTP_N = 15,
  parameter  T_DAT0_N = 12,
  parameter  T_DAT1_N =  1,
  parameter  T_BITS_N =  3,
  parameter  T_RCVR_N =  1,
  parameter  T_IDLE_N = 200,
  parameter  T_RSTH_O = 48,
  parameter  T_RSTL_O = 48,
  parameter  T_RSTP_O = 10,
  parameter  T_DAT0_O =  6,
  parameter  T_DAT1_O =  1,
  parameter  T_BITS_O =  2,
  parameter  T_RCVR_O =  2,
  parameter  T_IDLE_O = 96,
  // widths of the design's counters, same formulas as the RTL
  parameter  CDW = CDR_E ? ((BDW==32) ? 16 : 8) : $clog2(CDR_N),
  parameter  TDW = ((T_RSTH_O+T_RSTL_O) > (T_RSTH_N+T_RSTL_N))
                   ? $clog2(T_RSTH_O+T_RSTL_O) : $clog2(T_RSTH_N+T_RSTL_N)
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
  input  [OWN-1:0]       owr_e,
  input                  owr_iln,
  input                  owr_cyc,
  input                  owr_oen,
  input  [OWN-1:0]       owr_pwr,
  input                  owr_ovd,
  input                  owr_rst,
  input                  owr_dat,
  input                  irq_ena,
  input                  irq_sts,
  input  [CDW-1:0]       cdr_n,
  input  [CDW-1:0]       cdr_o,
  input  [TDW-1:0]       cnt,
  input                  pls
);

//////////////////////////////////////////////////////////////////////////////
// derived timing constants (base periods unless noted)
//////////////////////////////////////////////////////////////////////////////

localparam int EW = 16;  // width of the clock timer (longest cycle: 1000 clocks)

// normal mode. Lengths are the counter start values (t_xxx-1 plus one) of the
// RTL; line-low and sample points are the RTL event counts (cnt==t_xxx).
localparam int DDAT_N  = T_DAT0_N + T_RCVR_N;           // write 0/1 or read slot: 13 BP (65 us)
localparam int DRST_N  = T_RSTL_N + T_RSTH_N;           // reset + presence:       192 BP (960 us)
localparam int DIDL_N  = T_IDLE_N;                      // timed idle:             200 BP (1000 us)
localparam int RDAT0_N = T_DAT0_N;                      // write 0 line-low:       12 BP (60 us)
localparam int RDAT1_N = T_DAT1_N;                      // write 1/read line-low:  1 BP (5 us)
localparam int RRST_N  = T_RSTL_N;                      // reset line-low:         96 BP (480 us)
localparam int SDAT_N  = T_BITS_N;                      // read sample point:      3 BP after start
localparam int SRST_N  = T_RSTL_N + T_RSTP_N;           // presence sample point:  111 BP after start
localparam int SIDL_N  = T_IDLE_N - T_RSTH_N + T_RSTP_N;// same point in idle:     119 BP after start

// overdrive mode
localparam int DDAT_O  = T_DAT0_O + T_RCVR_O;           // 8 BP (8 us)
localparam int DRST_O  = T_RSTL_O + T_RSTH_O;           // 96 BP (96 us)
localparam int RDAT0_O = T_DAT0_O;                      // 6 BP
localparam int RDAT1_O = T_DAT1_O;                      // 1 BP
localparam int RRST_O  = T_RSTL_O;                      // 48 BP
localparam int SDAT_O  = T_BITS_O;                      // 2 BP
localparam int SRST_O  = T_RSTL_O + T_RSTP_O;           // 58 BP

// cycle length in clocks for a ctl write with ovd=i_o, rst=i_r, dat=i_d
function automatic [EW-1:0] f_dlen(input logic i_o, i_r, i_d);
  if (i_o) return (i_r ? DRST_O : DDAT_O) * (CDR_O + 1);
  if (i_r) return (i_d ? DIDL_N : DRST_N) * (CDR_N + 1);
  return DDAT_N * (CDR_N + 1);
endfunction

// clock at which the line low phase ends (line released after this clock)
function automatic [EW-1:0] f_rlen(input logic i_o, i_r, i_d);
  if (i_o) return (i_r ? RRST_O : (i_d ? RDAT1_O : RDAT0_O)) * (CDR_O + 1);
  if (i_r) return i_d ? 0 : RRST_N * (CDR_N + 1);   // timed idle never drives the line
  return (i_d ? RDAT1_N : RDAT0_N) * (CDR_N + 1);
endfunction

// clock at which the presence / read bit is sampled
function automatic [EW-1:0] f_slen(input logic i_o, i_r, i_d);
  if (i_o) return (i_r ? SRST_O : SDAT_O) * (CDR_O + 1);
  if (i_r) return (i_d ? SIDL_N : SRST_N) * (CDR_N + 1);
  return SDAT_N * (CDR_N + 1);
endfunction

//////////////////////////////////////////////////////////////////////////////
// bus and event decode
//////////////////////////////////////////////////////////////////////////////

wire w0  = bus_wen & ~bus_adr[0];                 // write to control/status register
wire w1  = bus_wen &  bus_adr[0];                 // write to clock divider register
wire st  = w0 & bus_wdt[3] & ~(&bus_wdt[2:0]);    // write that starts a 1-wire cycle
wire zi  = w0 & (&bus_wdt[2:0]);                  // zero-time idle write (Table 12)
wire evt = pls & (cnt == 0);                      // end-of-counter event of the RTL

//////////////////////////////////////////////////////////////////////////////
// cycle tracker (checker-internal, same clock and reset as the design)
//////////////////////////////////////////////////////////////////////////////

reg          act;    // a cycle started by a ctl write is tracked, no bus write since
reg [EW-1:0] el;     // clocks since the starting write (cycle t+k has el == k)
reg [EW-1:0] dlen;   // expected cycle length in clocks
reg [EW-1:0] rlen;   // clock after which the line is released
reg [EW-1:0] slen;   // clock of the presence / read sample
reg          wdat;   // dat bit written by the starting write
reg          smp_v;  // line value captured at the sample point

always @ (posedge clk, posedge rst)
if (rst) begin
  act   <= 1'b0;
  el    <= 'd0;
  dlen  <= 'd0;
  rlen  <= 'd0;
  slen  <= 'd0;
  wdat  <= 1'b0;
  smp_v <= 1'b0;
end else if (st) begin
  act   <= 1'b1;
  el    <= 'd1;
  dlen  <= f_dlen(bus_wdt[2], bus_wdt[1], bus_wdt[0]);
  rlen  <= f_rlen(bus_wdt[2], bus_wdt[1], bus_wdt[0]);
  slen  <= f_slen(bus_wdt[2], bus_wdt[1], bus_wdt[0]);
  wdat  <= bus_wdt[0];
end else if (bus_wen) begin
  act   <= 1'b0;                                  // any bus write cancels tracking
end else if (act) begin
  if (el <= dlen + 1) el <= el + 1;               // saturates at dlen+2
  if (el == slen) smp_v <= owr_iln;
end

default clocking @(posedge clk); endclocking
default disable iff (rst);

//////////////////////////////////////////////////////////////////////////////
// reset values
//////////////////////////////////////////////////////////////////////////////

// Table 10 reset values (ien, irq, pwr, cyc, ovd, rst = 0); RTL also resets dat to 0.
// Checked in the first cycle after reset release, when the registers still hold the reset values.
a_rst_ctl: assert property ($past(rst) |->
  (irq_ena == 1'b0 && irq_sts == 1'b0 && owr_pwr == '0 && owr_cyc == 1'b0 &&
   owr_ovd == 1'b0 && owr_rst == 1'b0 && owr_dat == 1'b0));

// Sec 4.3: after reset all power bits are 0 (no pull-up power). Table 10/4.4: pull-down enable is off.
a_rst_line: assert property ($past(rst) |-> (owr_p == '0 && owr_e == '0));

// Sec 4.2: after reset cdr_n/cdr_o hold CDR_N/CDR_O.
a_rst_cdr: assert property ($past(rst) |-> (cdr_n == CDR_N && cdr_o == CDR_O));

//////////////////////////////////////////////////////////////////////////////
// control/status register: write then read back (Table 10, Sec 4.4)
//////////////////////////////////////////////////////////////////////////////

// Table 10 bit 7 ien: a written enable is read back.
a_rb_ien: assert property ((w0 ##1 !bus_adr[0]) |-> (bus_rdt[7] == $past(bus_wdt[7])));

// Table 10 bit 4 pwr (OWN=1): a written power bit is read back.
a_rb_pwr: assert property ((w0 ##1 !bus_adr[0]) |-> (bus_rdt[4] == $past(bus_wdt[4])));

// Table 10 bit 2 ovd: a written overdrive bit is read back.
a_rb_ovd: assert property ((w0 ##1 !bus_adr[0]) |-> (bus_rdt[2] == $past(bus_wdt[2])));

// Table 10 bit 1 rst: a written reset bit is read back.
a_rb_rst: assert property ((w0 ##1 !bus_adr[0]) |-> (bus_rdt[1] == $past(bus_wdt[1])));

// Table 10 bit 0 dat: a written data bit is read back (write data, before any cycle ends).
a_rb_dat: assert property ((w0 ##1 !bus_adr[0]) |-> (bus_rdt[0] == $past(bus_wdt[0])));

// Table 11 bit 3 cyc: reads 1 exactly when the write started a cycle (cyc=1, not zero-time idle).
a_rb_cyc: assert property ((w0 ##1 !bus_adr[0]) |->
  (bus_rdt[3] == $past(bus_wdt[3] & ~(&bus_wdt[2:0]))));

// Table 11 bit 6 irq: a write clears the status (RTL priority: write over set/read).
a_rb_irq_clr: assert property ((w0 ##1 !bus_adr[0]) |-> !bus_rdt[6]);

// Sec 4.2 / Table 8: clock divider registers are read back as written
// (address 1 writes both cdr_n and cdr_o, read as {cdr_o, cdr_n}).
a_rb_cdr: assert property ((w1 ##1 bus_adr[0]) |-> (bus_rdt == $past(bus_wdt)));

//////////////////////////////////////////////////////////////////////////////
// cycle start rules (Table 11 cyc, Table 12 zero-time idle)
//////////////////////////////////////////////////////////////////////////////

// Table 12: ovd=1 rst=1 dat=1 is a zero-time idle, no cycle is started.
a_zi_nocyc: assert property (zi |=> !owr_cyc);

// Table 11 cyc: a ctl write with cyc=0 does not start a cycle.
a_nostart_nocyc: assert property ((w0 && !bus_wdt[3]) |=> !owr_cyc);

// Table 12: the zero-time idle does not drive the 1-wire line.
a_zi_line: assert property (zi |=> (owr_e == '0));

//////////////////////////////////////////////////////////////////////////////
// cycle tracker properties: timing, line, sample and status (Table 7, Table 12)
//////////////////////////////////////////////////////////////////////////////

// Table 12 cycle lengths: write 0/1 or read 65us, reset 960us, timed idle 1000us
// in normal mode; write 0/1 or read 8us, reset 96us in overdrive mode (base 1 us).
// owr_cyc is high for exactly the cycle length, from the write until the end.
a_cyc_len: assert property (act |-> (owr_cyc == (el <= dlen)));

// Table 11 cyc status: the status bit cannot be set while a cycle is running.
a_cyc_busy_noirq: assert property (act && (el <= dlen) |-> !irq_sts);

// Table 11 bit 6 / Sec 2.2.1: the interrupt status is set at the end of a cycle.
a_cyc_end_irq: assert property (act && (el == dlen + 1) |-> irq_sts);

// Sec 2.2.1 / Table 10 bit 7: an enabled end-of-cycle interrupt is seen on bus_irq.
a_cyc_end_bus_irq: assert property (act && (el == dlen + 1) && irq_ena |-> bus_irq);

// Table 7 tDAT0/tDAT1/tRSTL and Sec 4.4 dat/rst: the line is driven low for the
// documented low time (write 0: 60 us, write 1/read: 5 us, reset: 480 us), and is released after that.
// Timed idle never drives the line (owr_oen stays 0).
a_cyc_line: assert property (act |-> (owr_oen == (el <= rlen)));

// Table 11 bit 0 dat: the write bit is held during the cycle.
a_cyc_dat_hold: assert property (act && (el <= dlen) |-> (owr_dat == wdat));

// Sec 4.4 dat / Table 7 tBITS and presence: at the end of a cycle, dat is the
// line value sampled at the sample point (read bit in data slots, presence in reset).
a_cyc_dat_latch: assert property (act && (el == dlen + 1) |-> (owr_dat == smp_v));

//////////////////////////////////////////////////////////////////////////////
// same-cycle priority (RTL: write > end-of-cycle set > read clear)
//////////////////////////////////////////////////////////////////////////////

// A ctl write in the cycle where a cycle would end clears the status (write wins).
a_pri_end_wr: assert property (act && (el == dlen) && w0 |=> !irq_sts);

// A ctl read in the cycle where a cycle ends does not lose the end status (set wins).
a_pri_end_rd: assert property (act && (el == dlen) && bus_ren && !bus_adr[0] && !bus_wen |=> irq_sts);

// Table 11 bit 6 / Sec 2.2.1: a ctl read clears the interrupt status (unless a new
// end-of-counter event sets it in the same cycle, see a_pri_end_rd).
a_rd_clr: assert property (bus_ren && !bus_adr[0] && !bus_wen && !evt |=> !bus_irq);

// Table 11 bit 7: a disabled interrupt never reaches bus_irq.
a_irq_en: assert property (!irq_ena |-> !bus_irq);

// Sec 4.2 / RTL: a clock divider write during a running cycle does not abort it.
a_cdrw_keep: assert property (owr_cyc && w1 && !evt |=> owr_cyc);

//////////////////////////////////////////////////////////////////////////////
// power and hold
//////////////////////////////////////////////////////////////////////////////

// Table 11 bit 4 / Sec 4.3: pwr=1 supplies power on the line (owr_p), output follows the written bit.
a_pwr_out: assert property ((w0 ##1 !bus_adr[0]) |-> (owr_p[0] == $past(bus_wdt[4])));

// Sec 4.3/4.4: pwr, ien, ovd and rst keep their value until the next control write.
a_hold_ctl: assert property (!w0 |=>
  ($stable(owr_pwr) && $stable(irq_ena) && $stable(owr_ovd) && $stable(owr_rst)));

// Sec 4.2: divider ratios keep their value until the next clock divider write.
a_hold_cdr: assert property (!w1 |=> ($stable(cdr_n) && $stable(cdr_o)));

endmodule

// Binds the checker to the top module, passing the design's own parameters.
bind sockit_owm sockit_owm_sva #(
  .CDR_E   (CDR_E),
  .BDW     (BDW),
  .OWN     (OWN),
  .BAW     (BAW),
  .CDR_N   (CDR_N),
  .CDR_O   (CDR_O),
  .T_RSTH_N(T_RSTH_N),
  .T_RSTL_N(T_RSTL_N),
  .T_RSTP_N(T_RSTP_N),
  .T_DAT0_N(T_DAT0_N),
  .T_DAT1_N(T_DAT1_N),
  .T_BITS_N(T_BITS_N),
  .T_RCVR_N(T_RCVR_N),
  .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O),
  .T_RSTL_O(T_RSTL_O),
  .T_RSTP_O(T_RSTP_O),
  .T_DAT0_O(T_DAT0_O),
  .T_DAT1_O(T_DAT1_O),
  .T_BITS_O(T_BITS_O),
  .T_RCVR_O(T_RCVR_O),
  .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);
