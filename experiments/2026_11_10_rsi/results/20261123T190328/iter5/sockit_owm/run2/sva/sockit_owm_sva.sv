// Specification checker for the sockit_owm 1-wire master, bound to the top
// module. Written for the default parameters (BDW=32, OWN=1, OVD_E=1,
// CDR_E=1, BTP_N="5.0", BTP_O="1.0"); the timing parameters are passed in so
// that the expressions use the design's own values.
//
// Auxiliary state (same clock and reset as the design):
//   tk_cnt  - base periods (divider ticks) elapsed since the running 1-wire
//             cycle was started by a control write. Cleared by every control
//             write, counts ticks only while owr_cyc is high.
// Derived values:
//   len_now - length in base periods of the cycle selected by the current
//             owr_ovd / owr_rst / owr_dat (the cnt reload value + 1).
//   tk_*    - tick index (tk_cnt value) at which the named RTL event happens.
//             cnt starts at len-1 and is decremented once per tick, so a
//             count value c is reached at tk = len-1-c.
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
  parameter T_RSTP_N = 15,
  parameter T_DAT0_N = 12,
  parameter T_DAT1_N = 1,
  parameter T_BITS_N = 3,
  parameter T_RCVR_N = 1,
  parameter T_IDLE_N = 200,
  parameter T_RSTH_O = 48,
  parameter T_RSTL_O = 48,
  parameter T_RSTP_O = 10,
  parameter T_DAT0_O = 6,
  parameter T_DAT1_O = 1,
  parameter T_BITS_O = 2,
  parameter T_RCVR_O = 2,
  parameter T_IDLE_O = 96
)(
  input               clk,
  input               rst,
  input               bus_ren,
  input               bus_wen,
  input  [BAW-1:0]    bus_adr,
  input  [BDW-1:0]    bus_wdt,
  input  [BDW-1:0]    bus_rdt,
  input               bus_irq,
  input  [OWN-1:0]    owr_p,
  input  [OWN-1:0]    owr_e,
  input  [CDW-1:0]    div,
  input  [CDW-1:0]    cdr_n,
  input  [CDW-1:0]    cdr_o,
  input               pls,
  input               owr_cyc,
  input  [TDW-1:0]    cnt,
  input  [OWN-1:0]    owr_pwr,
  input               owr_ovd,
  input               owr_rst,
  input               owr_dat,
  input               owr_smp,
  input               owr_oen,
  input               irq_ena,
  input               irq_sts
);

  //////////////////////////////////////////////////////////////////////////
  // helpers
  //////////////////////////////////////////////////////////////////////////

  wire ctl_wr    = bus_wen && (bus_adr[0] == 1'b0);   // bus_wen_ctl_sts
  wire ctl_rd    = bus_ren && (bus_adr[0] == 1'b0);   // bus_ren_ctl_sts
  wire cdr_wr    = bus_wen && (bus_adr[0] == 1'b1);
  wire cdr_rd    = bus_ren && (bus_adr[0] == 1'b1);
  wire tick_zero = pls && (cnt == '0);                // end-of-cycle tick
  wire cyc_end   = owr_cyc && tick_zero;

  // base periods elapsed in the running cycle
  reg  [TDW-1:0] tk_cnt;
  always @ (posedge clk or posedge rst)
    if (rst)                 tk_cnt <= '0;
    else if (ctl_wr)         tk_cnt <= '0;
    else if (pls && owr_cyc) tk_cnt <= tk_cnt + 1'b1;

  // cycle length (cnt reload value + 1) of the selected cycle type
  wire [TDW-1:0] len_now = TDW'(
      owr_ovd ? (owr_rst ? (owr_dat ? T_IDLE_O : T_RSTL_O + T_RSTH_O)
                         : (T_DAT0_O + T_RCVR_O))
              : (owr_rst ? (owr_dat ? T_IDLE_N : T_RSTL_N + T_RSTH_N)
                         : (T_DAT0_N + T_RCVR_N)));

  // tick index of the named events (see header)
  wire [TDW-1:0] tk_rel_rst = TDW'((owr_ovd ? T_RSTL_O : T_RSTL_N) - 1);               // release of reset low (cnt == t_rsth)
  wire [TDW-1:0] tk_pres    = TDW'((owr_ovd ? T_RSTL_O + T_RSTP_O : T_RSTL_N + T_RSTP_N) - 1); // presence sample (cnt == t_rstp)
  wire [TDW-1:0] tk_bits    = TDW'((owr_ovd ? T_BITS_O : T_BITS_N) - 1);               // data sample (cnt == t_bits)
  wire [TDW-1:0] tk_dat0    = TDW'((owr_ovd ? T_DAT0_O : T_DAT0_N) - 1);               // write-0 release (cnt == t_dat0)
  wire [TDW-1:0] tk_dat1    = TDW'((owr_ovd ? T_DAT1_O : T_DAT1_N) - 1);               // write-1 release (cnt == t_dat1)
  wire           smp_pt     = owr_rst ? (tk_cnt == tk_pres) : (tk_cnt == tk_bits);

  default clocking @(posedge clk); endclocking
  default disable iff (rst);

  //////////////////////////////////////////////////////////////////////////
  // reset values (Table 10 reset column, section 4.2, RTL reset branches)
  //////////////////////////////////////////////////////////////////////////

  // Table 10: ien, irq, pwr, cyc, ovd, rst reset to 0; section 4.2: divider
  // ratio registers reset to CDR_N / CDR_O. owr_dat resets to 0 in the RTL.
  // Source: Table 10 / RTL reset branches. Holds because all these registers
  // have an asynchronous reset to the listed value.
  a_rst_ctl: assert property ($past(rst) |-> (owr_cyc == 1'b0 && owr_rst == 1'b0 &&
             owr_ovd == 1'b0 && owr_dat == 1'b0 && owr_pwr == '0 && owr_oen == 1'b0 &&
             irq_ena == 1'b0 && irq_sts == 1'b0));

  // Source: section 4.2 (clock divider ratio registers reset to CDR_N / CDR_O).
  a_rst_cdr: assert property ($past(rst) |-> (cdr_n == CDR_N && cdr_o == CDR_O));

  // Source: RTL reset of the clock divider and the cycle counter. Both are
  // zero, so no tick is pending after reset.
  a_rst_div_cnt: assert property ($past(rst) |-> (div == '0 && cnt == '0));

  // Source: outputs derived from reset registers (interrupt, power, line
  // enable). With owr_oen reset to 0 the line is not driven.
  a_rst_outputs: assert property ($past(rst) |-> (bus_irq == 1'b0 && owr_p == '0 && owr_e == '0));

  //////////////////////////////////////////////////////////////////////////
  // register map and read/write behaviour (Tables 8, 10, 11)
  //////////////////////////////////////////////////////////////////////////

  // Table 8: address 0 is the control/status register; bits 31..8 are the
  // power/select field, which for OWN=1 is not implemented and reads 0.
  // Table 10: bit 5 is reserved (reads 0).
  // Source: Table 8, Table 10. Holds because the RTL drives these bits with
  // constant zero for OWN=1 and BDW=32.
  a_map_zero: assert property (ctl_rd |-> (bus_rdt[31:8] == '0 && bus_rdt[5] == 1'b0));

  // Table 10/11: bits 7 ien, 6 irq, 4 pwr, 3 cyc, 2 ovd, 1 rst, 0 dat read the
  // current state of the corresponding registers. Read data is combinational
  // from the registers, so a read in the same cycle as a write returns the
  // value before the write.
  // Source: Table 10/11. Holds because bus_rdt is built from these registers.
  a_map_ctl: assert property (ctl_rd |-> (bus_rdt[7:6] == {irq_ena, irq_sts} &&
             bus_rdt[4] == owr_pwr[0] && bus_rdt[3] == owr_cyc &&
             bus_rdt[2:0] == {owr_ovd, owr_rst, owr_dat}));

  // Table 8: address 1 holds cdr_o (bits 31..16) and cdr_n (bits 15..0).
  // Holds because the read-data mux selects these registers for address 1.
  a_map_cdr: assert property (cdr_rd |-> (bus_rdt == {cdr_o, cdr_n}));

  // Section 4.2: the divider ratio registers can be written and then read
  // back. Both halves are loaded by a write to address 1.
  // Source: Section 4.2. Holds because a write at address 1 loads cdr_n from
  // bus_wdt[15:0] and cdr_o from bus_wdt[31:16] on the same cycle.
  a_rb_cdr: assert property (cdr_wr ##1 cdr_rd |-> (bus_rdt == $past(bus_wdt)));

  // Table 10: ien is written from bit 7 and reads back.
  // Source: Table 10 (ien r/w). Holds because irq_ena is loaded on a control write.
  a_rb_ctl_ien: assert property (ctl_wr ##1 ctl_rd |-> (bus_rdt[7] == $past(bus_wdt[7])));

  // Table 11: bit 6 is cleared by a control write (interrupt cleared by status
  // access). The RTL clears irq_sts on every control write, so it reads 0 on
  // the next cycle.
  // Source: Table 10 / Table 11 (irq bit), RTL interrupt logic. Holds because a
  // control write has priority over the end-of-cycle set.
  a_rb_ctl_irq: assert property (ctl_wr ##1 ctl_rd |-> (bus_rdt[6] == 1'b0));

  // Table 11: bit 4 (pwr) written from bit 4 and read back.
  // Source: Table 11 (pwr, OWN=1 case). Holds because owr_pwr loads bus_wdt[4].
  a_rb_ctl_pwr: assert property (ctl_wr ##1 ctl_rd |-> (bus_rdt[4] == $past(bus_wdt[4])));

  // Table 11: bit 3 (cyc) reads back the cycle status set by the write. A write
  // with bit 3 set and not all of ovd/rst/dat set starts a cycle, so cyc reads 1.
  // Source: Table 11 (cyc), Table 12 (zero-time idle). Holds because owr_cyc is
  // loaded with bus_wdt[3] & ~&bus_wdt[2:0].
  a_rb_ctl_cyc: assert property (ctl_wr ##1 ctl_rd |->
                (bus_rdt[3] == $past(bus_wdt[3] & ~&bus_wdt[2:0])));

  // Table 11: bits 2..0 (ovd, rst, dat) read back what was written.
  // Source: Table 11. Holds because these registers load on a control write.
  a_rb_ctl_ovd_rst_dat: assert property (ctl_wr ##1 ctl_rd |-> (bus_rdt[2:0] == $past(bus_wdt[2:0])));

  // The divider ratio registers only change on an address-1 write.
  // Source: Table 8 / Section 4.2. Holds because cdr_n/cdr_o load only on
  // bus_wen_cdr_n / bus_wen_cdr_o, which are the same address-1 write.
  a_cdr_hold: assert property (!cdr_wr |=> ($stable(cdr_n) && $stable(cdr_o)));

  // Table 10/11: the control/status register bits (except irq and cyc, which
  // have their own rules) change only on a control write.
  // Source: Table 10 (ien, pwr, ovd, rst). Holds because the RTL loads these
  // registers only under the control-write enable.
  a_ctl_hold: assert property (!ctl_wr |=> ($stable(owr_pwr) && $stable(irq_ena) &&
              $stable(owr_ovd) && $stable(owr_rst)));

  // Bus writes to the control register load ovd and rst.
  // Source: Table 10/11. Holds because the RTL loads them from bus_wdt[2] and bus_wdt[1].
  a_wr_mode: assert property (ctl_wr |=> (owr_ovd == $past(bus_wdt[2]) && owr_rst == $past(bus_wdt[1])));

  // Any bus write restarts the clock divider.
  // Source: RTL clock divider logic (divider is cleared on bus_wen). Doc: the
  // divider ratios must be written while no cycle is in progress (Section 4.2).
  // Holds because the RTL resets div on any bus write.
  a_div_wr: assert property (bus_wen |=> div == '0);

  //////////////////////////////////////////////////////////////////////////
  // power and line outputs (Section 2.2.2, Section 4.3, Table 10 pwr)
  //////////////////////////////////////////////////////////////////////////

  // Section 4.3 / Table 11: with OWN=1 the pwr bit of the control register
  // directly controls owr_p[0] (line power enable).
  // Source: Section 4.3, Table 11. Holds because owr_p = owr_pwr, which loads bus_wdt[4].
  a_pwr_wr: assert property (ctl_wr |=> (owr_p == $past(bus_wdt[4])));

  // Section 4.3: power stays on until the next control write.
  // Source: Section 4.3. Holds because owr_pwr changes only on control writes.
  a_pwr_hold: assert property (!ctl_wr |=> $stable(owr_p));

  // Section 4.4: a control write that is not the zero-length idle sets the line
  // driver (owr_oen). The RTL loads owr_oen from the rst/dat bits on every
  // control write (not only on a started cycle).
  // Source: RTL output register (owr_oen). Holds by the RTL assignment on bus_wen_ctl_sts.
  a_oen_wr_drive: assert property (ctl_wr && !(&bus_wdt[1:0]) |=> owr_oen);

  // Table 12: the rst=1, dat=1 combination (idle) does not drive the line.
  // Source: Table 12 (idle cycle), RTL owr_oen load. Holds because owr_oen loads
  // ~&bus_wdt[1:0].
  a_oen_wr_idle: assert property (ctl_wr && (&bus_wdt[1:0]) |=> !owr_oen);

  // owr_oen changes only on a control write or a tick.
  // Source: RTL output register (update enable is bus_wen_ctl_sts or pls).
  // Holds by inspection of the RTL.
  a_oen_hold: assert property (!ctl_wr && !pls |=> $stable(owr_oen));

  // Source: owr_e = owr_oen << owr_sel (OWN=1). A zero line-enable shifts to
  // zero whatever owr_sel is, so owr_e is zero when owr_oen is zero.
  // Note: owr_sel is never assigned for OWN=1, so only properties independent
  // of owr_sel are asserted here.
  a_e_zero: assert property (!owr_oen |-> (owr_e == '0));

  // Source: owr_e = owr_oen << owr_sel with OWN=1. A 1-bit shifted result is
  // either owr_oen or zero, so a set owr_e bit implies owr_oen.
  a_e_only: assert property (owr_e != '0 |-> owr_oen);

  //////////////////////////////////////////////////////////////////////////
  // interrupt (Table 10 irq/ien, Section 2.2.1, Section 4.4)
  //////////////////////////////////////////////////////////////////////////

  // Section 2.2.1 / Table 10: the interrupt request is the enabled status.
  // Source: Section 2.2.1 and Table 10. Holds because bus_irq = irq_ena & irq_sts.
  a_irq_out: assert property (bus_irq == (irq_ena && irq_sts));

  // Table 10: ien is written from bit 7 and held otherwise.
  // Source: Table 10. Holds because irq_ena loads bus_wdt[7] on a control write.
  a_irq_ena_wr: assert property (ctl_wr |=> (irq_ena == $past(bus_wdt[7])));

  // Table 11: irq is set on the end of a 1-wire cycle. Write priority: a control
  // write in the same cycle clears the status instead.
  // Source: Table 11 (irq), RTL interrupt logic. Holds because the set condition
  // is pls & cnt==0 and the control write has priority in the same always block.
  // Note: the RTL also sets irq_sts on the same tick condition while owr_cyc is
  // low (see report); this assertion is restricted to real cycle ends.
  a_irq_set: assert property (cyc_end && !ctl_wr |=> irq_sts);

  // Section 2.2.1: with ien set, the interrupt output rises at the cycle end.
  // Source: Section 2.2.1 / Table 10. Holds because bus_irq = irq_ena & irq_sts.
  a_irq_set_out: assert property (cyc_end && !ctl_wr && irq_ena |=> bus_irq);

  // irq_sts rises only on a tick with zero count (its only set condition).
  // Source: RTL interrupt logic. Holds because the only assignment setting
  // irq_sts to one is on tick_zero.
  a_irq_rise: assert property ($rose(irq_sts) |-> $past(tick_zero));

  // Table 11: a control write clears the interrupt status.
  // Source: Table 11 (irq cleared by status read), RTL interrupt logic. Holds
  // because a control write has the highest priority.
  a_irq_wr_clr: assert property (ctl_wr |=> !irq_sts);

  // Section 2.2.1 / Table 11: a control read clears the interrupt status unless a
  // control write or an end-of-cycle tick takes priority in the same cycle.
  // Source: RTL interrupt logic. Holds by the RTL priority order.
  a_irq_rd_clr: assert property (ctl_rd && !ctl_wr && !tick_zero |=> !irq_sts);

  // irq_sts holds when no clear, set, or status-read event occurs.
  // Source: RTL interrupt logic. Holds because irq_sts is assigned only on these events.
  a_irq_hold: assert property (!ctl_wr && !ctl_rd && !tick_zero |=> $stable(irq_sts));

  //////////////////////////////////////////////////////////////////////////
  // cycle control and timing (Section 3.1, Section 4.4, Table 12)
  //////////////////////////////////////////////////////////////////////////

  // Table 11: writing cyc=1 starts a cycle, except the zero-length idle
  // (ovd=rst=dat=1), which Table 12 lists as 0 us.
  // Source: Table 11 (cyc), Table 12. Holds because owr_cyc loads
  // bus_wdt[3] & ~&bus_wdt[2:0] on a control write.
  a_cyc_start: assert property (ctl_wr && bus_wdt[3] && !(&bus_wdt[2:0]) |=> owr_cyc);

  // Table 11: writing cyc=0 starts no cycle.
  // Source: Table 11 (cyc: 0 - no action). Holds because owr_cyc loads 0 when bit 3 is 0.
  a_cyc_nostart: assert property (ctl_wr && !bus_wdt[3] |=> !owr_cyc);

  // Table 12: the zero-length idle (ovd=rst=dat=1) does not start a cycle status.
  // Source: Table 12, RTL owr_cyc load. Holds because owr_cyc loads 0 for &bus_wdt[2:0].
  a_cyc_nostart_zt: assert property (ctl_wr && (&bus_wdt[2:0]) |=> !owr_cyc);

  // Section 3.1 / Table 11: the cycle ends at the tick where the counter reaches
  // zero (end of cycle).
  // Source: Section 3.1, counter logic. Holds because owr_cyc is cleared on
  // pls & cnt==0 unless a control write takes priority.
  a_cyc_end: assert property (cyc_end && !ctl_wr |=> !owr_cyc);

  // Section 3.1: a running cycle continues until its end tick.
  // Source: Section 3.1. Holds because owr_cyc only changes on a control write
  // or on the end tick.
  a_cyc_hold: assert property (owr_cyc && !tick_zero && !ctl_wr |=> owr_cyc);

  // Section 4.5 / RTL: the divider is zero while no cycle runs. Holds because
  // it is cleared on bus writes and on every tick, and only counts while owr_cyc.
  a_cyc_idle_div: assert property (!owr_cyc |-> (div == '0));

  // RTL clock divider: while a cycle runs and there is no tick, the divider
  // advances by one each clock.
  // Source: RTL clock divider logic. Holds because div <= div + owr_cyc, and
  // div is cleared only by a tick (pls) or a bus write, both excluded here.
  a_div_count: assert property (owr_cyc && !pls && !bus_wen |=> (div == $past(div) + 1'b1));

  // Section 3.1 / Table 12: a running cycle has the length of its type
  // (reset, data bit, or timed idle, in normal or overdrive mode). The counter
  // is loaded with that length minus one on the start write and decremented
  // once per tick, so cnt + tk_cnt stays at len-1 for the whole cycle.
  // Source: Section 3.1, Table 12, RTL counter reload. Holds because the cycle
  // type (owr_ovd/owr_rst/owr_dat) changes only on a control write, and a
  // control write restarts the count (tk_cnt) and reloads cnt.
  a_cnt_len: assert property (owr_cyc |-> ((cnt + tk_cnt) == (len_now - TDW'(1))));

  // Section 3.1: the counter only moves on a tick or a control write.
  // Source: RTL counter logic. Holds because cnt is assigned only on a control
  // write or on pls.
  a_cnt_hold: assert property (!ctl_wr && !pls |=> $stable(cnt));

  // Section 3.1: the counter steps once per base period.
  // Source: RTL counter logic. Holds because cnt decrements on each pls unless
  // a control write reloads it.
  a_cnt_step: assert property (pls && !ctl_wr |=> (cnt == $past(cnt) - 1'b1));

  //////////////////////////////////////////////////////////////////////////
  // base period (tick) timing (Section 2.1.3, Section 3.2, Table 7)
  //////////////////////////////////////////////////////////////////////////

  // Overdrive base period is CDR_O+1 clocks. With the default CDR_O of 0 each
  // clock is one tick, i.e. 1 us base period (Table 7 "1.0" overdrive option).
  // Source: Section 2.1.3, Table 7. Holds because after a tick the divider is
  // zero and compares equal to cdr_o = CDR_O when the mode is overdrive.
  a_tick_ovd: assert property (pls && !bus_wen && owr_ovd && cdr_o == CDR_O |=> pls);

  // The first tick after an overdrive control write with cyc=1 is immediate
  // (divider was cleared by the write and cdr_o = CDR_O).
  // Source: Section 2.1.3 / RTL divider. Holds because the write clears div and
  // owr_ovd takes bus_wdt[2].
  a_tick_ovd_first: assert property (ctl_wr && bus_wdt[2] && cdr_o == CDR_O |=> pls);

  // Normal base period is CDR_N+1 clocks; with the default CDR_N of 4 that is
  // 5 us (Table 7 "5.0" normal option). Checked from a tick with no bus write
  // and nonzero count, through four quiet clocks, to the next tick.
  // Source: Section 2.1.3, Table 7. Holds because the divider counts from zero
  // while a cycle runs and no write or tick interrupts it.
  a_tick_norm: assert property (
      (owr_cyc && pls && !bus_wen && !owr_ovd && cdr_n == CDR_N && cnt != '0)
      ##1 (!bus_wen && !pls)[*4] |-> ##1 pls);

  // The first normal tick after a control write that starts a cycle occurs
  // CDR_N+1 clocks after the write.
  // Source: Section 2.1.3, Section 3.2. Holds because the write clears the
  // divider and the divider then counts to CDR_N while owr_cyc is high.
  a_tick_norm_first: assert property (
      (ctl_wr && bus_wdt[3] && !bus_wdt[2] && cdr_n == CDR_N)
      ##1 (!bus_wen)[*4] |-> ##1 pls);

  //////////////////////////////////////////////////////////////////////////
  // 1-wire waveform phases (Section 3.2, Table 6, Table 7, Table 12)
  //////////////////////////////////////////////////////////////////////////

  // Write 1 / read slot: the line is released at the first tick, which is one
  // base period after the write (tDAT1 = 1 base period, Table 6/7).
  // Source: Section 3.2 (write 1/read timing), Table 7 (tDAT1). Holds because
  // the release at cnt == t_dat1 occurs at tk = T_DAT1 - 1 = 0.
  a_wr1_release: assert property (owr_cyc && !owr_rst && owr_dat && pls && tk_cnt == tk_dat1 |=> !owr_oen);

  // Write 0 slot: the line stays driven until tick T_DAT0 - 1 (tDAT0 base
  // periods, Table 7). Before that tick the line stays driven.
  // Source: Section 3.2 (write 0 timing), Table 7. Holds because the only
  // release for a data slot is at cnt == t_dat0, and that tick is later.
  a_wr0_hold: assert property (owr_cyc && !owr_rst && !owr_dat && pls && tk_cnt < tk_dat0 && !ctl_wr |=> owr_oen);

  // Write 0 slot: the line is released at tick T_DAT0 - 1 (tDAT0 base periods).
  // Source: Section 3.2, Table 7. Holds by the RTL release branch for data slots.
  a_wr0_release: assert property (owr_cyc && !owr_rst && !owr_dat && pls && tk_cnt == tk_dat0 |=> !owr_oen);

  // Reset pulse: the line is held low until tick T_RSTL - 1 (tRSTL base periods,
  // Table 7).
  // Source: Section 3.2, Table 6/7 (tRSTL), Section 4.5.1. Holds because the
  // reset-cycle release is at cnt == t_rsth, which is tick T_RSTL - 1.
  a_rst_hold: assert property (owr_cyc && owr_rst && !owr_dat && pls && tk_cnt < tk_rel_rst && !ctl_wr |=> owr_oen);

  // Reset pulse: the line is released at tick T_RSTL - 1 and stays released
  // until the cycle ends (tRSTH high phase).
  // Source: Section 3.2, Table 7. Holds by the reset release branch.
  a_rst_release: assert property (owr_cyc && owr_rst && !owr_dat && pls && tk_cnt == tk_rel_rst |=> !owr_oen);

  // Section 4.4: the data-bit result (dat) is only written at a control write or
  // at the end of a cycle.
  // Source: Table 11 (dat as read status), RTL owr_dat logic. Holds because owr_dat
  // is assigned only on a control write or on the end tick.
  a_dat_hold: assert property (!ctl_wr && !tick_zero |=> $stable(owr_dat));

  // A control write loads the dat bit from bus_wdt[0].
  // Source: Table 11 (dat write). Holds because owr_dat loads bus_wdt[0].
  a_dat_wr: assert property (ctl_wr |=> (owr_dat == $past(bus_wdt[0])));

  // At the end of a 1-wire cycle the sampled line value is copied to dat.
  // Source: Table 11 (dat is the receive status), RTL end-of-cycle logic. Holds
  // because owr_dat <= owr_smp on the end tick, and owr_smp keeps its value until
  // the next tick that samples it.
  a_dat_end: assert property (cyc_end && !ctl_wr |=> (owr_dat == $past(owr_smp)));

  // Sampling of the line is only done on a tick. Holds because owr_smp is
  // assigned only under pls.
  // Source: RTL sampling logic. Holds because owr_smp is assigned only inside the pls branch.
  a_smp_hold: assert property (!pls |=> $stable(owr_smp));

  // Within a running cycle, owr_smp changes only at the sample tick of the
  // selected cycle type (reset: T_RSTL+T_RSTP-1, data: T_BITS-1).
  // Source: Section 2.3, Section 3.2 (tDATS, presence sampling), RTL sampling
  // logic. Holds because the sampling conditions are cnt == t_rstp / cnt == t_bits
  // and tk_cnt tracks cnt in a running cycle.
  a_smp_window: assert property (owr_cyc && pls && !smp_pt |=> $stable(owr_smp));

endmodule

// Checker bound to the design top module, with the design's own parameters.
bind sockit_owm sockit_owm_sva #(
  .BAW(BAW), .BDW(BDW), .OWN(OWN), .CDW(CDW), .TDW(TDW),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_RSTP_N(T_RSTP_N),
  .T_DAT0_N(T_DAT0_N), .T_DAT1_N(T_DAT1_N), .T_BITS_N(T_BITS_N),
  .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_RSTP_O(T_RSTP_O),
  .T_DAT0_O(T_DAT0_O), .T_DAT1_O(T_DAT1_O), .T_BITS_O(T_BITS_O),
  .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);
