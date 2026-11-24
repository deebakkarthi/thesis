// SVA checker for sockit_owm (1-wire master), elaborated with default parameters:
// BDW=32, OWN=1, OVD_E=1, CDR_E=1, BTP_N="5.0", BTP_O="1.0".
// Sources: doc/sockit_owr.pdf sections 4.1-4.5, Tables 6-12; RTL rtl/sockit_owm.v.
module sockit_owm_sva #(
  parameter OVD_E = 1,
  parameter CDR_E = 1,
  parameter BDW   = 32,
  parameter OWN   = 1,
  parameter BAW   = 1,
  parameter BTP_N = "5.0",
  parameter BTP_O = "1.0",
  parameter CDR_N = 5-1,
  parameter CDR_O = 1-1
)(
  input logic           clk,
  input logic           rst,
  input logic           bus_ren,
  input logic           bus_wen,
  input logic [BAW-1:0] bus_adr,
  input logic [BDW-1:0] bus_wdt,
  input logic [BDW-1:0] bus_rdt,
  input logic           bus_irq,
  input logic [OWN-1:0] owr_p,
  input logic [OWN-1:0] owr_e,
  input logic [OWN-1:0] owr_i,
  // internal state of sockit_owm
  input logic           pls,
  input logic [15:0]    div,
  input logic [15:0]    cdr_n,
  input logic [15:0]    cdr_o,
  input logic [7:0]     cnt,
  input logic           owr_cyc,
  input logic [1:0]     owr_sel,
  input logic [OWN-1:0] owr_pwr,
  input logic           owr_ovd,
  input logic           owr_rst,
  input logic           owr_dat,
  input logic           owr_oen,
  input logic           irq_ena,
  input logic           irq_sts
);

  // Timing values, copied from the parameter block of sockit_owm (base periods).
  localparam int T_RSTH_N = (BTP_N == "7.5") ?  64 : (BTP_N == "5.0") ?  96 :  80;
  localparam int T_RSTL_N = (BTP_N == "7.5") ?  64 : (BTP_N == "5.0") ?  96 :  80;
  localparam int T_RSTP_N = (BTP_N == "7.5") ?  10 : (BTP_N == "5.0") ?  15 :  10;
  localparam int T_DAT0_N = (BTP_N == "7.5") ?   8 : (BTP_N == "5.0") ?  12 :  10;
  localparam int T_DAT1_N = (BTP_N == "7.5") ?   1 : (BTP_N == "5.0") ?   1 :   1;
  localparam int T_BITS_N = (BTP_N == "7.5") ?   2 : (BTP_N == "5.0") ?   3 :   2;
  localparam int T_RCVR_N = (BTP_N == "7.5") ?   1 : (BTP_N == "5.0") ?   1 :   1;
  localparam int T_IDLE_N = (BTP_N == "7.5") ? 128 : (BTP_N == "5.0") ? 200 : 160;
  localparam int T_RSTH_O = (BTP_O == "1.0") ?  48 :  96;
  localparam int T_RSTL_O = (BTP_O == "1.0") ?  48 :  96;
  localparam int T_RSTP_O = (BTP_O == "1.0") ?  10 :  15;
  localparam int T_DAT0_O = (BTP_O == "1.0") ?   6 :  12;
  localparam int T_DAT1_O = (BTP_O == "1.0") ?   1 :   2;
  localparam int T_BITS_O = (BTP_O == "1.0") ?   2 :   3;
  localparam int T_RCVR_O = (BTP_O == "1.0") ?   2 :   4;
  localparam int T_IDLE_O = (BTP_O == "1.0") ?  96 : 192;
  // Pulse index, counted from the control write, of the presence and data sample points.
  localparam int RIDX_N = T_RSTL_N + T_RSTP_N;
  localparam int RIDX_O = T_RSTL_O + T_RSTP_O;
  localparam int BIDX_N = T_BITS_N;
  localparam int BIDX_O = T_BITS_O;

  default clocking cb @(posedge clk); endclocking
  default disable iff (rst);

  wire       wen_c = bus_wen & ~bus_adr[0];        // write to control/status register (addr 0)
  wire       ren_c = bus_ren & ~bus_adr[0];        // read of control/status register (addr 0)
  wire       wen_d = bus_wen & bus_adr[0];         // write to clock divider registers (addr 1)
  wire       sel0  = (owr_sel == 2'd0);            // OWN=1: owr_sel is never written, so only line 0 is used
  wire [15:0] ridx = owr_ovd ? RIDX_O : RIDX_N;    // presence sample pulse index
  wire [15:0] bidx = owr_ovd ? BIDX_O : BIDX_N;    // data sample pulse index

  // Checker helpers. pcnt counts the divider pulses of the current cycle since the last
  // control write. rsmp / dsmp hold the line level taken at the presence / data sample pulse.
  logic [15:0] pcnt;
  logic        rsmp, dsmp;
  always_ff @(posedge clk) begin
    if (rst) begin
      pcnt <= '0;
      rsmp <= 1'b0;
      dsmp <= 1'b0;
    end else begin
      if (wen_c)                pcnt <= '0;
      else if (pls && owr_cyc)  pcnt <= pcnt + 16'd1;
      if (pls && owr_cyc && sel0) begin
        if ( owr_rst && (pcnt == ridx - 16'd1)) rsmp <= owr_i[0];
        if (!owr_rst && (pcnt == bidx - 16'd1)) dsmp <= owr_i[0];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Reset values (asserted in the first cycle after reset is released)
  // ---------------------------------------------------------------------------

  // Table 10: ien resets to 0
  a_rst_ien:    assert property ($fell(rst) |-> !irq_ena);
  // Table 10: irq resets to 0
  a_rst_irq:    assert property ($fell(rst) |-> !irq_sts);
  // Table 10: cyc resets to 0 (no cycle in progress)
  a_rst_cyc:    assert property ($fell(rst) |-> !owr_cyc);
  // Table 10: pwr resets to 0; Sec 4.3: all power is off after reset
  a_rst_pwr:    assert property ($fell(rst) |-> (owr_pwr == '0));
  a_rst_p_out:  assert property ($fell(rst) |-> (owr_p == '0));
  // Table 10: ovd and rst reset to 0
  a_rst_ovd:    assert property ($fell(rst) |-> !owr_ovd);
  a_rst_rst:    assert property ($fell(rst) |-> !owr_rst);
  // RTL: dat register resets to 0 (Table 10 leaves it unspecified)
  a_rst_dat:    assert property ($fell(rst) |-> !owr_dat);
  // Sec 4.2: ratio registers reset to CDR_N / CDR_O
  a_rst_cdr_n:  assert property ($fell(rst) |-> (cdr_n == CDR_N));
  a_rst_cdr_o:  assert property ($fell(rst) |-> (cdr_o == CDR_O));
  // RTL: divider and cycle counter reset to 0
  a_rst_div:    assert property ($fell(rst) |-> (div == 0));
  a_rst_cnt:    assert property ($fell(rst) |-> (cnt == 0));
  // Sec 4.3: after reset the line is not pulled down; no interrupt is pending
  a_rst_oen:    assert property ($fell(rst) |-> !owr_oen);
  a_rst_irq_o:  assert property ($fell(rst) |-> !bus_irq);

  // ---------------------------------------------------------------------------
  // Bus read-back of the control/status register and clock divider registers
  // ---------------------------------------------------------------------------

  // Table 10/11: rst is read/write; a read after a write returns the written bit
  a_bus_rst_rd: assert property (wen_c |=> (ren_c |-> (bus_rdt[1] == $past(bus_wdt[1]))));
  // Table 10: ovd is read/write (OVD_E=1)
  a_bus_ovd_rd: assert property (wen_c |=> (ren_c |-> (bus_rdt[2] == $past(bus_wdt[2]))));
  // Table 10: pwr is read/write (OWN=1)
  a_bus_pwr_rd: assert property (wen_c |=> (ren_c |-> (bus_rdt[4] == $past(bus_wdt[4]))));
  // Table 10: ien is read/write
  a_bus_ien_rd: assert property (wen_c |=> (ren_c |-> (bus_rdt[7] == $past(bus_wdt[7]))));
  // RTL: write of dat is visible on the next read, overriding any end-of-cycle update
  a_bus_dat_rd: assert property (wen_c |=> (ren_c |-> (bus_rdt[0] == $past(bus_wdt[0]))));
  // Table 11/12: cyc reads back 1 after a non-idle write; zero-time idle (111) starts no cycle
  a_bus_cyc_rd: assert property (wen_c |=> (ren_c |->
                  (bus_rdt[3] == ($past(bus_wdt[3]) && ($past(bus_wdt[2:0]) != 3'b111)))));
  // RTL: a control write clears the interrupt status (visible on the next read)
  a_bus_irq_clr: assert property (wen_c |=> (ren_c |-> !bus_rdt[6]));
  // Table 10: bit 5 is reserved and reads 0
  a_bus_rsv:    assert property (ren_c |-> !bus_rdt[5]);
  // RTL: power/select read data is zero when OWN=1 (bits 31..8 of address 0)
  a_bus_upper:  assert property (ren_c |-> (bus_rdt[31:8] == '0));
  // Sec 4.4: cyc reads the current cycle status
  a_bus_cyc_st: assert property (ren_c |-> (bus_rdt[3] == owr_cyc));
  // Table 11: irq reads the current interrupt status
  a_bus_irq_st: assert property (ren_c |-> (bus_rdt[6] == irq_sts));
  // Sec 4.1: address 1 holds {cdr_o, cdr_n}; a write is read back unchanged
  a_bus_cdr_rd: assert property (wen_d |=> ((bus_ren && bus_adr[0]) |-> (bus_rdt == $past(bus_wdt))));

  // ---------------------------------------------------------------------------
  // Effects of control writes and register hold behaviour
  // ---------------------------------------------------------------------------

  // RTL: a control write clears the interrupt status
  a_wr_irq_clr:    assert property (wen_c |=> !irq_sts);
  // Table 11/12: a write with cyc=1 and not 111 starts a 1-wire cycle
  a_wr_cyc_start:  assert property ((wen_c && bus_wdt[3] && (bus_wdt[2:0] != 3'b111)) |=> owr_cyc);
  // Table 12 and Sec 4.5.1: ovd=rst=dat=1 with cyc=1 is a zero-time idle, no cycle runs
  a_wr_zero_idle:  assert property ((wen_c && bus_wdt[3] && (bus_wdt[2:0] == 3'b111)) |=> !owr_cyc);
  // RTL: a control write sets dat, overriding an end-of-cycle update in the same cycle
  a_wr_dat_prio:   assert property (wen_c |=> (owr_dat == $past(bus_wdt[0])));
  // RTL: any bus write restarts the clock divider phase
  a_wr_div_clr:    assert property (bus_wen |=> (div == 0));
  // Table 10/11: rst, ovd, pwr and ien change only on a control-register write
  a_hold_rst:      assert property (!wen_c |=> $stable(owr_rst));
  a_hold_ovd:      assert property (!wen_c |=> $stable(owr_ovd));
  a_hold_pwr:      assert property (!wen_c |=> $stable(owr_pwr));
  a_hold_ien:      assert property (!wen_c |=> $stable(irq_ena));
  // Sec 4.1: ratio registers change only on an address-1 write
  a_hold_cdr_n:    assert property (!wen_d |=> $stable(cdr_n));
  a_hold_cdr_o:    assert property (!wen_d |=> $stable(cdr_o));

  // ---------------------------------------------------------------------------
  // Interrupt behaviour
  // ---------------------------------------------------------------------------

  // Sec 4.4 / Table 11: interrupt status is set at the end of each 1-wire cycle
  a_irq_set_end:   assert property ((owr_cyc && pls && (cnt == 0) && !wen_c) |=> irq_sts);
  // Table 11: an enabled interrupt request is raised after the cycle ends
  a_irq_bus_en:    assert property ((owr_cyc && pls && (cnt == 0) && !wen_c && irq_ena) |=> bus_irq);
  // Table 11: ien=0 disables the interrupt output
  a_irq_dis:       assert property (!irq_ena |-> !bus_irq);
  // Table 10/11: a read clears the interrupt status (unless the cycle ends in the same cycle)
  a_irq_rd_clr:    assert property ((ren_c && !wen_c && !(pls && (cnt == 0))) |=> !irq_sts);

  // ---------------------------------------------------------------------------
  // Cycle sequencing and counter progression
  // ---------------------------------------------------------------------------

  // RTL: the cycle counter steps down once per divider pulse
  a_cnt_dec:       assert property ((owr_cyc && pls && (cnt != 0) && !wen_c) |=> (cnt == $past(cnt) - 1));
  // RTL: the cycle counter does not move between divider pulses
  a_cnt_hold:      assert property ((owr_cyc && !pls && !wen_c) |=> $stable(cnt));
  // RTL: a cycle ends at the pulse where the counter is zero
  a_cyc_end:       assert property ((owr_cyc && pls && (cnt == 0) && !wen_c) |=> !owr_cyc);
  // RTL: an active cycle stays active until that end pulse or a control write
  a_cyc_hold:      assert property ((owr_cyc && !(pls && (cnt == 0)) && !wen_c) |=> owr_cyc);
  // RTL: counter stays inside the range of the longest normal / overdrive cycle
  a_cnt_rng_n:     assert property ((owr_cyc && !owr_ovd) |-> (cnt < T_IDLE_N));
  a_cnt_rng_o:     assert property ((owr_cyc && owr_ovd)  |-> (cnt < T_IDLE_O));

  // RTL: divider is cleared whenever no cycle is in progress
  a_div_idle:      assert property (!owr_cyc |-> (div == 0));
  // RTL: divider never runs past the active ratio during a cycle
  a_div_rng_n:     assert property ((owr_cyc && !owr_ovd) |-> (div <= cdr_n));
  a_div_rng_o:     assert property ((owr_cyc && owr_ovd)  |-> (div <= cdr_o));

  // ---------------------------------------------------------------------------
  // Cycle lengths in base periods (Table 7 / Table 12), counted in pulses of owr_cyc
  // ---------------------------------------------------------------------------

  // Table 12: reset-and-presence cycle (dat=0, rst=1) lasts tRSTL+tRSTH base periods (normal)
  a_len_rst_n: assert property ($fell(owr_cyc) && !$past(wen_c) && $past(owr_rst) && !$past(owr_dat) && !$past(owr_ovd)
                 |-> (pcnt == T_RSTL_N + T_RSTH_N));
  // Table 12: same, overdrive
  a_len_rst_o: assert property ($fell(owr_cyc) && !$past(wen_c) && $past(owr_rst) && !$past(owr_dat) && $past(owr_ovd)
                 |-> (pcnt == T_RSTL_O + T_RSTH_O));
  // Table 12: read/write slot (rst=0) lasts tDAT0+tRCVR base periods (normal)
  a_len_dat_n: assert property ($fell(owr_cyc) && !$past(wen_c) && !$past(owr_rst) && !$past(owr_ovd)
                 |-> (pcnt == T_DAT0_N + T_RCVR_N));
  // Table 12: same, overdrive
  a_len_dat_o: assert property ($fell(owr_cyc) && !$past(wen_c) && !$past(owr_rst) && $past(owr_ovd)
                 |-> (pcnt == T_DAT0_O + T_RCVR_O));
  // Table 12: timed idle (rst=1, dat=1, normal) lasts T_IDLE_N base periods (1 ms)
  a_len_idle_n: assert property ($fell(owr_cyc) && !$past(wen_c) && $past(owr_rst) && $past(owr_dat) && !$past(owr_ovd)
                 |-> (pcnt == T_IDLE_N));

  // ---------------------------------------------------------------------------
  // Line driver timing: release points in base periods after the cycle start
  // ---------------------------------------------------------------------------

  // Table 6/12: reset holds the line low for tRSTL (normal)
  a_rel_rst_n: assert property ($fell(owr_oen) && $past(owr_cyc) && $past(owr_rst) && !$past(wen_c) && !$past(owr_ovd)
                 |-> (pcnt == T_RSTL_N));
  // Table 6/12: same, overdrive
  a_rel_rst_o: assert property ($fell(owr_oen) && $past(owr_cyc) && $past(owr_rst) && !$past(wen_c) && $past(owr_ovd)
                 |-> (pcnt == T_RSTL_O));
  // Table 6/12: write-0 holds the line low for tDAT0 (normal)
  a_rel_w0_n:  assert property ($fell(owr_oen) && $past(owr_cyc) && !$past(owr_rst) && !$past(owr_dat) && !$past(wen_c) && !$past(owr_ovd)
                 |-> (pcnt == T_DAT0_N));
  // Table 6/12: same, overdrive
  a_rel_w0_o:  assert property ($fell(owr_oen) && $past(owr_cyc) && !$past(owr_rst) && !$past(owr_dat) && !$past(wen_c) && $past(owr_ovd)
                 |-> (pcnt == T_DAT0_O));
  // Table 6/12: write-1 holds the line low for tDAT1 (normal)
  a_rel_w1_n:  assert property ($fell(owr_oen) && $past(owr_cyc) && !$past(owr_rst) && $past(owr_dat) && !$past(wen_c) && !$past(owr_ovd)
                 |-> (pcnt == T_DAT1_N));
  // Table 6/12: same, overdrive
  a_rel_w1_o:  assert property ($fell(owr_oen) && $past(owr_cyc) && !$past(owr_rst) && $past(owr_dat) && !$past(wen_c) && $past(owr_ovd)
                 |-> (pcnt == T_DAT1_O));
  // Sec 4.5: the line is released by the end of every cycle
  a_rel_end:   assert property ($fell(owr_cyc) && !$past(wen_c) |-> !owr_oen);
  // Drawing 2 / Table 12: a non-idle cycle start pulls the line low immediately
  a_drv_start: assert property ((wen_c && bus_wdt[3] && (bus_wdt[1:0] != 2'b11) && sel0) |=> owr_e[0]);
  // Sec 4.5.1: a timed idle does not drive the line (power only)
  a_drv_idle:  assert property ((wen_c && (bus_wdt[1:0] == 2'b11) && sel0) |=> !owr_e[0]);
  // Table 11 bit 4: the power bit drives the line power output
  a_pwr_out:   assert property (wen_c |=> (owr_p[0] == $past(bus_wdt[4])));

  // ---------------------------------------------------------------------------
  // Data path: line sampled at the documented sample point, then reported in dat
  // ---------------------------------------------------------------------------

  // Table 11 / Table 7: read data bit (dat) is the line level sampled at tDATS
  a_dat_rcv:   assert property ($fell(owr_cyc) && !$past(wen_c) && !$past(owr_rst) && sel0 |-> (owr_dat == dsmp));
  // Table 11 / Table 6: presence status (dat) is the line level sampled at tRSTP
  // (RTL: idle cycles also sample presence)
  a_pres_rcv:  assert property ($fell(owr_cyc) && !$past(wen_c) && $past(owr_rst) && sel0 |-> (owr_dat == rsmp));

  // ---------------------------------------------------------------------------
  // Documentation / RTL mismatches. The documentation is the reference, so these
  // assertions state the documented behaviour; they are expected to FAIL on the RTL.
  // ---------------------------------------------------------------------------

  // DOC/RTL MISMATCH (Table 11: cyc=0 is "no action"): RTL loads owr_oen from rst/dat on
  // every control write, so a write with cyc=0 and not idle pulls the line low, with no
  // cycle to release it.
  x_doc_cyc0_line: assert property ((wen_c && !bus_wdt[3] && !owr_oen && sel0 && (bus_wdt[1:0] != 2'b11)) |=> !owr_e[0]);
  // DOC/RTL MISMATCH (Sec 4.4: irq set at end of each cycle): with CDR_O=0 (default), the
  // divider pulses every clock while idle in overdrive mode, so irq_sts is set with no cycle.
  x_doc_irq_cyc:   assert property ($rose(irq_sts) |-> $past(owr_cyc));
  // DOC/RTL MISMATCH (Sec 4.5.1, dat is the slot result): same free-running divider also
  // updates owr_dat with no cycle in progress.
  x_doc_dat_cyc:   assert property (($changed(owr_dat) && !$past(wen_c)) |-> $past(owr_cyc));

  // ---------------------------------------------------------------------------
  // Bind: attaches the checker to every sockit_owm instance
  // ---------------------------------------------------------------------------
endmodule

bind sockit_owm sockit_owm_sva #(
  .OVD_E(OVD_E), .CDR_E(CDR_E), .BDW(BDW), .OWN(OWN), .BAW(BAW),
  .BTP_N(BTP_N), .BTP_O(BTP_O), .CDR_N(CDR_N), .CDR_O(CDR_O)
) u_sockit_owm_sva (
  .clk(clk), .rst(rst),
  .bus_ren(bus_ren), .bus_wen(bus_wen), .bus_adr(bus_adr),
  .bus_wdt(bus_wdt), .bus_rdt(bus_rdt), .bus_irq(bus_irq),
  .owr_p(owr_p), .owr_e(owr_e), .owr_i(owr_i),
  .pls(pls), .div(div), .cdr_n(cdr_n), .cdr_o(cdr_o), .cnt(cnt),
  .owr_cyc(owr_cyc), .owr_sel(owr_sel), .owr_pwr(owr_pwr),
  .owr_ovd(owr_ovd), .owr_rst(owr_rst), .owr_dat(owr_dat), .owr_oen(owr_oen),
  .irq_ena(irq_ena), .irq_sts(irq_sts)
);
