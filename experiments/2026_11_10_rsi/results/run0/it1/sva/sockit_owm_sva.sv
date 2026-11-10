// Checker for rtl/sockit_owm.v (default parameters: BDW=32, OWN=1, BAW=1,
// CDW=16, TDW=8). Bound with .* so checker inputs match RTL names.
module sockit_owm_sva #(parameter BDW=32, OWN=1, BAW=1, CDW=16, TDW=8) (
  input                              clk,
  input                              rst,
  // CPU bus
  input                              bus_ren,
  input                              bus_wen,
  input  [BAW-1:0]                   bus_adr,
  input  [BDW-1:0]                   bus_wdt,
  input  [BDW-1:0]                   bus_rdt,
  input                              bus_irq,
  // 1-wire
  input  [OWN-1:0]                   owr_p,
  input  [OWN-1:0]                   owr_e,
  input  [OWN-1:0]                   owr_i,
  // address decode and read segments
  input                              bus_ren_ctl_sts,
  input                              bus_wen_ctl_sts,
  input                              bus_wen_pwr_sel,
  input                              bus_wen_cdr_n,
  input                              bus_wen_cdr_o,
  input  [7:0]                       bus_rdt_ctl_sts,
  input  [(BDW==32 ? 24 : 8)-1:0]    bus_rdt_pwr_sel,
  // clock divider
  input  [CDW-1:0]                   div,
  input  [CDW-1:0]                   cdr_n,
  input  [CDW-1:0]                   cdr_o,
  input                              pls,
  // cycle control
  input                              owr_cyc,
  input  [TDW-1:0]                   cnt,
  input  [1:0]                       owr_sel,
  input                              req_ovd,
  input  [OWN-1:0]                   owr_pwr,
  input                              owr_ovd,
  input                              owr_rst,
  input                              owr_dat,
  input                              owr_smp,
  input                              owr_oen,
  input                              owr_iln,
  input                              irq_ena,
  input                              irq_sts,
  // timing wires
  input  [TDW-1:0]                   t_idl,
  input  [TDW-1:0]                   t_rst,
  input  [TDW-1:0]                   t_bit,
  input  [TDW-1:0]                   t_rstp,
  input  [TDW-1:0]                   t_rsth,
  input  [TDW-1:0]                   t_dat0,
  input  [TDW-1:0]                   t_dat1,
  input  [TDW-1:0]                   t_bits,
  input  [TDW-1:0]                   t_zero
);

default clocking cb @(posedge clk); endclocking
default disable iff (rst);

//////////////////////////////////////////////////////////////////////////////
// address decode
//////////////////////////////////////////////////////////////////////////////

a_dec_ren_ctl:   assert property (bus_ren_ctl_sts == (bus_ren && !bus_adr[0]));
a_dec_wen_ctl:   assert property (bus_wen_ctl_sts == (bus_wen && !bus_adr[0]));
a_dec_wen_pwr:   assert property (bus_wen_pwr_sel == (bus_wen && !bus_adr[0]));
a_dec_wen_cdr_n: assert property (bus_wen_cdr_n   == (bus_wen &&  bus_adr[0]));
a_dec_wen_cdr_o: assert property (bus_wen_cdr_o   == (bus_wen &&  bus_adr[0]));
a_req_ovd:       assert property (req_ovd == (bus_wen_ctl_sts && bus_wdt[2]));

//////////////////////////////////////////////////////////////////////////////
// timing wires (BTP_N="5.0", BTP_O="1.0")
//////////////////////////////////////////////////////////////////////////////

a_t_zero: assert property (t_zero == 8'd0);
a_t_idl:  assert property (t_idl  == (req_ovd ? 8'd96 : 8'd200));
a_t_rst:  assert property (t_rst  == (req_ovd ? 8'd96 : 8'd192));
a_t_bit:  assert property (t_bit  == (req_ovd ? 8'd8  : 8'd13));
a_t_rstp: assert property (t_rstp == (owr_ovd ? 8'd38 : 8'd81));
a_t_rsth: assert property (t_rsth == (owr_ovd ? 8'd48 : 8'd96));
a_t_dat0: assert property (t_dat0 == (owr_ovd ? 8'd2  : 8'd1));
a_t_dat1: assert property (t_dat1 == (owr_ovd ? 8'd7  : 8'd12));
a_t_bits: assert property (t_bits == (owr_ovd ? 8'd6  : 8'd10));

a_pls: assert property (pls == (div == (owr_ovd ? cdr_o : cdr_n)));

//////////////////////////////////////////////////////////////////////////////
// bus read
//////////////////////////////////////////////////////////////////////////////

a_rdt_ctl_sts: assert property (bus_rdt_ctl_sts ==
  {irq_ena, irq_sts, 1'b0, owr_pwr[0], owr_cyc, owr_ovd, owr_rst, owr_dat});
a_rdt_pwr_sel: assert property (bus_rdt_pwr_sel == '0);
a_rdt0: assert property (!bus_adr[0] |-> bus_rdt ==
  {24'h0, irq_ena, irq_sts, 1'b0, owr_pwr[0], owr_cyc, owr_ovd, owr_rst, owr_dat});
a_rdt1: assert property (bus_adr[0] |-> bus_rdt == {cdr_o, cdr_n});

//////////////////////////////////////////////////////////////////////////////
// interrupt
//////////////////////////////////////////////////////////////////////////////

a_irq_out: assert property (bus_irq == (irq_ena & irq_sts));

a_irq_ena_wr:   assert property (bus_wen_ctl_sts |=> irq_ena == $past(bus_wdt[7]));
a_irq_ena_hold: assert property (!bus_wen_ctl_sts |=> $stable(irq_ena));

a_irq_sts_wr:    assert property (bus_wen_ctl_sts |=> !irq_sts);
a_irq_sts_set:   assert property (!bus_wen_ctl_sts && pls && cnt == t_zero |=> irq_sts);
a_irq_sts_rd:    assert property (!bus_wen_ctl_sts && !(pls && cnt == t_zero) && bus_ren_ctl_sts |=> !irq_sts);
a_irq_sts_hold:  assert property (!bus_wen_ctl_sts && !(pls && cnt == t_zero) && !bus_ren_ctl_sts |=> $stable(irq_sts));

//////////////////////////////////////////////////////////////////////////////
// clock divider
//////////////////////////////////////////////////////////////////////////////

a_cdr_n_wr:   assert property (bus_wen_cdr_n |=> cdr_n == $past(bus_wdt[15:0]));
a_cdr_n_hold: assert property (!bus_wen_cdr_n |=> $stable(cdr_n));
a_cdr_o_wr:   assert property (bus_wen_cdr_o |=> cdr_o == $past(bus_wdt[31:16]));
a_cdr_o_hold: assert property (!bus_wen_cdr_o |=> $stable(cdr_o));

a_div_wen: assert property (bus_wen |=> div == 0);
a_div_pls: assert property (!bus_wen && pls |=> div == 0);
a_div_cnt: assert property (!bus_wen && !pls |=> div == $past(div) + $past(owr_cyc));

//////////////////////////////////////////////////////////////////////////////
// onewire cycle control
//////////////////////////////////////////////////////////////////////////////

a_owr_pwr_wr:   assert property (bus_wen_ctl_sts |=> owr_pwr == $past(bus_wdt[4]));
a_owr_pwr_hold: assert property (!bus_wen_ctl_sts |=> $stable(owr_pwr));

a_owr_sel_stable: assert property ($stable(owr_sel));

a_owr_rst_wr:   assert property (bus_wen_ctl_sts |=> owr_rst == $past(bus_wdt[1]));
a_owr_rst_hold: assert property (!bus_wen_ctl_sts |=> $stable(owr_rst));

a_owr_ovd_wr:   assert property (bus_wen_ctl_sts |=> owr_ovd == $past(bus_wdt[2]));
a_owr_ovd_hold: assert property (!bus_wen_ctl_sts |=> $stable(owr_ovd));

a_owr_dat_wr:   assert property (bus_wen_ctl_sts |=> owr_dat == $past(bus_wdt[0]));
a_owr_dat_smp:  assert property (!bus_wen_ctl_sts && pls && cnt == t_zero |=> owr_dat === $past(owr_smp));
a_owr_dat_hold: assert property (!bus_wen_ctl_sts && !(pls && cnt == t_zero) |=> $stable(owr_dat));

a_owr_cyc_wr:   assert property (bus_wen_ctl_sts |=>
  owr_cyc == ($past(bus_wdt[3]) && ($past(bus_wdt[2:0]) != 3'b111)));
a_owr_cyc_end:  assert property (!bus_wen_ctl_sts && pls && cnt == t_zero |=> !owr_cyc);
a_owr_cyc_hold: assert property (!bus_wen_ctl_sts && !(pls && cnt == t_zero) |=> $stable(owr_cyc));

a_cnt_idl_ovd: assert property (bus_wen_ctl_sts &&  bus_wdt[2] && bus_wdt[1:0] == 2'b11 |=> cnt == 8'd95);
a_cnt_idl_nrm: assert property (bus_wen_ctl_sts && !bus_wdt[2] && bus_wdt[1:0] == 2'b11 |=> cnt == 8'd199);
a_cnt_rst_ovd: assert property (bus_wen_ctl_sts &&  bus_wdt[2] && bus_wdt[1:0] == 2'b10 |=> cnt == 8'd95);
a_cnt_rst_nrm: assert property (bus_wen_ctl_sts && !bus_wdt[2] && bus_wdt[1:0] == 2'b10 |=> cnt == 8'd191);
a_cnt_bit_ovd: assert property (bus_wen_ctl_sts &&  bus_wdt[2] && !bus_wdt[1] |=> cnt == 8'd7);
a_cnt_bit_nrm: assert property (bus_wen_ctl_sts && !bus_wdt[2] && !bus_wdt[1] |=> cnt == 8'd12);
a_cnt_dec:     assert property (!bus_wen_ctl_sts && pls |=> cnt == $past(cnt) - 8'd1);
a_cnt_hold:    assert property (!bus_wen_ctl_sts && !pls |=> $stable(cnt));

// receive sampling
a_smp_rst:  assert property (pls && owr_rst && cnt == t_rstp |=> owr_smp === $past(owr_iln));
a_smp_bit:  assert property (pls && !owr_rst && cnt == t_bits |=> owr_smp === $past(owr_iln));
a_smp_hold: assert property (!(pls && owr_rst && cnt == t_rstp) && !(pls && !owr_rst && cnt == t_bits)
                             |=> $stable(owr_smp));

// output enable
a_oen_wr_idl: assert property (bus_wen_ctl_sts &&  bus_wdt[1:0] == 2'b11 |=> !owr_oen);
a_oen_wr_act: assert property (bus_wen_ctl_sts && bus_wdt[1:0] != 2'b11 |=>  owr_oen);
a_oen_rst:    assert property (!bus_wen_ctl_sts && pls && owr_rst && cnt == t_rsth |=> !owr_oen);
a_oen_rd:     assert property (!bus_wen_ctl_sts && pls && !(owr_rst && cnt == t_rsth)
                               && owr_dat && cnt == t_dat1 |=> !owr_oen);
a_oen_wr0:    assert property (!bus_wen_ctl_sts && pls && !(owr_rst && cnt == t_rsth)
                               && !(owr_dat && cnt == t_dat1) && cnt == t_dat0 |=> !owr_oen);
a_oen_hold_idl: assert property (!bus_wen_ctl_sts && !pls |=> $stable(owr_oen));
a_oen_hold_pls: assert property (!bus_wen_ctl_sts && pls && !(owr_rst && cnt == t_rsth)
                                 && !(owr_dat && cnt == t_dat1) && cnt != t_dat0 |=> $stable(owr_oen));

//////////////////////////////////////////////////////////////////////////////
// outputs
//////////////////////////////////////////////////////////////////////////////

a_owr_p:   assert property (owr_p == owr_pwr);
a_owr_e:   assert property (owr_e === OWN'(owr_oen << owr_sel));
a_owr_iln: assert property (owr_iln === owr_i[owr_sel]);

//////////////////////////////////////////////////////////////////////////////
// cover properties (reachability sanity)
//////////////////////////////////////////////////////////////////////////////

c_bus_irq:      cover property (bus_irq);
c_irq_set:      cover property ($rose(irq_sts));
c_irq_clr_rd:   cover property (irq_sts && bus_ren_ctl_sts ##1 !irq_sts);
c_ovd_on:       cover property ($rose(owr_ovd));
c_oen_fall:     cover property ($fell(owr_oen));
c_oen_hi:       cover property (owr_e);
c_owr_p:        cover property (owr_p);
c_smp_rst:      cover property (pls && owr_rst && cnt == t_rstp);
c_smp_bit:      cover property (pls && !owr_rst && cnt == t_bits);
c_cyc_end:      cover property (owr_cyc ##1 !owr_cyc);
c_cdr_n_wr:     cover property (bus_wen_cdr_n && bus_wdt[15:0] == 16'd7 ##1 cdr_n == 16'd7);
c_rdt_adr1:     cover property (bus_adr[0] && bus_rdt[15:0] != 16'd0);
c_rdt_adr0:     cover property (!bus_adr[0] && bus_rdt[3]);
c_cnt_idl:      cover property (bus_wen_ctl_sts && !bus_wdt[2] && bus_wdt[1:0] == 2'b11 ##1 cnt == 8'd199);

endmodule

bind sockit_owm sockit_owm_sva #(.BDW(BDW), .OWN(OWN), .BAW(BAW), .CDW(CDW), .TDW(TDW))
  u_sva (.*);
