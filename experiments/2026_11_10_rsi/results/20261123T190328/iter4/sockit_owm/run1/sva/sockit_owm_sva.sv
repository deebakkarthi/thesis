// ============================================================================
// SVA checker for sockit_owm (1-wire master, Avalon-style 32-bit bus).
//
// Default configuration only: BDW=32, BAW=1, OWN=1, OVD_E=1, CDR_E=1,
// BTP_N="5.0", BTP_O="1.0".  Derived: CDR_N=4, CDR_O=0, cnt/TDW=8, div/cdr 16b.
//
// Notes on the RTL that shaped the assertions (all checked by hand):
//  * owr_sel is only given a value by an `initial` block when OWN==1, so it is
//    never assigned. owr_e and owr_iln (and so owr_smp, owr_dat after a cycle,
//    and bit 0 of the status read) are therefore unconstrained. Only the
//    implication owr_e[0] -> owr_oen is asserted on the driver output.
//  * pls = (div == (owr_ovd ? cdr_o : cdr_n)) is not gated by owr_cyc. With
//    cdr_o==0 (default) and owr_ovd==1, pls fires every clock even when idle,
//    so cnt keeps counting and irq_sts/owr_dat are updated at cnt==0 with no
//    cycle in progress. Properties that involve idle state exclude that event
//    (pls && cnt==0) explicitly.
//  * A 1-wire cycle is N ticks long, where a tick is one pls. Within a cycle,
//    cnt == N-1-ticks, so 'ticks' (an aux counter of pls while owr_cyc) gives
//    the documented durations without unrolling time.
// ============================================================================
module sockit_owm_sva #(
  parameter BDW      = 32,
  parameter BAW      = 1,
  parameter OWN      = 1,
  parameter TDW      = 8,
  parameter CDW      = 16,
  parameter CDR_N    = 4,
  parameter CDR_O    = 0,
  parameter T_RSTL_N = 96,
  parameter T_RSTH_N = 96,
  parameter T_DAT0_N = 12,
  parameter T_DAT1_N = 1,
  parameter T_RCVR_N = 1,
  parameter T_IDLE_N = 200,
  parameter T_RSTL_O = 48,
  parameter T_RSTH_O = 48,
  parameter T_DAT0_O = 6,
  parameter T_DAT1_O = 1,
  parameter T_RCVR_O = 2,
  parameter T_IDLE_O = 96
)(
  input                clk,
  input                rst,
  input                bus_ren,
  input                bus_wen,
  input  [BAW-1:0]     bus_adr,
  input  [BDW-1:0]     bus_wdt,
  input  [BDW-1:0]     bus_rdt,
  input                bus_irq,
  input  [OWN-1:0]     owr_e,
  input  [OWN-1:0]     owr_p,
  input  [CDW-1:0]     div,
  input  [CDW-1:0]     cdr_n,
  input  [CDW-1:0]     cdr_o,
  input                pls,
  input                owr_cyc,
  input  [TDW-1:0]     cnt,
  input  [OWN-1:0]     owr_pwr,
  input                owr_ovd,
  input                owr_rst,
  input                owr_dat,
  input                owr_oen,
  input                irq_ena,
  input                irq_sts
);

  // ------------------------------------------------------------------------
  // Constants derived from the design parameters (default configuration)
  // ------------------------------------------------------------------------
  localparam [15:0] RST_CDR_N = CDR_N;
  localparam [15:0] RST_CDR_O = CDR_O;

  // cycle length in ticks (pls), normal and overdrive
  localparam [7:0] LEN_W0_N  = T_DAT0_N + T_RCVR_N;          // 13  (65 us)
  localparam [7:0] LEN_RST_N = T_RSTL_N + T_RSTH_N;          // 192 (960 us)
  localparam [7:0] LEN_IDL_N = T_IDLE_N;                     // 200 (1000 us)
  localparam [7:0] LEN_W0_O  = T_DAT0_O + T_RCVR_O;          // 8   (8 us)
  localparam [7:0] LEN_RST_O = T_RSTL_O + T_RSTH_O;          // 96  (96 us)

  // ticks after which the line is released (low time), per cycle type
  localparam [7:0] LO_W0_N  = T_DAT0_N;
  localparam [7:0] LO_W0_O  = T_DAT0_O;
  localparam [7:0] LO_W1_N  = T_DAT1_N;
  localparam [7:0] LO_W1_O  = T_DAT1_O;
  localparam [7:0] LO_RST_N = T_RSTL_N;
  localparam [7:0] LO_RST_O = T_RSTL_O;

  // ------------------------------------------------------------------------
  // Auxiliary logic (same clock, same reset)
  //   ticks : number of pls edges since the last control write, counted only
  //           while a 1-wire cycle is active.
  //   sub   : clocks since the last pls or bus write (mirrors the divider).
  // ------------------------------------------------------------------------
  reg  [7:0]  ticks;
  reg  [15:0] sub;

  always @(posedge clk)
    if (rst) begin
      ticks <= 8'd0;
      sub   <= 16'd0;
    end else begin
      if (bus_wen && (bus_adr[0] == 1'b0))  ticks <= 8'd0;
      else if (pls && owr_cyc)              ticks <= ticks + 8'd1;
      if (bus_wen || pls)                   sub <= 16'd0;
      else if (sub != 16'hFFFF)             sub <= sub + 16'd1;
    end

  // ------------------------------------------------------------------------
  // Derived events
  // ------------------------------------------------------------------------
  wire wr_ctl   = bus_wen && (bus_adr[0] == 1'b0);      // control/status write
  wire wr_cdr   = bus_wen && (bus_adr[0] == 1'b1);      // clock divider write
  wire rd_ctl   = bus_ren && (bus_adr[0] == 1'b0);
  wire rd_cdr   = bus_ren && (bus_adr[0] == 1'b1);
  // a control write that starts a 1-wire cycle (zero-time idle excluded)
  wire wr_start = wr_ctl && bus_wdt[3] && !(&bus_wdt[2:0]);
  // a control write with rst=1, dat=1: line released, no cycle time
  wire wr_idle  = wr_ctl && (&bus_wdt[1:0]);
  // divider-level end of cycle (the design's own end-of-cycle event)
  wire cnt_zero_pls = pls && (cnt == 8'd0);

  wire [7:0] cyc_len = owr_ovd ? (owr_rst ? LEN_RST_O : LEN_W0_O)
                               : (owr_rst ? (owr_dat ? LEN_IDL_N : LEN_RST_N) : LEN_W0_N);
  wire [7:0] lo_w0  = owr_ovd ? LO_W0_O  : LO_W0_N;
  wire [7:0] lo_w1  = owr_ovd ? LO_W1_O  : LO_W1_N;
  wire [7:0] lo_rst = owr_ovd ? LO_RST_O : LO_RST_N;

  wire [CDW-1:0] ratio = owr_ovd ? cdr_o : cdr_n;

  wire cyc_end  = owr_cyc && pls && (ticks == cyc_len - 8'd1);   // last tick of a cycle
  wire ph_rst   = owr_cyc && owr_rst && !owr_dat;                 // reset cycle
  wire ph_w0    = owr_cyc && !owr_rst && !owr_dat;                // write-0 cycle
  wire ph_w1    = owr_cyc && !owr_rst && owr_dat;                 // write-1 / read cycle
  wire ph_idle  = owr_cyc && owr_rst && owr_dat;                  // timed idle cycle

  default clocking @(posedge clk); endclocking
  default disable iff (rst);

  // ========================================================================
  // 1. Reset values (checked in the first cycle after reset release)
  // ========================================================================

  // Doc Table 10 (reset column) and Table 9/4.2: cdr_n/cdr_o reset to CDR_N/CDR_O.
  // RTL: reset branch of the clock divider ratio registers.
  a_rst_cdr_val: assert property ($past(rst) |-> (cdr_n == RST_CDR_N && cdr_o == RST_CDR_O));

  // Doc Table 10 reset column: cyc, ovd, rst, dat, pwr, ien are 0.
  a_rst_ctl_val: assert property ($past(rst) |-> (!owr_cyc && !owr_ovd && !owr_rst && !owr_dat));

  // Doc Table 10 reset column: irq, ien, pwr are 0; output enable register is 0.
  a_rst_sts_val: assert property ($past(rst) |-> (!irq_sts && !irq_ena && (owr_pwr == 1'b0) && !owr_oen));

  // RTL: cnt and div are reset to 0 (counter start value).
  a_rst_cnt_val: assert property ($past(rst) |-> (cnt == 8'd0 && div == 16'd0));

  // Doc Table 8 and 10: a read of the control/status register after reset returns 0.
  a_rst_rd_ctl:  assert property ($past(rst) && rd_ctl |-> (bus_rdt == 32'd0));

  // Doc Table 8: address 1 reads cdr_o (bits 31:16) and cdr_n (bits 15:0), reset values.
  a_rst_rd_cdr:  assert property ($past(rst) && rd_cdr |-> (bus_rdt == {RST_CDR_O, RST_CDR_N}));

  // ========================================================================
  // 2. Register map and read data
  // ========================================================================

  // Doc Table 8: for OWN=1 the power and select fields are not implemented;
  // RTL: bus_rdt_pwr_sel is 24'h0 in the OWN==1 branch.
  a_rd_ctl_hi_zero: assert property (rd_ctl |-> (bus_rdt[31:8] == 24'd0));

  // Doc Table 10: bit 5 is reserved; RTL: constant 1'b0 in bus_rdt_ctl_sts.
  a_rd_ctl_rsv_zero: assert property (rd_ctl |-> (bus_rdt[5] == 1'b0));

  // Doc Table 11: bit 7 = ien (enable), bit 6 = irq (status of cycle interrupt).
  a_rd_ctl_irq: assert property (rd_ctl |-> (bus_rdt[7] == irq_ena && bus_rdt[6] == irq_sts));

  // Doc Table 11: bit 4 reads the power status of the line; with OWN=1 this is pwr.
  a_rd_ctl_pwr: assert property (rd_ctl |-> (bus_rdt[4] == owr_pwr[0]));

  // Doc Table 11: bit 3 reads 1 while a 1-wire cycle is in progress.
  a_rd_ctl_cyc: assert property (rd_ctl |-> (bus_rdt[3] == owr_cyc));

  // Doc Table 11: bit 2 = ovd (overdrive setting), bit 1 = rst (reset cycle select).
  a_rd_ctl_ovd_rst: assert property (rd_ctl |-> (bus_rdt[2] == owr_ovd && bus_rdt[1] == owr_rst));

  // Doc Table 8: address 1 returns {cdr_o, cdr_n}.
  a_rd_cdr_map: assert property (rd_cdr |-> (bus_rdt == {cdr_o, cdr_n}));

  // Write then read-back: a value written to address 1 is returned by the next read.
  a_wr_cdr_roundtrip: assert property ((wr_cdr ##1 rd_cdr) |-> (bus_rdt == $past(bus_wdt)));

  // Doc 4.2: ratios change only on a write to address 1 (no other event touches them).
  a_cdr_hold: assert property (!wr_cdr |=> (cdr_n == $past(cdr_n) && cdr_o == $past(cdr_o)));

  // Doc Table 11 and 4.4: after a control write, the writable bits read back,
  // and the interrupt status is cleared by the write (RTL: irq_sts priority).
  a_wr_ctl_roundtrip: assert property ((wr_ctl ##1 rd_ctl) |->
      (bus_rdt[7] == $past(bus_wdt[7]) && bus_rdt[4] == $past(bus_wdt[4]) &&
       bus_rdt[2] == $past(bus_wdt[2]) && bus_rdt[1] == $past(bus_wdt[1]) &&
       bus_rdt[0] == $past(bus_wdt[0]) && !bus_rdt[6]));

  // ========================================================================
  // 3. Cycle start, duration and end
  // ========================================================================

  // Doc Table 11 (cyc: 1 = start a new cycle) and Table 12 (non-idle cycles).
  a_cyc_start: assert property (wr_start |=> owr_cyc);

  // Doc Table 12: "zero time idle cycle" (ovd=1, rst=1, dat=1, cyc=1) is not run.
  a_cyc_zero_time: assert property ((wr_ctl && bus_wdt[3:0] == 4'hF) |=> !owr_cyc);

  // Doc Table 11: cyc=0 means no action; with no cycle running it starts nothing.
  a_cyc_idle_nostart: assert property ((wr_ctl && !bus_wdt[3] && !owr_cyc) |=> !owr_cyc);

  // Doc Table 12 / Table 7: a cycle lasts a fixed number of base periods (ticks).
  // The length depends on the mode and type bits latched by the starting write:
  //   normal write 13 ticks (65 us), normal reset 192 (960 us),
  //   normal idle 200 (1000 us), overdrive write 8 (8 us), overdrive reset 96 (96 us).
  // RTL: cnt is loaded with (length - 1) and decremented on each pls.
  a_cyc_bound: assert property (owr_cyc |-> (ticks < cyc_len));

  // A cycle keeps running until its last tick (absent a new control write).
  a_cyc_hold: assert property ((owr_cyc && !cyc_end && !wr_ctl) |=> owr_cyc);

  // The cycle ends exactly at its last tick.
  a_cyc_end: assert property ((cyc_end && !wr_ctl) |=> !owr_cyc);

  // Cycle-end is the only event that clears cyc besides a control write
  // (RTL: owr_cyc update is write / pls&&cnt==0).
  a_hold_cyc: assert property ((!wr_ctl && !cnt_zero_pls) |=> $stable(owr_cyc));

  // ========================================================================
  // 4. 1-wire line (open-drain driver) timing
  // ========================================================================

  // Doc Table 12 / 4.4: a write that starts a cycle drives the line low at once.
  // RTL: owr_oen <= ~&bus_wdt[1:0] on a control write.
  a_start_drive: assert property ((wr_start && !(&bus_wdt[1:0])) |=> owr_oen);

  // Doc Table 12: an idle (rst=1, dat=1) write releases the line.
  a_idle_write_release: assert property (wr_idle |=> !owr_oen);

  // Doc Table 7 (tRSTL), Table 6 (tDAT0, tDAT1): line low for T_RSTL / T_DAT0 / T_DAT1
  // base periods in a reset / write-0 / write-1 cycle, then released.
  // Normal: 96 / 12 / 1 ticks. Overdrive: 48 / 6 / 1 ticks.
  a_w0_low:      assert property (ph_w0 && (ticks < lo_w0)  |-> owr_oen);
  a_w0_release:  assert property (ph_w0 && (ticks >= lo_w0) |-> !owr_oen);
  a_w1_low:      assert property (ph_w1 && (ticks < lo_w1)  |-> owr_oen);
  a_w1_release:  assert property (ph_w1 && (ticks >= lo_w1) |-> !owr_oen);
  a_rst_low:     assert property (ph_rst && (ticks < lo_rst)  |-> owr_oen);
  a_rst_release: assert property (ph_rst && (ticks >= lo_rst) |-> !owr_oen);

  // Doc 4.4 / Table 12: a timed idle cycle never pulls the line down.
  a_idle_undriven: assert property (ph_idle |-> !owr_oen);

  // Output enable is only asserted when the output-enable register is set
  // (owr_e = owr_oen << owr_sel, and owr_sel is unconstrained for OWN=1).
  a_e_gated: assert property (owr_e[0] |-> owr_oen);

  // Doc 4.3: the power bit (bit 4) drives owr_p[0] (OWN=1).
  a_pwr_out:  assert property (wr_ctl |=> (owr_p == $past(bus_wdt[4])));
  a_pwr_hold: assert property (!wr_ctl |=> $stable(owr_p));

  // ========================================================================
  // 5. Hold properties (registers change only on their documented events)
  // ========================================================================

  // Doc Table 11: ovd, rst, pwr, ien are written only by a control write.
  a_hold_mode_bits: assert property (!wr_ctl |=> ($stable(owr_ovd) && $stable(owr_rst) &&
                                                  $stable(owr_pwr) && $stable(irq_ena)));

  // RTL: owr_dat changes on a control write or on the design's end-of-cycle event.
  a_hold_dat: assert property ((!wr_ctl && !cnt_zero_pls) |=> $stable(owr_dat));

  // RTL: owr_oen changes on a control write or on a pls.
  a_hold_oen: assert property ((!wr_ctl && !pls) |=> $stable(owr_oen));

  // RTL: cnt changes on a control write or on a pls.
  a_hold_cnt: assert property ((!wr_ctl && !pls) |=> $stable(cnt));

  // ========================================================================
  // 6. Clock divider (base period generator)
  // ========================================================================

  // Doc 2.1.3 / 3.1: any bus write re-aligns the divider (RTL: div <= 0 on bus_wen).
  a_wr_resets_div: assert property (bus_wen |=> (div == 16'd0));

  // With no cycle in progress the divider is at zero.
  a_div_idle_zero: assert property (!owr_cyc |-> (div == 16'd0));

  // Doc 2.1.3: one base period (tick) every (ratio+1) clocks while a cycle runs.
  // sub mirrors the elapsed clocks since the last tick or bus write.
  a_div_tick:  assert property (owr_cyc && (sub == ratio) |-> pls);
  a_div_quiet: assert property (owr_cyc && (sub <  ratio) |-> !pls);

  // ========================================================================
  // 7. Interrupt
  // ========================================================================

  // Doc Table 11: irq is set at the end of each 1-wire cycle.
  // RTL: irq_sts <= 1 on pls && cnt==0 unless a control write takes priority.
  a_irq_set: assert property ((cyc_end && !wr_ctl) |=> irq_sts);

  // Doc 4.4 / Table 11: a register read clears irq. Exception: the end-of-cycle
  // event has priority over the read clear (RTL priority chain).
  a_irq_rd_clear: assert property ((rd_ctl && !cnt_zero_pls) |=> !irq_sts);

  // Same-cycle collision: end of cycle wins over a read in that cycle.
  a_irq_end_beats_rd: assert property ((cyc_end && rd_ctl && !wr_ctl) |=> irq_sts);

  // RTL: irq_sts holds unless write, end-of-cycle or read event.
  a_irq_hold: assert property ((!wr_ctl && !cnt_zero_pls && !rd_ctl) |=> $stable(irq_sts));

  // Doc Table 11: ien enables the interrupt request output.
  a_irq_enabled: assert property ((cyc_end && !wr_ctl && irq_ena) |=> bus_irq);
  a_irq_masked:  assert property ((cyc_end && !wr_ctl && !irq_ena) |=> !bus_irq);

  // RTL: bus_irq = irq_ena & irq_sts.
  a_irq_out_en: assert property (bus_irq |-> irq_ena);
  a_irq_out_on: assert property ((irq_ena && irq_sts) |-> bus_irq);

endmodule

// Bind to the design top; parameters are taken from the design.
bind sockit_owm sockit_owm_sva #(
  .BDW(BDW), .BAW(BAW), .OWN(OWN), .TDW(TDW), .CDW(CDW),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTL_N(T_RSTL_N), .T_RSTH_N(T_RSTH_N), .T_DAT0_N(T_DAT0_N),
  .T_DAT1_N(T_DAT1_N), .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTL_O(T_RSTL_O), .T_RSTH_O(T_RSTH_O), .T_DAT0_O(T_DAT0_O),
  .T_DAT1_O(T_DAT1_O), .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);
