// SVA checker for sockit_owm (1-wire master), default parameters.
// Bound into the top module; port names match the design's signal names.
module sockit_owm_sva #(
  parameter BDW      = 32,
  parameter BAW      = 1,
  parameter OWN      = 1,
  parameter CDW      = 16,   // clock divider register width (BDW=32, CDR_E=1)
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
  input                clk,
  input                rst,
  input                bus_wen,
  input                bus_ren,
  input  [BAW-1:0]     bus_adr,
  input  [BDW-1:0]     bus_wdt,
  input  [BDW-1:0]     bus_rdt,
  input                bus_irq,
  input  [OWN-1:0]     owr_p,
  input  [OWN-1:0]     owr_e,
  input  [OWN-1:0]     owr_pwr,
  input                owr_oen,
  input                owr_cyc,
  input                owr_ovd,
  input                owr_rst,
  input                owr_dat,
  input                irq_ena,
  input                irq_sts,
  input                pls,
  input  [CDW-1:0]     div,
  input  [CDW-1:0]     cdr_n,
  input  [CDW-1:0]     cdr_o
);

  localparam PW = 9;  // enough for the longest cycle (192 base periods)

  default clocking @(posedge clk);
  endclocking
  default disable iff (rst);

  // ------------------------------------------------------------------------
  // Modelling state. Clocked and reset like the design. It records the
  // type of the last control write and counts base periods (pls) since it.
  // A cycle is restarted by every control write, so the state always refers
  // to the cycle that is currently in progress.
  // ------------------------------------------------------------------------

  // cycle length in base periods (1 base period = 1 pls), from the
  // datasheet Table 12 / Table 7 and the design parameters:
  //   write 0 / write 1 or read : T_DAT0 + T_RCVR
  //   reset and presence        : T_RSTL + T_RSTH
  //   timed idle (normal only)  : T_IDLE_N
  //   zero-time idle (ovd=1)    : no cycle is started, length 0
  function automatic [PW-1:0] cyc_len(input o, input r, input d);
    begin
      if (r && d)      cyc_len = o ? '0 : PW'(T_IDLE_N);
      else if (r)      cyc_len = o ? PW'(T_RSTL_O + T_RSTH_O) : PW'(T_RSTL_N + T_RSTH_N);
      else             cyc_len = o ? PW'(T_DAT0_O + T_RCVR_O) : PW'(T_DAT0_N + T_RCVR_N);
    end
  endfunction

  reg          mrst, mdat, movd;  // rst, dat, ovd bits of the last control write
  reg [PW-1:0] lenm;              // length of the cycle started by that write
  reg [PW-1:0] pc;                // base periods elapsed in the current cycle

  always @(posedge clk or posedge rst)
    if (rst) begin
      mrst <= 1'b0;
      mdat <= 1'b0;
      movd <= 1'b0;
      lenm <= '0;
      pc   <= '0;
    end else if (bus_wen & ~bus_adr[0]) begin
      mrst <= bus_wdt[1];
      mdat <= bus_wdt[0];
      movd <= bus_wdt[2];
      lenm <= cyc_len(bus_wdt[2], bus_wdt[1], bus_wdt[0]);
      pc   <= '0;
    end else if (owr_cyc & pls) begin
      pc   <= pc + 1'b1;
    end

  // ------------------------------------------------------------------------
  // Derived conditions
  // ------------------------------------------------------------------------
  wire wr_ctl = bus_wen & ~bus_adr[0];                     // control register write
  wire wr_st  = wr_ctl & bus_wdt[3] & ~(&bus_wdt[2:0]);    // starts a 1-wire cycle
  wire wr_zt  = wr_ctl & bus_wdt[3] &  (&bus_wdt[2:0]);    // zero-time idle write
  wire last   = (pc + 1'b1 == lenm);                       // this pulse ends the cycle
  wire end_ev = owr_cyc & pls & last;                      // end-of-cycle event

  wire lw0 = ~mrst & ~mdat;   // write 0 cycle
  wire lw1 = ~mrst &  mdat;   // write 1 / read cycle
  wire lr  =  mrst & ~mdat;   // reset and presence cycle
  wire li  =  mrst &  mdat;   // timed idle cycle

  // release points (in base periods) for the cycle mode in progress
  wire [PW-1:0] T0 = movd ? PW'(T_DAT0_O) : PW'(T_DAT0_N);  // write 0 low time
  wire [PW-1:0] T1 = movd ? PW'(T_DAT1_O) : PW'(T_DAT1_N);  // write 1 low time
  wire [PW-1:0] TL = movd ? PW'(T_RSTL_O) : PW'(T_RSTL_N);  // reset low time

  // ------------------------------------------------------------------------
  // Reset values
  // The reset is asynchronous, so the value is visible in the cycle after rst
  // is sampled high. The check is written as rst |=> ... with the default
  // disable iff turned off, because the default would disable it.
  // ------------------------------------------------------------------------

  // Source: datasheet Table 10 (reset 0 for ien, irq, pwr, cyc, ovd, rst);
  // Table 8/Sec 4.2 (cdr_n, cdr_o reset to the CDR_N / CDR_O parameters).
  // Holds because all these registers have an asynchronous reset.
  a_rst_cdr: assert property (disable iff (1'b0)
    rst |=> (cdr_n == CDR_N) && (cdr_o == CDR_O));

  // Source: datasheet Table 10 and Sec 4.3 (lines released after reset).
  // Holds because these registers have an asynchronous reset to 0.
  a_rst_ctl: assert property (disable iff (1'b0)
    rst |=> (owr_pwr == 0) && !owr_ovd && !owr_rst && !owr_cyc && !owr_oen &&
            !irq_ena && !irq_sts);

  // ------------------------------------------------------------------------
  // Register read-back
  // ------------------------------------------------------------------------

  // Source: Datasheet Table 11 (bits 7 ien, 4 pwr, 2 ovd, 1 rst) and Table 10.
  // A control write followed by a control read returns the written bits,
  // because these bits change only on a control write.
  a_rb_ctl: assert property (
    (bus_wen & ~bus_adr[0]) ##1 (bus_ren & ~bus_adr[0]) |->
      (bus_rdt[7] == $past(bus_wdt[7])) && (bus_rdt[4] == $past(bus_wdt[4])) &&
      (bus_rdt[2] == $past(bus_wdt[2])) && (bus_rdt[1] == $past(bus_wdt[1])));

  // Source: Datasheet Table 8 (address 1 holds cdr_o[31:16], cdr_n[15:0]) and
  // Sec 4.2. A write to address 1 is read back unchanged on the next cycle.
  a_rb_cdr: assert property (
    (bus_wen & bus_adr[0]) ##1 (bus_ren & bus_adr[0]) |-> bus_rdt == $past(bus_wdt));

  // ------------------------------------------------------------------------
  // Interrupt
  // ------------------------------------------------------------------------

  // Source: Datasheet Table 11 bit 6 and Sec 2.2.1 (status cleared by a read).
  // A control read that is not coincident with a base period end clears irq.
  a_irq_rd_clr: assert property (
    (bus_ren & ~bus_adr[0] & ~pls) |=> ~irq_sts);

  // Source: Datasheet Table 11 bit 6 (status is held until read) and the
  // irq logic in the RTL (only a control read or write clears it).
  a_irq_hold: assert property (
    (irq_sts & ~wr_ctl & ~(bus_ren & ~bus_adr[0])) |=> irq_sts);

  // Source: RTL interrupt logic: a control write has priority and clears irq.
  a_irq_wr_clr: assert property (wr_ctl |=> ~irq_sts);

  // Source: Datasheet Table 11 bit 6 ("set on end of 1-wire cycle").
  // The end event is the last base period of a cycle in progress.
  a_irq_set: assert property ((end_ev & ~wr_ctl) |=> irq_sts);

  // Source: Datasheet Table 11 bit 7 (ien enables the interrupt request).
  // The request appears on bus_irq one cycle after the end of an enabled cycle.
  a_irq_out: assert property ((end_ev & ~wr_ctl & irq_ena) |=> bus_irq);

  // ------------------------------------------------------------------------
  // Power output
  // ------------------------------------------------------------------------

  // Source: Datasheet Sec 4.3 ("pwr" drives owr_p[0] when OWN=1) and Table 11 bit 4.
  a_pwr_set: assert property ((wr_ctl & bus_wdt[4]) |=> owr_p[0]);
  a_pwr_clr: assert property ((wr_ctl & ~bus_wdt[4]) |=> ~owr_p[0]);

  // Source: Datasheet Sec 4.3 (power register only written by control write).
  // owr_p changes only on a control write.
  a_pwr_hold: assert property (~wr_ctl |=> $stable(owr_p));

  // ------------------------------------------------------------------------
  // 1-wire line driver
  // owr_e = owr_oen << owr_sel, and owr_sel is never driven when OWN=1, so
  // only the relation to owr_oen is specified here.
  // ------------------------------------------------------------------------

  // Source: Datasheet Sec 2.2.2 (owr_e is the pull-down enable) and RTL IO
  // section (owr_e = owr_oen shifted by owr_sel, one bit wide).
  a_e_gated: assert property (owr_e |-> owr_oen);

  // ------------------------------------------------------------------------
  // Cycle start, zero-time idle, abort, length
  // ------------------------------------------------------------------------

  // Source: Datasheet Table 11 bit 3 (cyc=1 starts a cycle, cyc reads status).
  a_cyc_start: assert property (wr_st |=> owr_cyc);

  // Source: Datasheet Table 12 row "1 1 1 0us zero time idle cycle".
  a_cyc_zero: assert property (wr_zt |=> ~owr_cyc);

  // Source: RTL control logic: a control write with cyc=0 clears owr_cyc.
  a_cyc_abort: assert property ((wr_ctl & ~bus_wdt[3]) |=> ~owr_cyc);

  // Source: Datasheet Table 12 durations (in base periods, Table 7). The cycle
  // ends on its last base period.
  a_cyc_end: assert property ((owr_cyc & pls & last & ~wr_ctl) |=> ~owr_cyc);

  // Source: Datasheet Table 12 durations. The cycle continues until its last
  // base period; it only changes on a pulse or a control write.
  a_cyc_hold: assert property ((owr_cyc & ~(pls & last) & ~wr_ctl) |=> owr_cyc);

  // ------------------------------------------------------------------------
  // Line driving per cycle type
  // ------------------------------------------------------------------------

  // Source: Datasheet Drawing 5 and Table 7 (write 0: line low for tDAT0 base
  // periods, then released). owr_oen is set by the write and cleared at the
  // base period T0, and it stays cleared until the cycle ends.
  a_w0_drive: assert property ((wr_st & ~bus_wdt[1] & ~bus_wdt[0]) |=> owr_oen);
  a_w0_hold: assert property ((owr_cyc & lw0 & ~wr_ctl & (pc < T0) &
                               ~(pls & (pc + 1'b1 == T0))) |=> owr_oen);
  a_w0_rel: assert property ((owr_cyc & lw0 & ~wr_ctl & pls & (pc + 1'b1 == T0))
                             |=> ~owr_oen);
  a_w0_after: assert property ((owr_cyc & lw0 & ~wr_ctl & (pc >= T0)) |=> ~owr_oen);

  // Source: Datasheet Drawing 6 and Table 7 (write 1 / read: line low for tDAT1
  // base periods, then released).
  a_w1_drive: assert property ((wr_st & ~bus_wdt[1] & bus_wdt[0]) |=> owr_oen);
  a_w1_hold: assert property ((owr_cyc & lw1 & ~wr_ctl & (pc < T1) &
                               ~(pls & (pc + 1'b1 == T1))) |=> owr_oen);
  a_w1_rel: assert property ((owr_cyc & lw1 & ~wr_ctl & pls & (pc + 1'b1 == T1))
                             |=> ~owr_oen);
  a_w1_after: assert property ((owr_cyc & lw1 & ~wr_ctl & (pc >= T1)) |=> ~owr_oen);

  // Source: Datasheet Drawing 4 and Table 7 (reset: line low for tRSTL base
  // periods, then released for the rest of the cycle).
  a_r_drive: assert property ((wr_st & bus_wdt[1] & ~bus_wdt[0]) |=> owr_oen);
  a_r_hold: assert property ((owr_cyc & lr & ~wr_ctl & (pc < TL) &
                              ~(pls & (pc + 1'b1 == TL))) |=> owr_oen);
  a_r_rel: assert property ((owr_cyc & lr & ~wr_ctl & pls & (pc + 1'b1 == TL))
                            |=> ~owr_oen);
  a_r_after: assert property ((owr_cyc & lr & ~wr_ctl & (pc >= TL)) |=> ~owr_oen);

  // Source: Datasheet Table 12 row "1 0 1 timed idle" / Sec 4.5.1: an idle
  // cycle does not drive the line. owr_oen is set only by a control write
  // with a non-idle cycle, so it stays low during the idle cycle.
  a_idle_rel: assert property ((owr_cyc & li) |-> ~owr_oen);

  // ------------------------------------------------------------------------
  // Data bit (dat) and divider
  // ------------------------------------------------------------------------

  // Source: Datasheet Table 11 bit 0 ("write: data transmit request").
  a_dat_wr1: assert property ((wr_st & bus_wdt[0]) |=> owr_dat);
  a_dat_wr0: assert property ((wr_st & ~bus_wdt[0]) |=> ~owr_dat);

  // Source: RTL: owr_dat changes only on a control write or at the end of a
  // cycle (the sampled bit is stored at the end). It holds during a cycle.
  a_dat_hold: assert property ((owr_cyc & ~wr_ctl & ~end_ev) |=> $stable(owr_dat));

  // Source: RTL clock divider logic: any bus write restarts the base-period
  // divider.
  a_div_restart: assert property (bus_wen |=> (div == 0));

endmodule

bind sockit_owm sockit_owm_sva #(
  .BDW(BDW), .BAW(BAW), .OWN(OWN),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_DAT0_N(T_DAT0_N),
  .T_DAT1_N(T_DAT1_N), .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_DAT0_O(T_DAT0_O),
  .T_DAT1_O(T_DAT1_O), .T_RCVR_O(T_RCVR_O)
) u_sockit_owm_sva (.*);
