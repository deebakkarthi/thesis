// SVA checker for rtl/sockit_owm.v (default parameters: BDW=32, OWN=1, OVD_E=1, CDR_E=1)
// Timing constants below are the elaborated values for BTP_N="5.0", BTP_O="1.0".

module sockit_owm_sva #(
  parameter BDW = 32,
  parameter OWN = 1,
  parameter BAW = 1,
  parameter CDW = 16,
  parameter TDW = 8
) (
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
  input  [1:0]         owr_sel,   // SDW=0 -> 2-bit reg [-1:0], never written when OWN==1
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
  input                owr_smp,
  input                owr_oen,
  input                owr_iln,
  input                irq_ena,
  input                irq_sts,
  input                req_ovd,
  input                bus_ren_ctl_sts,
  input                bus_wen_ctl_sts,
  input                bus_wen_pwr_sel,
  input                bus_wen_cdr_n,
  input                bus_wen_cdr_o,
  input  [7:0]         bus_rdt_ctl_sts,
  input  [23:0]        bus_rdt_pwr_sel,
  input  [TDW-1:0]     t_idl,
  input  [TDW-1:0]     t_rst,
  input  [TDW-1:0]     t_bit,
  input  [TDW-1:0]     t_rstp,
  input  [TDW-1:0]     t_rsth,
  input  [TDW-1:0]     t_dat0,
  input  [TDW-1:0]     t_dat1,
  input  [TDW-1:0]     t_bits,
  input  [TDW-1:0]     t_zero
);

  default clocking cb @(posedge clk); endclocking
  default disable iff (rst);

  // ---------------------------------------------------------------------------
  // elaborated timing constants (normal / overdrive)
  // ---------------------------------------------------------------------------
  localparam K_CDR_N_RST = 4;   // CDR_N = 5-1
  localparam K_CDR_O_RST = 0;   // CDR_O = 1-1
  localparam K_IDL_N = 200, K_IDL_O = 96;
  localparam K_RST_N = 192, K_RST_O = 96;   // reset low + high
  localparam K_BIT_N = 13,  K_BIT_O = 8;    // DAT0 + RCVR
  localparam K_RSTP_N = 81, K_RSTP_O = 38;  // RSTH - RSTP
  localparam K_RSTH_N = 96, K_RSTH_O = 48;
  localparam K_DAT0_N = 1,  K_DAT0_O = 2;   // DAT0 - DAT0 + RCVR
  localparam K_DAT1_N = 12, K_DAT1_O = 7;   // DAT0 - DAT1 + RCVR
  localparam K_BITS_N = 10, K_BITS_O = 6;   // DAT0 - BITS + RCVR

  // ---------------------------------------------------------------------------
  // helper wires (mirror RTL conditions exactly)
  // ---------------------------------------------------------------------------
  wire [TDW-1:0] cnt_dec    = cnt - 1'b1;
  wire [TDW-1:0] ld_idl_m1  = t_idl - 1'b1;
  wire [TDW-1:0] ld_rst_m1  = t_rst - 1'b1;
  wire [TDW-1:0] ld_bit_m1  = t_bit - 1'b1;

  wire ev_end  = pls && (cnt == t_zero);                       // end of cycle
  wire ev_rstp = pls &&  owr_rst && (cnt == t_rstp);           // presence sample
  wire ev_bits = pls && !owr_rst && (cnt == t_bits);           // data bit sample
  wire ev_rsth = pls &&  owr_rst && (cnt == t_rsth);           // reset release (oen clear, prio 1)
  wire ev_dat1 = pls && !(owr_rst && cnt == t_rsth) &&
                 owr_dat && (cnt == t_dat1);                   // oen clear, prio 2
  wire ev_dat0 = pls && !(owr_rst && cnt == t_rsth) &&
                 !(owr_dat && cnt == t_dat1) && (cnt == t_dat0); // oen clear, prio 3
  wire ev_oen  = ev_rsth || ev_dat1 || ev_dat0;

  // ---------------------------------------------------------------------------
  // reset values. JasperGold starts traces from the reset state (reset
  // rst==1'b1) and rst is never high afterwards, so reset values are checked
  // in the reset state. in_rst_f is cleared by the async reset itself, so it
  // is 1 only in that state (it is not initializer-driven, which the reset
  // analysis would overwrite).
  // ---------------------------------------------------------------------------
  reg in_rst_f;
  always @(posedge clk, posedge rst)
    if (rst) in_rst_f <= 1'b1;
    else     in_rst_f <= 1'b0;

  a_rst_cdr_n:   assert property (disable iff (1'b0) in_rst_f |-> cdr_n == K_CDR_N_RST);
  a_rst_cdr_o:   assert property (disable iff (1'b0) in_rst_f |-> cdr_o == K_CDR_O_RST);
  a_rst_div:     assert property (disable iff (1'b0) in_rst_f |-> div == 0);
  a_rst_pwr:     assert property (disable iff (1'b0) in_rst_f |-> owr_pwr == 0);
  a_rst_irq_ena: assert property (disable iff (1'b0) in_rst_f |-> !irq_ena);
  a_rst_irq_sts: assert property (disable iff (1'b0) in_rst_f |-> !irq_sts);
  a_rst_ovd:     assert property (disable iff (1'b0) in_rst_f |-> !owr_ovd);
  a_rst_owr_rst: assert property (disable iff (1'b0) in_rst_f |-> !owr_rst);
  a_rst_dat:     assert property (disable iff (1'b0) in_rst_f |-> !owr_dat);
  a_rst_cyc:     assert property (disable iff (1'b0) in_rst_f |-> !owr_cyc);
  a_rst_oen:     assert property (disable iff (1'b0) in_rst_f |-> !owr_oen);
  a_rst_cnt:     assert property (disable iff (1'b0) in_rst_f |-> cnt == 0);

  // ---------------------------------------------------------------------------
  // address decode and request wires
  // ---------------------------------------------------------------------------
  a_dec_wen_ctl:   assert property (bus_wen_ctl_sts == (bus_wen && !bus_adr[0]));
  a_dec_wen_pwr:   assert property (bus_wen_pwr_sel == (bus_wen && !bus_adr[0]));
  a_dec_ren_ctl:   assert property (bus_ren_ctl_sts == (bus_ren && !bus_adr[0]));
  a_dec_wen_cdr_n: assert property (bus_wen_cdr_n == (bus_wen && bus_adr[0]));
  a_dec_wen_cdr_o: assert property (bus_wen_cdr_o == (bus_wen && bus_adr[0]));
  a_req_ovd:       assert property (req_ovd == (bus_wen_ctl_sts && bus_wdt[2]));

  // ---------------------------------------------------------------------------
  // timing wires
  // ---------------------------------------------------------------------------
  a_t_idl:  assert property (t_idl  == (req_ovd ? K_IDL_O : K_IDL_N));
  a_t_rst:  assert property (t_rst  == (req_ovd ? K_RST_O : K_RST_N));
  a_t_bit:  assert property (t_bit  == (req_ovd ? K_BIT_O : K_BIT_N));
  a_t_rstp: assert property (t_rstp == (owr_ovd ? K_RSTP_O : K_RSTP_N));
  a_t_rsth: assert property (t_rsth == (owr_ovd ? K_RSTH_O : K_RSTH_N));
  a_t_dat0: assert property (t_dat0 == (owr_ovd ? K_DAT0_O : K_DAT0_N));
  a_t_dat1: assert property (t_dat1 == (owr_ovd ? K_DAT1_O : K_DAT1_N));
  a_t_bits: assert property (t_bits == (owr_ovd ? K_BITS_O : K_BITS_N));
  a_t_zero: assert property (t_zero == 0);

  // ---------------------------------------------------------------------------
  // clock divider
  // ---------------------------------------------------------------------------
  a_cdr_n_wr:   assert property (bus_wen_cdr_n |=> cdr_n == $past(bus_wdt[15:0]));
  a_cdr_n_hold: assert property (!bus_wen_cdr_n |=> $stable(cdr_n));
  a_cdr_o_wr:   assert property (bus_wen_cdr_o |=> cdr_o == $past(bus_wdt[31:16]));
  a_cdr_o_hold: assert property (!bus_wen_cdr_o |=> $stable(cdr_o));

  a_pls:        assert property (pls == (div == (owr_ovd ? cdr_o : cdr_n)));
  a_div_wen:    assert property (bus_wen |=> div == 0);
  a_div_pls:    assert property (!bus_wen && pls |=> div == 0);
  a_div_cnt:    assert property (!bus_wen && !pls |=> div == $past(div) + $past(owr_cyc));

  // ---------------------------------------------------------------------------
  // power (OWN==1 branch)
  // ---------------------------------------------------------------------------
  a_pwr_wr:   assert property (bus_wen_pwr_sel |=> owr_pwr == $past(bus_wdt[4]));
  a_pwr_hold: assert property (!bus_wen_pwr_sel |=> $stable(owr_pwr));
  a_p_out:    assert property (owr_p == owr_pwr);
  a_e_out:    assert property (owr_e == (owr_oen << owr_sel));

  // ---------------------------------------------------------------------------
  // interrupt
  // ---------------------------------------------------------------------------
  a_irq_ena_wr:   assert property (bus_wen_ctl_sts |=> irq_ena == $past(bus_wdt[7]));
  a_irq_ena_hold: assert property (!bus_wen_ctl_sts |=> $stable(irq_ena));
  a_irq_out:      assert property (bus_irq == (irq_ena & irq_sts));

  a_irq_sts_wr:   assert property (bus_wen_ctl_sts |=> !irq_sts);
  a_irq_sts_set:  assert property (!bus_wen_ctl_sts && ev_end |=> irq_sts);
  a_irq_sts_clr:  assert property (!bus_wen_ctl_sts && !ev_end && bus_ren_ctl_sts |=> !irq_sts);
  a_irq_sts_hold: assert property (!bus_wen_ctl_sts && !ev_end && !bus_ren_ctl_sts |=> $stable(irq_sts));

  // ---------------------------------------------------------------------------
  // onewire control registers
  // ---------------------------------------------------------------------------
  a_ovd_wr:   assert property (bus_wen_ctl_sts |=> owr_ovd == $past(req_ovd));
  a_ovd_hold: assert property (!bus_wen_ctl_sts |=> $stable(owr_ovd));

  a_owrrst_wr:   assert property (bus_wen_ctl_sts |=> owr_rst == $past(bus_wdt[1]));
  a_owrrst_hold: assert property (!bus_wen_ctl_sts |=> $stable(owr_rst));

  a_dat_wr:   assert property (bus_wen_ctl_sts |=> owr_dat == $past(bus_wdt[0]));
  a_dat_smp:  assert property (!bus_wen_ctl_sts && ev_end |=> owr_dat == $past(owr_smp));
  a_dat_hold: assert property (!bus_wen_ctl_sts && !ev_end |=> $stable(owr_dat));

  a_cyc_wr:   assert property (bus_wen_ctl_sts |=> owr_cyc == $past(bus_wdt[3] & ~(&bus_wdt[2:0])));
  a_cyc_clr:  assert property (!bus_wen_ctl_sts && ev_end |=> !owr_cyc);
  a_cyc_hold: assert property (!bus_wen_ctl_sts && !ev_end |=> $stable(owr_cyc));

  // sample register (no reset in RTL; only updated under pls)
  a_smp_rst:  assert property (ev_rstp |=> owr_smp == $past(owr_iln));
  a_smp_bit:  assert property (ev_bits |=> owr_smp == $past(owr_iln));
  a_smp_hold: assert property (!(ev_rstp || ev_bits) |=> $stable(owr_smp));

  // output enable: per-branch with RTL if/else-if priority
  a_oen_wr:       assert property (bus_wen_ctl_sts |=> owr_oen == $past(~(&bus_wdt[1:0])));
  a_oen_clr_rst:  assert property (!bus_wen_ctl_sts && ev_rsth |=> !owr_oen);
  a_oen_clr_dat1: assert property (!bus_wen_ctl_sts && ev_dat1 |=> !owr_oen);
  a_oen_clr_dat0: assert property (!bus_wen_ctl_sts && ev_dat0 |=> !owr_oen);
  a_oen_hold:     assert property (!bus_wen_ctl_sts && !ev_oen |=> $stable(owr_oen));

  // ---------------------------------------------------------------------------
  // cycle counter: per-branch
  // ---------------------------------------------------------------------------
  a_cnt_idl:  assert property (bus_wen_ctl_sts && bus_wdt[1] && bus_wdt[0] |=> cnt == $past(ld_idl_m1));
  a_cnt_rst:  assert property (bus_wen_ctl_sts && bus_wdt[1] && !bus_wdt[0] |=> cnt == $past(ld_rst_m1));
  a_cnt_bit:  assert property (bus_wen_ctl_sts && !bus_wdt[1] |=> cnt == $past(ld_bit_m1));
  a_cnt_dec:  assert property (!bus_wen_ctl_sts && pls |=> cnt == $past(cnt_dec));
  a_cnt_hold: assert property (!bus_wen_ctl_sts && !pls |=> $stable(cnt));

  // ---------------------------------------------------------------------------
  // bus read data
  // ---------------------------------------------------------------------------
  a_rdt_ctl_sts: assert property (bus_rdt_ctl_sts == {irq_ena, irq_sts, 1'b0, owr_pwr[0], owr_cyc, owr_ovd, owr_rst, owr_dat});
  a_rdt_pwr_sel: assert property (bus_rdt_pwr_sel == 24'h0);
  a_rdt0:        assert property (!bus_adr[0] |-> bus_rdt == {24'h0, irq_ena, irq_sts, 1'b0, owr_pwr[0], owr_cyc, owr_ovd, owr_rst, owr_dat});
  a_rdt1:        assert property (bus_adr[0] |-> bus_rdt == {cdr_o, cdr_n});

  // ---------------------------------------------------------------------------
  // cover properties (reachable scenarios)
  // ---------------------------------------------------------------------------
  c_init_wr:      cover property (in_rst_f ##1 bus_wen_ctl_sts);
  c_wr_ctl_idle:  cover property (bus_wen_ctl_sts && bus_wdt[1] && bus_wdt[0]);
  c_wr_cdr_n:     cover property (bus_wen_cdr_n ##1 (cdr_n != K_CDR_N_RST));
  c_wr_cdr_o:     cover property (bus_wen_cdr_o ##1 (cdr_o != K_CDR_O_RST));
  c_ovd_enter:    cover property ($rose(owr_ovd));
  c_data_cycle:   cover property (owr_cyc && !owr_rst && pls);
  c_reset_cycle:  cover property (owr_cyc && owr_rst && pls);
  c_irq_rise:     cover property ($rose(irq_sts));
  c_irq_read_clr: cover property (irq_sts && bus_ren_ctl_sts ##1 !irq_sts);
  c_bus_irq:      cover property (bus_irq);
  c_oen_fall:     cover property ($fell(owr_oen));
  c_smp_hi:       cover property (ev_bits && owr_iln);
  c_rdt_cdr:      cover property (bus_adr[0] && (bus_rdt != 0));

endmodule

bind sockit_owm sockit_owm_sva #(.BDW(BDW), .OWN(OWN), .BAW(BAW), .CDW(CDW), .TDW(TDW))
  u_sva (.*);
