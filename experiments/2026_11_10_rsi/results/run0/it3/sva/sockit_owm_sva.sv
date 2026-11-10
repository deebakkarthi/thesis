// ============================================================================
// SVA checker for sockit_owm (1-wire master, Avalon-style bus).
//
// Step 0 - elaborated configuration (sockit_owm.tcl does not override any
// parameter, so the RTL defaults are elaborated):
//   OVD_E=1  CDR_E=1  BDW=32  OWN=1  BAW=1   (`ifdef __ICARUS__ not taken)
//   BTP_N="5.0": T_RSTH_N=96 T_RSTL_N=96 T_RSTP_N=15 T_DAT0_N=12 T_DAT1_N=1
//                T_BITS_N=3  T_RCVR_N=1  T_IDLE_N=200
//   BTP_O="1.0": T_RSTH_O=48 T_RSTL_O=48 T_RSTP_O=10 T_DAT0_O=6  T_DAT1_O=1
//                T_BITS_O=2  T_RCVR_O=2  T_IDLE_O=96
//   CDR_N=5-1=4  CDR_O=1-1=0
//   PDW=24 (BDW==32)  CDW=16 (CDR_E, BDW==32)  SDW=$clog2(1)=0
//   TDW: (96 > 192) is false -> $clog2(192) = 8
//   owr_sel is declared [SDW-1:0] = [-1:0] -> 2 bits wide.
//   Generate: BDW==32 branches selected; BDW==8 branches absent;
//             OWN>1 false -> else branch (owr_pwr with bus_wen_ctl_sts,
//             `initial owr_sel <= 0`). bus_rdt_pwr_sel = 24'h0.
//             bus_wen_{ctl_sts,pwr_sel} use adr[0]==0, bus_wen_cdr_{n,o}
//             use adr[0]==1.
//
// Evaluated timing wires (owr_ovd / req_ovd select the row):
//   normal   (0): t_idl=200 t_rst=192 t_bit=13 t_rstp=81 t_rsth=96
//                 t_dat0=1 t_dat1=12 t_bits=10 t_zero=0
//   overdrive(1): t_idl=96  t_rst=96  t_bit=8  t_rstp=38 t_rsth=48
//                 t_dat0=2 t_dat1=7  t_bits=6  t_zero=0
//   t_idl/t_rst/t_bit depend on req_ovd (combinational bus write, bdw[2]);
//   t_rstp/t_rsth/t_dat0/t_dat1/t_bits depend on owr_ovd (register).
//
// Step 1 - signal inventory (reset priority per register)
//   Reset is asynchronous (posedge rst) in every block that has one.
//   cdr_n  [15:0]: reset -> CDR_N(4)
//                  if (bus_wen_cdr_n)  <- bus_wdt[15:0]     e1
//                  else                                     hold
//   cdr_o  [15:0]: reset -> CDR_O(0)
//                  if (bus_wen_cdr_o)  <- bus_wdt[31:16]    e1
//                  else                                     hold
//   div    [15:0]: reset -> 0
//                  if (bus_wen)        <- 0                 e1
//                  else if (pls)       <- 0                 e2
//                  else                <- div + owr_cyc     e3   (no hold)
//   owr_cyc:       reset -> 0
//                  if (bus_wen_ctl_sts) <- wdt[3] & ~&wdt[2:0]   e1
//                  else if (pls & cnt==0) <- 0                   e2
//                  else                                          hold
//   cnt    [7:0]:  reset -> 0
//                  if (bus_wen_ctl_sts) <- (&wdt[1:0] ? t_idl : wdt[1] ? t_rst : t_bit) - 1   e1a/e1b/e1c
//                  else if (pls)        <- cnt - 1                                            e2
//                  else                                                                       hold
//   owr_pwr[0]:    reset -> 0
//                  if (bus_wen_ctl_sts) <- wdt[4]           e1
//                  else                                     hold
//   irq_ena:       reset -> 0
//                  if (bus_wen_ctl_sts) <- wdt[7]           e1
//                  else                                     hold
//   irq_sts:       reset -> 0
//                  if (bus_wen_ctl_sts)           <- 0      e1
//                  else if (pls & cnt==0)         <- 1      e2
//                  else if (bus_ren_ctl_sts)      <- 0      e3
//                  else                                     hold
//   owr_ovd:       reset -> 0
//                  if (bus_wen_ctl_sts) <- req_ovd          e1
//                  else                                     hold
//   owr_rst:       reset -> 0
//                  if (bus_wen_ctl_sts) <- wdt[1]           e1
//                  else                                     hold
//   owr_dat:       reset -> 0
//                  if (bus_wen_ctl_sts)           <- wdt[0]  e1
//                  else if (pls & cnt==0)         <- owr_smp e2
//                  else                                     hold
//   owr_smp:       NO RESET (arbitrary start value)
//                  if (pls) begin
//                    if (owr_rst & cnt==t_rstp)   <- owr_iln  e1
//                    else if (~owr_rst & cnt==t_bits) <- owr_iln  e2
//                    else                                     hold (inner)
//                  end
//                  else                                       hold (outer)
//   owr_oen:       reset -> 0
//                  if (bus_wen_ctl_sts)           <- ~&wdt[1:0]   e1
//                  else if (pls) begin
//                    if (owr_rst & cnt==t_rsth)   <- 0            e2
//                    else if (owr_dat & cnt==t_dat1) <- 0         e3
//                    else if (cnt==t_dat0)        <- 0            e4
//                    else                                         hold (inner)
//                  end
//                  else                                           hold (outer)
//
//   Wires: bus_ren_ctl_sts, bus_wen_ctl_sts, bus_wen_pwr_sel, bus_wen_cdr_n,
//          bus_wen_cdr_o, bus_rdt_ctl_sts[7:0], bus_rdt_pwr_sel[23:0],
//          bus_rdt[31:0], bus_irq, owr_p, owr_e, owr_iln, pls, req_ovd,
//          t_idl, t_rst, t_bit, t_rstp, t_rsth, t_dat0, t_dat1, t_bits, t_zero.
//
//   Free / not asserted:
//     owr_sel : only assigned in `initial` -> free. owr_e and owr_iln depend
//               on it: owr_e = owr_oen << owr_sel (1-bit result, so 0 when
//               sel!=0); owr_iln = owr_i[owr_sel] is only defined for sel==0.
//     owr_smp : no reset, assigned only under pls; asserted only one cycle
//               after its assignment and under its exact hold condition.
// ============================================================================

module sockit_owm_sva #(
  // same parameter names and defaults as sockit_owm
  parameter OVD_E =    1,
  parameter CDR_E =    1,
  parameter BDW   =   32,
  parameter OWN   =    1,
  parameter BAW   =    1,
  parameter BTP_N = "5.0",
  parameter BTP_O = "1.0",
  parameter T_RSTH_N = (BTP_N == "7.5") ?  64 : (BTP_N == "5.0") ?  96 :  80,
  parameter T_RSTL_N = (BTP_N == "7.5") ?  64 : (BTP_N == "5.0") ?  96 :  80,
  parameter T_RSTP_N = (BTP_N == "7.5") ?  10 : (BTP_N == "5.0") ?  15 :  10,
  parameter T_DAT0_N = (BTP_N == "7.5") ?   8 : (BTP_N == "5.0") ?  12 :  10,
  parameter T_DAT1_N = (BTP_N == "7.5") ?   1 : (BTP_N == "5.0") ?   1 :   1,
  parameter T_BITS_N = (BTP_N == "7.5") ?   2 : (BTP_N == "5.0") ?   3 :   2,
  parameter T_RCVR_N = (BTP_N == "7.5") ?   1 : (BTP_N == "5.0") ?   1 :   1,
  parameter T_IDLE_N = (BTP_N == "7.5") ? 128 : (BTP_N == "5.0") ? 200 : 160,
  parameter T_RSTH_O = (BTP_O == "1.0") ?  48 :  96,
  parameter T_RSTL_O = (BTP_O == "1.0") ?  48 :  96,
  parameter T_RSTP_O = (BTP_O == "1.0") ?  10 :  15,
  parameter T_DAT0_O = (BTP_O == "1.0") ?   6 :  12,
  parameter T_DAT1_O = (BTP_O == "1.0") ?   1 :   2,
  parameter T_BITS_O = (BTP_O == "1.0") ?   2 :   3,
  parameter T_RCVR_O = (BTP_O == "1.0") ?   2 :   4,
  parameter T_IDLE_O = (BTP_O == "1.0") ?  96 : 192,
  parameter CDR_N = 5-1,
  parameter CDR_O = 1-1,
  // widths, recomputed exactly as in sockit_owm
  localparam PDW = (BDW==32) ? 24 : 8,
  localparam CDW = CDR_E ? ((BDW==32) ? 16 : 8) : $clog2(CDR_N),
  localparam SDW = $clog2(OWN),
  localparam TDW = (T_RSTH_O+T_RSTL_O) > (T_RSTH_N+T_RSTL_N)
                 ? $clog2(T_RSTH_O+T_RSTL_O) : $clog2(T_RSTH_N+T_RSTL_N)
)(
  // system
  input                clk,
  input                rst,
  // bus
  input                bus_ren,
  input                bus_wen,
  input  [BAW-1:0]     bus_adr,
  input  [BDW-1:0]     bus_wdt,
  input  [BDW-1:0]     bus_rdt,
  input                bus_irq,
  // 1-wire
  input  [OWN-1:0]     owr_p,
  input  [OWN-1:0]     owr_e,
  input  [OWN-1:0]     owr_i,
  // internal wires and registers of sockit_owm
  input                bus_ren_ctl_sts,
  input                bus_wen_ctl_sts,
  input                bus_wen_pwr_sel,
  input                bus_wen_cdr_n,
  input                bus_wen_cdr_o,
  input  [7:0]         bus_rdt_ctl_sts,
  input  [PDW-1:0]     bus_rdt_pwr_sel,
  input  [CDW-1:0]     div,
  input  [CDW-1:0]     cdr_n,
  input  [CDW-1:0]     cdr_o,
  input                pls,
  input                owr_cyc,
  input  [TDW-1:0]     cnt,
  input  [SDW-1:0]     owr_sel,
  input                req_ovd,
  input  [OWN-1:0]     owr_pwr,
  input                owr_ovd,
  input                owr_rst,
  input                owr_dat,
  input                owr_smp,
  input                owr_oen,
  input                owr_iln,
  input                irq_ena,
  input                irq_sts,
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

  // ==========================================================================
  // Auxiliary flop: high in the first cycle after reset is released.
  // ==========================================================================
  logic first_cyc;
  always @(posedge clk or posedge rst)
    if (rst) first_cyc <= 1'b1; else first_cyc <= 1'b0;

  // ==========================================================================
  // Reset values (first cycle after reset)
  // ==========================================================================
  a_rv_cdr_n:  assert property (first_cyc |-> cdr_n == CDW'(CDR_N));
  a_rv_cdr_o:  assert property (first_cyc |-> cdr_o == CDW'(CDR_O));
  a_rv_div:    assert property (first_cyc |-> div == '0);
  a_rv_cyc:    assert property (first_cyc |-> owr_cyc == 1'b0);
  a_rv_cnt:    assert property (first_cyc |-> cnt == '0);
  a_rv_pwr:    assert property (first_cyc |-> owr_pwr == 1'b0);
  a_rv_ien:    assert property (first_cyc |-> irq_ena == 1'b0);
  a_rv_ists:   assert property (first_cyc |-> irq_sts == 1'b0);
  a_rv_ovd:    assert property (first_cyc |-> owr_ovd == 1'b0);
  a_rv_orst:   assert property (first_cyc |-> owr_rst == 1'b0);
  a_rv_dat:    assert property (first_cyc |-> owr_dat == 1'b0);
  a_rv_oen:    assert property (first_cyc |-> owr_oen == 1'b0);

  // ==========================================================================
  // Combinational wires
  // ==========================================================================
  a_w_ren_ctl:   assert property (bus_ren_ctl_sts == (bus_ren & (bus_adr[0] == 1'b0)));
  a_w_wen_ctl:   assert property (bus_wen_ctl_sts == (bus_wen & (bus_adr[0] == 1'b0)));
  a_w_wen_pwr:   assert property (bus_wen_pwr_sel == (bus_wen & (bus_adr[0] == 1'b0)));
  a_w_wen_cdr_n: assert property (bus_wen_cdr_n   == (bus_wen & (bus_adr[0] == 1'b1)));
  a_w_wen_cdr_o: assert property (bus_wen_cdr_o   == (bus_wen & (bus_adr[0] == 1'b1)));
  a_w_rdt_ctl:   assert property (bus_rdt_ctl_sts ==
                   {irq_ena, irq_sts, 1'b0, owr_pwr[0], owr_cyc, owr_ovd, owr_rst, owr_dat});
  a_w_rdt_pwr:   assert property (bus_rdt_pwr_sel == '0);
  a_w_req_ovd:   assert property (req_ovd == (bus_wen_ctl_sts & bus_wdt[2]));
  a_w_pls_ovd:   assert property (owr_ovd  |-> (pls == (div == cdr_o)));
  a_w_pls_n:     assert property (!owr_ovd |-> (pls == (div == cdr_n)));
  a_w_zero:      assert property (t_zero == '0);

  a_w_idl_o:  assert property (req_ovd  |-> t_idl == TDW'(T_IDLE_O));
  a_w_idl_n:  assert property (!req_ovd |-> t_idl == TDW'(T_IDLE_N));
  a_w_rst_o:  assert property (req_ovd  |-> t_rst == TDW'(T_RSTL_O + T_RSTH_O));
  a_w_rst_n:  assert property (!req_ovd |-> t_rst == TDW'(T_RSTL_N + T_RSTH_N));
  a_w_bit_o:  assert property (req_ovd  |-> t_bit == TDW'(T_DAT0_O + T_RCVR_O));
  a_w_bit_n:  assert property (!req_ovd |-> t_bit == TDW'(T_DAT0_N + T_RCVR_N));

  a_w_rstp_o: assert property (owr_ovd  |-> t_rstp == TDW'(T_RSTH_O - T_RSTP_O));
  a_w_rstp_n: assert property (!owr_ovd |-> t_rstp == TDW'(T_RSTH_N - T_RSTP_N));
  a_w_rsth_o: assert property (owr_ovd  |-> t_rsth == TDW'(T_RSTH_O));
  a_w_rsth_n: assert property (!owr_ovd |-> t_rsth == TDW'(T_RSTH_N));
  a_w_dat0_o: assert property (owr_ovd  |-> t_dat0 == TDW'(T_DAT0_O - T_DAT0_O + T_RCVR_O));
  a_w_dat0_n: assert property (!owr_ovd |-> t_dat0 == TDW'(T_DAT0_N - T_DAT0_N + T_RCVR_N));
  a_w_dat1_o: assert property (owr_ovd  |-> t_dat1 == TDW'(T_DAT0_O - T_DAT1_O + T_RCVR_O));
  a_w_dat1_n: assert property (!owr_ovd |-> t_dat1 == TDW'(T_DAT0_N - T_DAT1_N + T_RCVR_N));
  a_w_bits_o: assert property (owr_ovd  |-> t_bits == TDW'(T_DAT0_O - T_BITS_O + T_RCVR_O));
  a_w_bits_n: assert property (!owr_ovd |-> t_bits == TDW'(T_DAT0_N - T_BITS_N + T_RCVR_N));

  // ==========================================================================
  // Outputs
  // ==========================================================================
  a_out_rdt_r0: assert property ((bus_adr[0] == 1'b0) |-> bus_rdt == {bus_rdt_pwr_sel, bus_rdt_ctl_sts});
  a_out_rdt_r1: assert property ((bus_adr[0] == 1'b1) |-> bus_rdt == {cdr_o, cdr_n});
  a_out_irq:    assert property (bus_irq == (irq_ena & irq_sts));
  a_out_p:      assert property (owr_p == owr_pwr);
  a_out_e_s0:   assert property ((owr_sel == 0)  |-> owr_e == owr_oen);
  a_out_e_snz:  assert property ((owr_sel != 0)  |-> owr_e == '0);
  a_w_iln:      assert property ((owr_sel == 0)  |-> owr_iln == owr_i[0]);

  // ==========================================================================
  // cdr_n / cdr_o (bus-written ratio registers)
  // ==========================================================================
  a_cdr_n_wr:   assert property (bus_wen_cdr_n |=> cdr_n == $past(bus_wdt[15:0]));
  a_cdr_n_hold: assert property (!bus_wen_cdr_n |=> cdr_n == $past(cdr_n));
  a_cdr_o_wr:   assert property (bus_wen_cdr_o |=> cdr_o == $past(bus_wdt[31:16]));
  a_cdr_o_hold: assert property (!bus_wen_cdr_o |=> cdr_o == $past(cdr_o));

  // ==========================================================================
  // div
  // ==========================================================================
  a_div_wen:  assert property (bus_wen |=> div == '0);
  a_div_pls:  assert property ((!bus_wen && pls) |=> div == '0);
  a_div_inc:  assert property ((!bus_wen && !pls) |=> div == CDW'($past(div) + $past(owr_cyc)));

  // ==========================================================================
  // owr_cyc
  // ==========================================================================
  a_cyc_wr:   assert property (bus_wen_ctl_sts |=>
                owr_cyc == ($past(bus_wdt[3]) & ~(&$past(bus_wdt[2:0]))));
  a_cyc_end:  assert property ((!bus_wen_ctl_sts && pls && (cnt == t_zero)) |=> owr_cyc == 1'b0);
  a_cyc_hold: assert property ((!bus_wen_ctl_sts && !(pls && (cnt == t_zero))) |=> owr_cyc == $past(owr_cyc));

  // ==========================================================================
  // cnt
  // ==========================================================================
  a_cnt_idl:  assert property ((bus_wen_ctl_sts && (&bus_wdt[1:0])) |=>
                cnt == $bits(cnt)'($past(t_idl) - 1));
  a_cnt_rst:  assert property ((bus_wen_ctl_sts && !(&bus_wdt[1:0]) && bus_wdt[1]) |=>
                cnt == $bits(cnt)'($past(t_rst) - 1));
  a_cnt_bit:  assert property ((bus_wen_ctl_sts && !(&bus_wdt[1:0]) && !bus_wdt[1]) |=>
                cnt == $bits(cnt)'($past(t_bit) - 1));
  a_cnt_dec:  assert property ((!bus_wen_ctl_sts && pls) |=> cnt == $bits(cnt)'($past(cnt) - 1));
  a_cnt_hold: assert property ((!bus_wen_ctl_sts && !pls) |=> cnt == $past(cnt));

  // ==========================================================================
  // owr_pwr (OWN==1 branch)
  // ==========================================================================
  a_pwr_wr:   assert property (bus_wen_ctl_sts |=> owr_pwr == $past(bus_wdt[4]));
  a_pwr_hold: assert property (!bus_wen_ctl_sts |=> owr_pwr == $past(owr_pwr));

  // ==========================================================================
  // irq_ena / irq_sts
  // ==========================================================================
  a_ien_wr:    assert property (bus_wen_ctl_sts |=> irq_ena == $past(bus_wdt[7]));
  a_ien_hold:  assert property (!bus_wen_ctl_sts |=> irq_ena == $past(irq_ena));

  a_ists_wr:   assert property (bus_wen_ctl_sts |=> irq_sts == 1'b0);
  a_ists_set:  assert property ((!bus_wen_ctl_sts && pls && (cnt == t_zero)) |=> irq_sts == 1'b1);
  a_ists_ren:  assert property ((!bus_wen_ctl_sts && !(pls && (cnt == t_zero)) && bus_ren_ctl_sts)
                                |=> irq_sts == 1'b0);
  a_ists_hold: assert property ((!bus_wen_ctl_sts && !(pls && (cnt == t_zero)) && !bus_ren_ctl_sts)
                                |=> irq_sts == $past(irq_sts));

  // ==========================================================================
  // owr_ovd / owr_rst
  // ==========================================================================
  a_ovd_wr:    assert property (bus_wen_ctl_sts |=> owr_ovd == $past(req_ovd));
  a_ovd_hold:  assert property (!bus_wen_ctl_sts |=> owr_ovd == $past(owr_ovd));

  a_orst_wr:   assert property (bus_wen_ctl_sts |=> owr_rst == $past(bus_wdt[1]));
  a_orst_hold: assert property (!bus_wen_ctl_sts |=> owr_rst == $past(owr_rst));

  // ==========================================================================
  // owr_dat
  // ==========================================================================
  a_dat_wr:    assert property (bus_wen_ctl_sts |=> owr_dat == $past(bus_wdt[0]));
  a_dat_smp:   assert property ((!bus_wen_ctl_sts && pls && (cnt == t_zero)) |=> owr_dat == $past(owr_smp));
  a_dat_hold:  assert property ((!bus_wen_ctl_sts && !(pls && (cnt == t_zero))) |=> owr_dat == $past(owr_dat));

  // ==========================================================================
  // owr_smp (no reset): one cycle after assignment, and hold conditions
  // ==========================================================================
  a_smp_rst:   assert property ((owr_sel == 0 && pls && owr_rst && (cnt == t_rstp))
                                |=> owr_smp == $past(owr_iln));
  a_smp_bit:   assert property ((owr_sel == 0 && pls && !(owr_rst && (cnt == t_rstp))
                                 && !owr_rst && (cnt == t_bits))
                                |=> owr_smp == $past(owr_iln));
  a_smp_hold_o: assert property ((!pls) |=> owr_smp == $past(owr_smp));
  a_smp_hold_i: assert property ((pls && !(owr_rst && (cnt == t_rstp))
                                  && !(!owr_rst && (cnt == t_bits)))
                                 |=> owr_smp == $past(owr_smp));

  // ==========================================================================
  // owr_oen
  // ==========================================================================
  a_oen_wr:    assert property (bus_wen_ctl_sts |=> owr_oen == ~(&$past(bus_wdt[1:0])));
  a_oen_rst:   assert property ((!bus_wen_ctl_sts && pls && (owr_rst && (cnt == t_rsth)))
                                |=> owr_oen == 1'b0);
  a_oen_dat1:  assert property ((!bus_wen_ctl_sts && pls && !(owr_rst && (cnt == t_rsth))
                                 && (owr_dat && (cnt == t_dat1)))
                                |=> owr_oen == 1'b0);
  a_oen_dat0:  assert property ((!bus_wen_ctl_sts && pls && !(owr_rst && (cnt == t_rsth))
                                 && !(owr_dat && (cnt == t_dat1)) && (cnt == t_dat0))
                                |=> owr_oen == 1'b0);
  a_oen_hold_i: assert property ((!bus_wen_ctl_sts && pls && !(owr_rst && (cnt == t_rsth))
                                  && !(owr_dat && (cnt == t_dat1)) && !(cnt == t_dat0))
                                 |=> owr_oen == $past(owr_oen));
  a_oen_hold_o: assert property ((!bus_wen_ctl_sts && !pls) |=> owr_oen == $past(owr_oen));

  // ==========================================================================
  // Covers (reachable behaviour, no second reset needed)
  // ==========================================================================
  c_wr_ctl:     cover property (bus_wen_ctl_sts);
  c_wr_cdr_n:   cover property (bus_wen_cdr_n);
  c_wr_cdr_o:   cover property (bus_wen_cdr_o);
  c_wr_ovd:     cover property (bus_wen_ctl_sts && bus_wdt[2]);
  c_wr_idle:    cover property (bus_wen_ctl_sts && (&bus_wdt[1:0]));
  c_wr_rstcyc:  cover property (bus_wen_ctl_sts && !(&bus_wdt[1:0]) && bus_wdt[1]);
  c_wr_bitcyc:  cover property (bus_wen_ctl_sts && !bus_wdt[1]);
  c_ovd_on:     cover property (owr_ovd && pls);
  c_pls:        cover property (pls);
  c_cyc_end:    cover property ((!bus_wen_ctl_sts && pls && (cnt == t_zero)) ##1 irq_sts);
  c_bus_irq:    cover property (bus_irq);
  c_owr_e:      cover property (owr_e);
  c_owr_p:      cover property (owr_p);
  c_dat_one:    cover property (owr_dat);
  c_oen_fall:   cover property (owr_oen ##1 !owr_oen);
  c_smp_rst:    cover property (pls && owr_rst && (cnt == t_rstp));
  c_smp_bit:    cover property (pls && !owr_rst && (cnt == t_bits));
  c_rd_cdr:     cover property (bus_ren && (bus_adr[0] == 1'b1));

endmodule

// Bind to the DUT with the elaborated (default) parameter values.
bind sockit_owm sockit_owm_sva #(
  .OVD_E(1), .CDR_E(1), .BDW(32), .OWN(1), .BAW(1),
  .BTP_N("5.0"), .BTP_O("1.0"),
  .T_RSTH_N(96), .T_RSTL_N(96), .T_RSTP_N(15), .T_DAT0_N(12),
  .T_DAT1_N(1),  .T_BITS_N(3),  .T_RCVR_N(1),  .T_IDLE_N(200),
  .T_RSTH_O(48), .T_RSTL_O(48), .T_RSTP_O(10), .T_DAT0_O(6),
  .T_DAT1_O(1),  .T_BITS_O(2),  .T_RCVR_O(2),  .T_IDLE_O(96),
  .CDR_N(4), .CDR_O(0)
) u_sva (.*);
