// SVA checker for sockit_owm (1-wire master, 32-bit CPU bus).
// Specified at the default parameters: OVD_E=1, CDR_E=1, BDW=32, OWN=1,
// BTP_N="5.0", BTP_O="1.0". Timing values are passed in from the bind
// statement, so all tick counts come from the design's parameters.
//
// Deliberately not specified:
//  - owr_e, owr_iln and the value of owr_smp/owr_dat after a presence or
//    read sample: owr_sel is only assigned in an initial block when OWN=1,
//    so it is arbitrary, and the sampled line value is not constrained.
//  - Interrupt set and dat while the divider is free-running: when the
//    active divider ratio is 0 (default CDR_O=0 in overdrive), pls is high
//    in every idle cycle, so cnt/irq_sts/owr_dat move without a 1-wire
//    cycle. Properties that involve those registers are gated on owr_cyc
//    or on an end-of-period tick.

module sockit_owm_sva #(
  parameter BDW      = 32,
  parameter BAW      = 1,
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
  parameter T_RCVR_O = 2,
  parameter T_IDLE_O = 96
)(
  input                  clk,
  input                  rst,
  input                  bus_ren,
  input                  bus_wen,
  input  [BAW-1:0]       bus_adr,
  input  [BDW-1:0]       bus_wdt,
  input  [BDW-1:0]       bus_rdt,
  input                  bus_irq,
  input  [OWN-1:0]       owr_p,
  input  [OWN-1:0]       owr_pwr,
  input                  owr_ovd,
  input                  owr_rst,
  input                  owr_dat,
  input                  owr_smp,
  input                  owr_oen,
  input                  owr_cyc,
  input  [TDW-1:0]       cnt,
  input  [CDW-1:0]       div,
  input                  pls,
  input  [CDW-1:0]       cdr_n,
  input  [CDW-1:0]       cdr_o,
  input                  irq_ena,
  input                  irq_sts
);

default clocking @(posedge clk); endclocking
default disable iff (rst);

//////////////////////////////////////////////////////////////////////////////
// auxiliary logic
//////////////////////////////////////////////////////////////////////////////

// bus decode (address 0 = control/status, address 1 = clock divider ratios)
wire ctl_wen = bus_wen & ~bus_adr[0];
wire cdr_wen = bus_wen &  bus_adr[0];
wire ctl_ren = bus_ren & ~bus_adr[0];
wire cdr_ren = bus_ren &  bus_adr[0];

// end of a base period while the counter is at its last value
wire end_tk = pls & (cnt == 0);

// length of the running 1-wire cycle in base periods (type is held in
// owr_rst/owr_dat/owr_ovd for the whole cycle)
wire [31:0] t_len = owr_rst
                 ? (owr_dat ? (owr_ovd ? T_IDLE_O : T_IDLE_N)
                            : (owr_ovd ? T_RSTL_O + T_RSTH_O : T_RSTL_N + T_RSTH_N))
                 : (owr_ovd ? T_DAT0_O + T_RCVR_O : T_DAT0_N + T_RCVR_N);

// base periods after which the output phase changes
wire [31:0] t_rsth_sel = owr_ovd ? T_RSTH_O : T_RSTH_N;   // reset low phase
wire [31:0] t_dat0_sel = owr_ovd ? T_DAT0_O : T_DAT0_N;   // write-0 low phase
wire [31:0] t_dat1_sel = owr_ovd ? T_DAT1_O : T_DAT1_N;   // write-1 low phase

// base periods elapsed in the current 1-wire cycle (auxiliary tick counter)
reg [7:0] tk;
always @(posedge clk)
  if (rst || ctl_wen)          tk <= 8'd0;
  else if (pls && owr_cyc)     tk <= tk + 8'd1;

//////////////////////////////////////////////////////////////////////////////
// reset values (documentation Table 10; RTL reset branches)
//////////////////////////////////////////////////////////////////////////////

// Table 10 reset values: cyc/ien/irq/pwr/ovd/rst = 0
a_rst_cyc: assert property ($past(rst) |-> !owr_cyc);
a_rst_ovd: assert property ($past(rst) |-> !owr_ovd);
a_rst_rst: assert property ($past(rst) |-> !owr_rst);
// RTL reset branch of owr_dat (Table 10 lists it as x; RTL resets it to 0)
a_rst_dat: assert property ($past(rst) |-> !owr_dat);
a_rst_pwr: assert property ($past(rst) |-> (owr_pwr == 0) && (owr_p == 0));
a_rst_irq: assert property ($past(rst) |-> !irq_ena && !irq_sts && !bus_irq);
// RTL reset branch of the state counter and divider
a_rst_cnt: assert property ($past(rst) |-> (cnt == 0) && (div == 0));
// RTL reset branch of owr_oen (output not driven after reset)
a_rst_oen: assert property ($past(rst) |-> !owr_oen);
// section 4.2: cdr registers reset to CDR_N / CDR_O
a_rst_cdr: assert property ($past(rst) |-> (cdr_n == CDR_N) && (cdr_o == CDR_O));
// control/status reads as zero right after reset
a_rst_rd:  assert property ($past(rst) && ctl_ren |-> bus_rdt[7:0] == 8'h00);

//////////////////////////////////////////////////////////////////////////////
// register readback (write, then read in the next cycle)
//////////////////////////////////////////////////////////////////////////////

// Table 10/11: ien=bit7, pwr=bit4, cyc=bit3 (reads back as cycle status:
// writing cyc=1 with a non-zero-time type starts a cycle), ovd/rst/dat=bits
// 2..0, irq=bit6 (cleared by a control write), bit5 reserved (0)
a_rb_ctl: assert property (
  ctl_wen ##1 ctl_ren |-> bus_rdt[7:0] ==
    {$past(bus_wdt[7]), 2'b00, $past(bus_wdt[4]),
     $past(bus_wdt[3]) & ~&$past(bus_wdt[2:0]), $past(bus_wdt[2:0])});

// section 4.2: a write to address 1 sets cdr_o (bits 31:16) and cdr_n (15:0)
a_rb_cdr: assert property (
  cdr_wen ##1 cdr_ren |-> bus_rdt == {$past(bus_wdt[31:16]), $past(bus_wdt[15:0])});

// Table 8 / section 4.3: unused power and select bits read as zero with OWN=1
a_rd_unused: assert property (ctl_ren |-> bus_rdt[31:8] == 24'h000000);
// Table 11: read of cyc shows the cycle status
a_rd_cyc:    assert property (ctl_ren |-> bus_rdt[3] == owr_cyc);
// Table 11: read of pwr shows the line power state
a_rd_pwr:    assert property (ctl_ren |-> bus_rdt[4] == owr_p);
// Table 11: ien and irq read back their state
a_rd_irq:    assert property (ctl_ren |-> (bus_rdt[7] == irq_ena) && (bus_rdt[6] == irq_sts));

//////////////////////////////////////////////////////////////////////////////
// power output (section 4.3, Table 11 bit 4)
//////////////////////////////////////////////////////////////////////////////

// a control write sets the line power output directly (OWN=1)
a_pwr_set:  assert property (ctl_wen && bus_wdt[4]  |=> owr_p == 1'b1);
a_pwr_clr:  assert property (ctl_wen && !bus_wdt[4] |=> owr_p == 1'b0);
// power holds until the next control write, independent of 1-wire cycles
a_pwr_hold: assert property (!ctl_wen |=> $stable(owr_pwr));

//////////////////////////////////////////////////////////////////////////////
// interrupt (Table 11 bits 6/7; section 4.4)
//////////////////////////////////////////////////////////////////////////////

// a control write clears the cycle interrupt status (write has priority)
a_irq_wr_clr: assert property (ctl_wen |=> !irq_sts);
// the interrupt is set at the end of a 1-wire cycle (RTL: end-of-cycle tick)
a_irq_set:    assert property (owr_cyc && end_tk && !ctl_wen |=> irq_sts);
// bus_irq = irq_ena & irq_sts: a finished cycle raises the output when enabled
a_irq_out:    assert property (owr_cyc && end_tk && !ctl_wen && irq_ena |=> bus_irq);
// with the interrupt disabled, the end of a cycle does not raise bus_irq
a_irq_mask:   assert property (owr_cyc && end_tk && !ctl_wen && !irq_ena |=> !bus_irq);
// Table 11: a read of the control/status register clears irq (set wins)
a_irq_rd_clr: assert property (ctl_ren && !ctl_wen && !end_tk |=> !irq_sts);
// irq only changes on the events above; a read of cdr does not clear it
a_irq_hold:   assert property (!ctl_wen && !end_tk && !ctl_ren |=> $stable(irq_sts));
// ien only changes on a control write
a_ien_hold:   assert property (!ctl_wen |=> $stable(irq_ena));

//////////////////////////////////////////////////////////////////////////////
// cycle control and length (Table 12, section 4.4)
//////////////////////////////////////////////////////////////////////////////

// writing cyc=1 with a non-zero-time type starts a cycle (also breaks a running one)
a_cyc_start:  assert property (ctl_wen && bus_wdt[3] && !(&bus_wdt[2:0]) |=> owr_cyc);
// Table 12: ovd=1 rst=1 dat=1 is the zero-time idle, which starts no cycle
a_cyc_zero:   assert property (ctl_wen && bus_wdt[3] && (&bus_wdt[2:0]) |=> !owr_cyc);
// a write with cyc=0 does not start a cycle when none is running
a_cyc_nostart: assert property (ctl_wen && !bus_wdt[3] && !owr_cyc |=> !owr_cyc);
// cyc is only set by a control write
a_cyc_idle:   assert property (!owr_cyc && !ctl_wen |=> !owr_cyc);
// a running cycle stays until its last base period
a_cyc_hold:   assert property (owr_cyc && !ctl_wen && !end_tk |=> owr_cyc);
a_cyc_end:    assert property (owr_cyc && !ctl_wen && end_tk |=> !owr_cyc);
// Table 12 durations: the cycle ends at its t_len-th base period (tick counted in periods)
a_cyc_len:    assert property (owr_cyc && !ctl_wen && pls && (tk == t_len - 32'd1) |=> !owr_cyc);
// the state counter is loaded with t_len-1 and steps once per base period,
// so in every cycle it plus the tick counter equals t_len-1
a_cnt_inv:    assert property (owr_cyc |-> (({1'b0, cnt} + {1'b0, tk}) == (t_len - 32'd1)));
// the state counter only moves on a base period or a control write
a_cnt_hold:   assert property (!ctl_wen && !pls |=> $stable(cnt));

//////////////////////////////////////////////////////////////////////////////
// clock divider (section 4.2; base period = CDR+1 clocks)
//////////////////////////////////////////////////////////////////////////////

// a base-period tick restarts the divider
a_div_clr:    assert property (pls |=> div == 0);
// during a cycle without a tick or bus write, the divider counts up by one clock
a_div_cnt:    assert property (owr_cyc && !pls && !bus_wen |=> div == $past(div) + 1);

//////////////////////////////////////////////////////////////////////////////
// 1-wire output phase (section 3.2, Table 7/12). Phases are counted in base
// periods (tk), the same units the tick counter uses.
//////////////////////////////////////////////////////////////////////////////

// owr_oen only changes on a base period or a control write
a_oen_hold:   assert property (!pls && !ctl_wen |=> $stable(owr_oen));
// reset cycle: line pulled low for T_RSTH base periods, then released
a_oen_rst_lo: assert property (owr_cyc && owr_rst && !owr_dat && (tk < t_rsth_sel) |-> owr_oen);
a_oen_rst_hi: assert property (owr_cyc && owr_rst && !owr_dat && (tk >= t_rsth_sel) |-> !owr_oen);
// write-0 cycle: pulled low for T_DAT0 base periods
a_oen_w0_lo:  assert property (owr_cyc && !owr_rst && !owr_dat && (tk < t_dat0_sel) |-> owr_oen);
a_oen_w0_hi:  assert property (owr_cyc && !owr_rst && !owr_dat && (tk >= t_dat0_sel) |-> !owr_oen);
// write-1 / read cycle: pulled low for T_DAT1 base periods
a_oen_w1_lo:  assert property (owr_cyc && !owr_rst && owr_dat && (tk < t_dat1_sel) |-> owr_oen);
a_oen_w1_hi:  assert property (owr_cyc && !owr_rst && owr_dat && (tk >= t_dat1_sel) |-> !owr_oen);
// timed idle cycle (rst=1, dat=1): the line is never driven
a_oen_idle:   assert property (owr_cyc && owr_rst && owr_dat |-> !owr_oen);

//////////////////////////////////////////////////////////////////////////////
// data / state holds
//////////////////////////////////////////////////////////////////////////////

// during a cycle owr_dat (the transmitted bit) changes only at the end tick
a_dat_hold:   assert property (owr_cyc && !ctl_wen && !end_tk |=> $stable(owr_dat));
// the sample register is only written on a base period
a_smp_hold:   assert property (!pls |=> $stable(owr_smp));
// ovd and rst are only written by a control write
a_ovd_hold:   assert property (!ctl_wen |=> $stable(owr_ovd));
a_rst_hold:   assert property (!ctl_wen |=> $stable(owr_rst));
// clock divider ratios only change on an address-1 write
a_cdr_hold:   assert property (!cdr_wen |=> $stable(cdr_n) && $stable(cdr_o));

endmodule

bind sockit_owm sockit_owm_sva #(
  .BDW(BDW), .BAW(BAW), .OWN(OWN), .CDW(CDW), .TDW(TDW),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_DAT0_N(T_DAT0_N),
  .T_DAT1_N(T_DAT1_N), .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_DAT0_O(T_DAT0_O),
  .T_DAT1_O(T_DAT1_O), .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);
