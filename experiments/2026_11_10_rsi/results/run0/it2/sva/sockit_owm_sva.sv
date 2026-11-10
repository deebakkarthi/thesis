//////////////////////////////////////////////////////////////////////////////
// SVA checker for sockit_owm (1-wire master, bus interface, BDW=32)
//
// Elaborated parameter values (sockit_owm.tcl does not override any):
//   OVD_E=1 CDR_E=1 BDW=32 OWN=1 BAW=1 BTP_N="5.0" BTP_O="1.0"
//   normal:    T_RSTH_N=96 T_RSTL_N=96 T_RSTP_N=15 T_DAT0_N=12 T_DAT1_N=1
//              T_BITS_N=3 T_RCVR_N=1 T_IDLE_N=200
//   overdrive: T_RSTH_O=48 T_RSTL_O=48 T_RSTP_O=10 T_DAT0_O=6 T_DAT1_O=1
//              T_BITS_O=2 T_RCVR_O=2 T_IDLE_O=96
//   CDR_N=4 CDR_O=0
//
// Derived localparams (evaluated by hand):
//   PDW = 24                      (BDW==32)
//   CDW = 16                      (CDR_E=1, BDW==32)
//   SDW = $clog2(1) = 0           -> owr_sel declared [-1:0], i.e. 2 bits wide
//   TDW = $clog2(192) = 8         (96+96 > 48+48, so normal period sizes it)
//
// Selected generate branches:
//   BDW==32 bus decode / read mux / cdr registers
//   OWN>1 false -> else branch: owr_pwr is one bit, owr_sel only in an initial
//   OVD_E=1     -> req_ovd = bus_wen_ctl_sts & bus_wdt[2]
//
// Register priority structures (reset value; then branches):
//   div[CDW-1:0]:      rst->0
//                      if (bus_wen)                          e1 -> 0
//                      else if (pls)                         e2 -> 0
//                      else                                  e3 -> div + owr_cyc
//   cdr_n[CDW-1:0]:    rst->CDR_N
//                      if (bus_wen_cdr_n)                    e1 -> bus_wdt[15:0]
//                      else                                  hold
//   cdr_o[CDW-1:0]:    rst->CDR_O
//                      if (bus_wen_cdr_o)                    e1 -> bus_wdt[31:16]
//                      else                                  hold
//   owr_pwr[0:0]:      rst->0
//                      if (bus_wen_ctl_sts)                  e1 -> bus_wdt[4]
//                      else                                  hold
//   irq_ena:           rst->0
//                      if (bus_wen_ctl_sts)                  e1 -> bus_wdt[7]
//                      else                                  hold
//   irq_sts:           rst->0
//                      if (bus_wen_ctl_sts)                  e1 -> 0
//                      else if (pls & cnt==t_zero)           e2 -> 1
//                      else if (bus_ren_ctl_sts)             e3 -> 0
//                      else                                  hold
//   owr_ovd:           rst->0
//                      if (bus_wen_ctl_sts)                  e1 -> req_ovd
//                      else                                  hold
//   owr_rst:           rst->0
//                      if (bus_wen_ctl_sts)                  e1 -> bus_wdt[1]
//                      else                                  hold
//   owr_dat:           rst->0
//                      if (bus_wen_ctl_sts)                  e1 -> bus_wdt[0]
//                      else if (pls & cnt==t_zero)           e2 -> owr_smp
//                      else                                  hold
//   owr_cyc:           rst->0
//                      if (bus_wen_ctl_sts)                  e1 -> bus_wdt[3] & ~&bus_wdt[2:0]
//                      else if (pls & cnt==t_zero)           e2 -> 0
//                      else                                  hold
//   cnt[TDW-1:0]:      rst->0
//                      if (bus_wen_ctl_sts)                  e1 -> (&bus_wdt[1:0] ? t_idl :
//                                                                   bus_wdt[1] ? t_rst : t_bit) - 1
//                      else if (pls)                         e2 -> cnt - 1 (wraps 0 -> 255)
//                      else                                  hold
//   owr_smp[0:0]:      NO reset (arbitrary start value)
//                      if (pls) {
//                        if (owr_rst & cnt==t_rstp)          e1 -> owr_iln
//                        else if (~owr_rst & cnt==t_bits)    e2 -> owr_iln
//                        else                                hold }
//                      else                                  hold
//   owr_oen:           rst->0
//                      if (bus_wen_ctl_sts)                  e1 -> ~&bus_wdt[1:0]
//                      else if (pls) {
//                        if (owr_rst & cnt==t_rsth)          e2 -> 0
//                        else if (owr_dat & cnt==t_dat1)     e3 -> 0
//                        else if (cnt==t_dat0)               e4 -> 0
//                        else                                hold }
//                      else                                  hold
//
// Free / unconstrained signals:
//   owr_sel: only assigned in an initial block -> free. It drives owr_e (shift)
//   and owr_iln (index). owr_iln is only checked for owr_sel==0 (out-of-range
//   index otherwise). owr_smp is only checked on its load branches when
//   owr_sel==0 for the same reason.
//
// Not asserted by design: reset-branch values (rst->...), per the rules; they
// depend on reset being re-asserted and are not checked.
//////////////////////////////////////////////////////////////////////////////

module sockit_owm_sva #(
  parameter OVD_E    = 1,
  parameter CDR_E    = 1,
  parameter BDW      = 32,
  parameter OWN      = 1,
  parameter BAW      = 1,
  parameter BTP_N    = "5.0",
  parameter BTP_O    = "1.0",
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
  parameter T_IDLE_O = 96,
  parameter CDR_N   = 4,
  parameter CDR_O   = 0,
  // derived localparams of the DUT, recomputed so port widths match
  parameter PDW = (BDW==32) ? 24 : 8,
  parameter CDW = CDR_E ? ((BDW==32) ? 16 : 8) : $clog2(CDR_N),
  parameter SDW = $clog2(OWN),
  parameter TDW = ((T_RSTH_O+T_RSTL_O) > (T_RSTH_N+T_RSTL_N))
                ? $clog2(T_RSTH_O+T_RSTL_O) : $clog2(T_RSTH_N+T_RSTL_N)
)(
  // system
  input                  clk,
  input                  rst,
  // bus
  input                  bus_ren,
  input                  bus_wen,
  input  [BAW-1:0]       bus_adr,
  input  [BDW-1:0]       bus_wdt,
  input  [BDW-1:0]       bus_rdt,
  input                  bus_irq,
  // 1-wire
  input  [OWN-1:0]       owr_p,
  input  [OWN-1:0]       owr_e,
  input  [OWN-1:0]       owr_i,
  // internal wires
  input                  bus_ren_ctl_sts,
  input                  bus_wen_ctl_sts,
  input                  bus_wen_pwr_sel,
  input                  bus_wen_cdr_n,
  input                  bus_wen_cdr_o,
  input  [7:0]           bus_rdt_ctl_sts,
  input  [PDW-1:0]       bus_rdt_pwr_sel,
  input  [CDW-1:0]       div,
  input  [CDW-1:0]       cdr_n,
  input  [CDW-1:0]       cdr_o,
  input                  pls,
  input                  owr_cyc,
  input  [TDW-1:0]       cnt,
  input  [SDW-1:0]       owr_sel,
  input                  req_ovd,
  input  [OWN-1:0]       owr_pwr,
  input                  owr_ovd,
  input                  owr_rst,
  input                  owr_dat,
  input                  owr_smp,
  input                  owr_oen,
  input                  owr_iln,
  input                  irq_ena,
  input                  irq_sts,
  input  [TDW-1:0]       t_idl,
  input  [TDW-1:0]       t_rst,
  input  [TDW-1:0]       t_bit,
  input  [TDW-1:0]       t_rstp,
  input  [TDW-1:0]       t_rsth,
  input  [TDW-1:0]       t_dat0,
  input  [TDW-1:0]       t_dat1,
  input  [TDW-1:0]       t_bits,
  input  [TDW-1:0]       t_zero
);

default clocking cb @(posedge clk); endclocking
default disable iff (rst);

//////////////////////////////////////////////////////////////////////////////
// combinational: address decode
//////////////////////////////////////////////////////////////////////////////

a_ren_ctl:   assert property (bus_ren_ctl_sts == (bus_ren & (bus_adr[0] == 1'b0)));
a_wen_ctl:   assert property (bus_wen_ctl_sts == (bus_wen & (bus_adr[0] == 1'b0)));
a_wen_pwr:   assert property (bus_wen_pwr_sel == (bus_wen & (bus_adr[0] == 1'b0)));
a_wen_cdr_n: assert property (bus_wen_cdr_n   == (bus_wen & (bus_adr[0] == 1'b1)));
a_wen_cdr_o: assert property (bus_wen_cdr_o   == (bus_wen & (bus_adr[0] == 1'b1)));

//////////////////////////////////////////////////////////////////////////////
// combinational: bus read data
//////////////////////////////////////////////////////////////////////////////

a_rdt_ctl_sts: assert property (bus_rdt_ctl_sts ==
                 {irq_ena, irq_sts, 1'b0, owr_pwr[0], owr_cyc, owr_ovd, owr_rst, owr_dat});
a_rdt_pwr_sel: assert property (bus_rdt_pwr_sel == 24'h000000);
a_rdt_ctl:     assert property (bus_adr[0] == 1'b0 |-> bus_rdt == {bus_rdt_pwr_sel, bus_rdt_ctl_sts});
a_rdt_cdr:     assert property (bus_adr[0] == 1'b1 |-> bus_rdt == {cdr_o, cdr_n});

//////////////////////////////////////////////////////////////////////////////
// combinational: interrupt, overdrive request, timing wires, clock pulse
//////////////////////////////////////////////////////////////////////////////

a_irq:     assert property (bus_irq == (irq_ena & irq_sts));
a_req_ovd: assert property (req_ovd == (OVD_E ? (bus_wen_ctl_sts & bus_wdt[2]) : 1'b0));

a_t_idl:  assert property (t_idl  == (req_ovd ? T_IDLE_O : T_IDLE_N));
a_t_rst:  assert property (t_rst  == (req_ovd ? T_RSTL_O + T_RSTH_O : T_RSTL_N + T_RSTH_N));
a_t_bit:  assert property (t_bit  == (req_ovd ? T_DAT0_O + T_RCVR_O : T_DAT0_N + T_RCVR_N));
a_t_rstp: assert property (t_rstp == (owr_ovd ? T_RSTH_O - T_RSTP_O : T_RSTH_N - T_RSTP_N));
a_t_rsth: assert property (t_rsth == (owr_ovd ? T_RSTH_O : T_RSTH_N));
a_t_dat0: assert property (t_dat0 == (owr_ovd ? T_DAT0_O - T_DAT0_O + T_RCVR_O
                                              : T_DAT0_N - T_DAT0_N + T_RCVR_N));
a_t_dat1: assert property (t_dat1 == (owr_ovd ? T_DAT0_O - T_DAT1_O + T_RCVR_O
                                              : T_DAT0_N - T_DAT1_N + T_RCVR_N));
a_t_bits: assert property (t_bits == (owr_ovd ? T_DAT0_O - T_BITS_O + T_RCVR_O
                                              : T_DAT0_N - T_BITS_N + T_RCVR_N));
a_t_zero: assert property (t_zero == 0);

a_pls: assert property (pls == (div == (owr_ovd ? cdr_o : cdr_n)));

//////////////////////////////////////////////////////////////////////////////
// combinational: 1-wire I/O
//////////////////////////////////////////////////////////////////////////////

a_owr_e: assert property (owr_e == (owr_oen << owr_sel));
a_owr_p: assert property (owr_p == owr_pwr);
// owr_sel==0 only: other values index out of range of the 1-bit owr_i
a_iln0:  assert property (owr_sel == 0 |-> owr_iln == owr_i[0]);

//////////////////////////////////////////////////////////////////////////////
// registers: clock divider
//////////////////////////////////////////////////////////////////////////////

a_div_e1: assert property (bus_wen |=> div == 0);
a_div_e2: assert property (!bus_wen && pls |=> div == 0);
a_div_e3: assert property (!bus_wen && !pls |=> div == CDW'($past(div) + $past(owr_cyc)));

a_cdr_n_e1:   assert property (bus_wen_cdr_n |=> cdr_n == $past(bus_wdt[15:0]));
a_cdr_n_hold: assert property (!bus_wen_cdr_n |=> cdr_n == $past(cdr_n));
a_cdr_o_e1:   assert property (bus_wen_cdr_o |=> cdr_o == $past(bus_wdt[31:16]));
a_cdr_o_hold: assert property (!bus_wen_cdr_o |=> cdr_o == $past(cdr_o));

//////////////////////////////////////////////////////////////////////////////
// registers: power, interrupt enable and status
//////////////////////////////////////////////////////////////////////////////

a_pwr_e1:   assert property (bus_wen_ctl_sts |=> owr_pwr == $past(bus_wdt[4]));
a_pwr_hold: assert property (!bus_wen_ctl_sts |=> owr_pwr == $past(owr_pwr));

a_irq_ena_e1:   assert property (bus_wen_ctl_sts |=> irq_ena == $past(bus_wdt[7]));
a_irq_ena_hold: assert property (!bus_wen_ctl_sts |=> irq_ena == $past(irq_ena));

a_irq_sts_e1:   assert property (bus_wen_ctl_sts |=> irq_sts == 1'b0);
a_irq_sts_e2:   assert property (!bus_wen_ctl_sts && pls && (cnt == t_zero) |=> irq_sts == 1'b1);
a_irq_sts_e3:   assert property (!bus_wen_ctl_sts && !(pls && (cnt == t_zero)) && bus_ren_ctl_sts
                                 |=> irq_sts == 1'b0);
a_irq_sts_hold: assert property (!bus_wen_ctl_sts && !(pls && (cnt == t_zero)) && !bus_ren_ctl_sts
                                 |=> irq_sts == $past(irq_sts));

//////////////////////////////////////////////////////////////////////////////
// registers: 1-wire state machine
//////////////////////////////////////////////////////////////////////////////

a_ovd_e1:   assert property (bus_wen_ctl_sts |=> owr_ovd == $past(req_ovd));
a_ovd_hold: assert property (!bus_wen_ctl_sts |=> owr_ovd == $past(owr_ovd));

a_rst_e1:   assert property (bus_wen_ctl_sts |=> owr_rst == $past(bus_wdt[1]));
a_rst_hold: assert property (!bus_wen_ctl_sts |=> owr_rst == $past(owr_rst));

a_dat_e1:   assert property (bus_wen_ctl_sts |=> owr_dat == $past(bus_wdt[0]));
a_dat_e2:   assert property (!bus_wen_ctl_sts && pls && (cnt == t_zero) |=> owr_dat == $past(owr_smp));
a_dat_hold: assert property (!bus_wen_ctl_sts && !(pls && (cnt == t_zero))
                             |=> owr_dat == $past(owr_dat));

a_cyc_e1:   assert property (bus_wen_ctl_sts |=> owr_cyc == $past(bus_wdt[3] & ~&bus_wdt[2:0]));
a_cyc_e2:   assert property (!bus_wen_ctl_sts && pls && (cnt == t_zero) |=> owr_cyc == 1'b0);
a_cyc_hold: assert property (!bus_wen_ctl_sts && !(pls && (cnt == t_zero))
                             |=> owr_cyc == $past(owr_cyc));

// cycle counter: write loads (t_idl / t_rst / t_bit) - 1, else decrement on pls
a_cnt_e1a:  assert property (bus_wen_ctl_sts && bus_wdt[1] && bus_wdt[0]
                             |=> cnt == TDW'($past(t_idl) - 1));
a_cnt_e1b:  assert property (bus_wen_ctl_sts && bus_wdt[1] && !bus_wdt[0]
                             |=> cnt == TDW'($past(t_rst) - 1));
a_cnt_e1c:  assert property (bus_wen_ctl_sts && !bus_wdt[1]
                             |=> cnt == TDW'($past(t_bit) - 1));
a_cnt_e2:   assert property (!bus_wen_ctl_sts && pls |=> cnt == TDW'($past(cnt) - 1));
a_cnt_hold: assert property (!bus_wen_ctl_sts && !pls |=> cnt == $past(cnt));

// receive sample: no reset on owr_smp; only checked for owr_sel==0
a_smp_e1:   assert property (pls && owr_rst && (cnt == t_rstp) && (owr_sel == 0)
                             |=> owr_smp == $past(owr_iln));
a_smp_e2:   assert property (pls && !owr_rst && (cnt == t_bits) && (owr_sel == 0)
                             |=> owr_smp == $past(owr_iln));
a_smp_hold: assert property (!(pls && ((owr_rst && (cnt == t_rstp)) || (!owr_rst && (cnt == t_bits))))
                             |=> owr_smp == $past(owr_smp));

// output enable
a_oen_e1:   assert property (bus_wen_ctl_sts |=> owr_oen == $past(~&bus_wdt[1:0]));
a_oen_e2:   assert property (!bus_wen_ctl_sts && pls && owr_rst && (cnt == t_rsth)
                             |=> owr_oen == 1'b0);
a_oen_e3:   assert property (!bus_wen_ctl_sts && pls && !(owr_rst && (cnt == t_rsth))
                             && owr_dat && (cnt == t_dat1)
                             |=> owr_oen == 1'b0);
a_oen_e4:   assert property (!bus_wen_ctl_sts && pls && !(owr_rst && (cnt == t_rsth))
                             && !(owr_dat && (cnt == t_dat1)) && (cnt == t_dat0)
                             |=> owr_oen == 1'b0);
a_oen_hold: assert property (!bus_wen_ctl_sts
                             && !(pls && ((owr_rst && (cnt == t_rsth))
                                       || (owr_dat && (cnt == t_dat1))
                                       || (cnt == t_dat0)))
                             |=> owr_oen == $past(owr_oen));

//////////////////////////////////////////////////////////////////////////////
// higher-level properties
//////////////////////////////////////////////////////////////////////////////

a_wr_excl: assert property (!(bus_wen_ctl_sts && bus_wen_cdr_n));

//////////////////////////////////////////////////////////////////////////////
// covers
//////////////////////////////////////////////////////////////////////////////

c_wr_ctl:       cover property (bus_wen_ctl_sts);
c_wr_cdr_n:     cover property (bus_wen_cdr_n);
c_wr_cdr_o:     cover property (bus_wen_cdr_o);
c_req_ovd:      cover property (req_ovd);
c_ovd_on:       cover property (owr_ovd);
c_pls:          cover property (pls);
c_cycle_end:    cover property (!bus_wen_ctl_sts && pls && (cnt == t_zero));
c_irq:          cover property (bus_irq);
c_irq_clr_rd:   cover property (irq_sts && bus_ren_ctl_sts ##1 !irq_sts);
c_smp_rst:      cover property (pls && owr_rst && (cnt == t_rstp));
c_smp_bit:      cover property (pls && !owr_rst && (cnt == t_bits));
c_oen_e2:       cover property (pls && owr_rst && (cnt == t_rsth));
c_oen_e3:       cover property (pls && !owr_rst && owr_dat && (cnt == t_dat1));
c_oen_e4:       cover property (pls && !owr_rst && !owr_dat && (cnt == t_dat0));
c_cnt_wrap:     cover property (!bus_wen_ctl_sts && pls && (cnt == 0) ##1 (cnt == 8'hFF));
c_owr_e:        cover property (owr_e[0]);
c_owr_p:        cover property (owr_p[0]);
c_rdt_cdr:      cover property (bus_adr[0] && bus_ren);

endmodule

bind sockit_owm sockit_owm_sva #(
  .OVD_E(1), .CDR_E(1), .BDW(32), .OWN(1), .BAW(1),
  .BTP_N("5.0"), .BTP_O("1.0"),
  .T_RSTH_N(96), .T_RSTL_N(96), .T_RSTP_N(15), .T_DAT0_N(12),
  .T_DAT1_N(1), .T_BITS_N(3), .T_RCVR_N(1), .T_IDLE_N(200),
  .T_RSTH_O(48), .T_RSTL_O(48), .T_RSTP_O(10), .T_DAT0_O(6),
  .T_DAT1_O(1), .T_BITS_O(2), .T_RCVR_O(2), .T_IDLE_O(96),
  .CDR_N(4), .CDR_O(0)
) u_sva (.*);
