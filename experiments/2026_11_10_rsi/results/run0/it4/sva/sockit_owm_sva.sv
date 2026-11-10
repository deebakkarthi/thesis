// ============================================================================
// SVA checker for sockit_owm (1-wire master, Avalon-like bus)
// Bound to sockit_owm; every DUT port and internal signal checked is an input
// here with the same name and width (connected by .*).
//
// ---------------------------------------------------------------------------
// Step 0: parameter / generate evaluation (tcl does not override any value)
//   OVD_E=1  CDR_E=1  BDW=32  OWN=1  BAW=1 (__ICARUS__ not defined)
//   BTP_N="5.0"  BTP_O="1.0"
//   normal:    T_RSTH_N=96 T_RSTL_N=96 T_RSTP_N=15 T_DAT0_N=12 T_DAT1_N=1
//              T_BITS_N=3  T_RCVR_N=1  T_IDLE_N=200
//   overdrive: T_RSTH_O=48 T_RSTL_O=48 T_RSTP_O=10 T_DAT0_O=6  T_DAT1_O=1
//              T_BITS_O=2  T_RCVR_O=2  T_IDLE_O=96
//   CDR_N=5-1=4   CDR_O=1-1=0
//   localparams: PDW=24 (BDW==32); CDW=16 (CDR_E); SDW=$clog2(1)=0 -> owr_sel
//                is [-1:0] (2 bits); TDW: 96>192 false -> $clog2(192)=8
//   selected generate branches: BDW==32 (cdr regs, bus_rdt, bus_ren/wen decode),
//                OWN==1 (else branch: owr_pwr, bus_rdt_pwr_sel = 24'h0),
//                CDR_E==1 (cdr_n/cdr_o registers), OVD_E==1 (req_ovd).
//   not selected: BDW==8 branches, OWN>1 sel_implementation, CDR_E==0 initial.
//
// ---------------------------------------------------------------------------
// Step 1: signal inventory (priority structure of each always block)
//
// cdr_n[15:0]    : reset -> CDR_N (4)
//                  if (bus_wen_cdr_n) <- e1 ; else hold
// cdr_o[15:0]    : reset -> CDR_O (0)
//                  if (bus_wen_cdr_o) <- e1 ; else hold
// div[15:0]      : reset -> 0
//                  if (bus_wen) <- e1 ; else if (pls) <- e2 ; else <- e3 (div+owr_cyc)
// owr_cyc        : reset -> 0
//                  if (bus_wen_ctl_sts) <- e1 ; else if (pls & cnt==t_zero) <- e2 ; else hold
// cnt[7:0]       : reset -> 0
//                  if (bus_wen_ctl_sts) <- e1 ; else if (pls) <- e2 ; else hold
// irq_ena        : reset -> 0
//                  if (bus_wen_ctl_sts) <- e1 ; else hold
// irq_sts        : reset -> 0
//                  if (bus_wen_ctl_sts) <- e1 ; else if (pls & cnt==t_zero) <- e2
//                  else if (bus_ren_ctl_sts) <- e3 ; else hold
// owr_pwr[0:0]   : reset -> 0   (OWN==1 branch)
//                  if (bus_wen_ctl_sts) <- e1 ; else hold
// owr_ovd        : reset -> 0
//                  if (bus_wen_ctl_sts) <- e1 ; else hold
// owr_rst        : reset -> 0
//                  if (bus_wen_ctl_sts) <- e1 ; else hold
// owr_dat        : reset -> 0
//                  if (bus_wen_ctl_sts) <- e1 ; else if (pls & cnt==t_zero) <- e2 ; else hold
// owr_oen        : reset -> 0
//                  if (bus_wen_ctl_sts) <- e1
//                  else if (pls) {  if (owr_rst & cnt==t_rsth) <- e2
//                                   else if (owr_dat & cnt==t_dat1) <- e3
//                                   else if (cnt==t_dat0) <- e4
//                                   else <- hold_in }
//                  else <- hold_out
// owr_smp        : NO reset (always @(posedge clk) only)
//                  if (pls) { if (owr_rst & cnt==t_rstp) <- e1 (owr_iln)
//                             else if (~owr_rst & cnt==t_bits) <- e2 (owr_iln)
//                             else <- hold_in }
//                  else <- hold_out
// owr_sel[-1:0]  : assigned ONLY in an initial block (OWN==1 branch) -> FREE.
//                  Never asserted on its value or stability. Used only in owr_e
//                  and owr_iln, which are asserted as functions of it.
//
// Unreset registers: owr_smp (asserted only through relations and its exact
// hold condition). Free: owr_sel.
//
// Combinational wires / outputs:
//   bus_ren_ctl_sts, bus_wen_ctl_sts, bus_wen_pwr_sel, bus_wen_cdr_n, bus_wen_cdr_o
//   bus_rdt_ctl_sts[7:0], bus_rdt_pwr_sel[23:0] (=0), bus_rdt[31:0] (2 selects)
//   req_ovd, pls, t_idl, t_rst, t_bit, t_rstp, t_rsth, t_dat0, t_dat1, t_bits, t_zero
//   owr_e (per owr_sel value), owr_p, owr_iln (owr_sel==0 only), bus_irq
//
// Not checkable: owr_iln for owr_sel in {1,2,3} is an out-of-range bit select
// (X); the owr_smp e1/e2 assertions are restricted to owr_sel==0 for the same
// reason.
// ============================================================================

module sockit_owm_sva #(
  // same parameter names and defaults as the DUT
  parameter OVD_E    =    1,
  parameter CDR_E    =    1,
  parameter BDW      =   32,
  parameter OWN      =    1,
  parameter BAW      =    1,
  parameter BTP_N    = "5.0",
  parameter BTP_O    = "1.0",
  parameter T_RSTH_N =   96,
  parameter T_RSTL_N =   96,
  parameter T_RSTP_N =   15,
  parameter T_DAT0_N =   12,
  parameter T_DAT1_N =    1,
  parameter T_BITS_N =    3,
  parameter T_RCVR_N =    1,
  parameter T_IDLE_N =  200,
  parameter T_RSTH_O =   48,
  parameter T_RSTL_O =   48,
  parameter T_RSTP_O =   10,
  parameter T_DAT0_O =    6,
  parameter T_DAT1_O =    1,
  parameter T_BITS_O =    2,
  parameter T_RCVR_O =    2,
  parameter T_IDLE_O =   96,
  parameter CDR_N    =    4,
  parameter CDR_O    =    0
) (
  clk, rst,
  bus_ren, bus_wen, bus_adr, bus_wdt, bus_rdt, bus_irq,
  owr_p, owr_e, owr_i,
  div, cdr_n, cdr_o, pls,
  owr_cyc, cnt,
  owr_sel, req_ovd, owr_pwr, owr_ovd, owr_rst, owr_dat, owr_smp, owr_oen, owr_iln,
  irq_ena, irq_sts,
  t_idl, t_rst, t_bit, t_rstp, t_rsth, t_dat0, t_dat1, t_bits, t_zero,
  bus_ren_ctl_sts, bus_wen_ctl_sts, bus_wen_pwr_sel, bus_wen_cdr_n, bus_wen_cdr_o,
  bus_rdt_ctl_sts, bus_rdt_pwr_sel
);

  localparam PDW = (BDW==32) ? 24 : 8;
  localparam CDW = CDR_E ? ((BDW==32) ? 16 : 8) : $clog2(CDR_N);
  localparam SDW = $clog2(OWN);
  localparam TDW = (T_RSTH_O+T_RSTL_O) > (T_RSTH_N+T_RSTL_N)
                 ? $clog2(T_RSTH_O+T_RSTL_O) : $clog2(T_RSTH_N+T_RSTL_N);

  input                 clk;
  input                 rst;
  input                 bus_ren;
  input                 bus_wen;
  input  [BAW-1:0]      bus_adr;
  input  [BDW-1:0]      bus_wdt;
  input  [BDW-1:0]      bus_rdt;
  input                 bus_irq;
  input  [OWN-1:0]      owr_p;
  input  [OWN-1:0]      owr_e;
  input  [OWN-1:0]      owr_i;
  input  [CDW-1:0]      div;
  input  [CDW-1:0]      cdr_n;
  input  [CDW-1:0]      cdr_o;
  input                 pls;
  input                 owr_cyc;
  input  [TDW-1:0]      cnt;
  input  [SDW-1:0]      owr_sel;
  input                 req_ovd;
  input  [OWN-1:0]      owr_pwr;
  input                 owr_ovd;
  input                 owr_rst;
  input                 owr_dat;
  input                 owr_smp;
  input                 owr_oen;
  input                 owr_iln;
  input                 irq_ena;
  input                 irq_sts;
  input  [TDW-1:0]      t_idl;
  input  [TDW-1:0]      t_rst;
  input  [TDW-1:0]      t_bit;
  input  [TDW-1:0]      t_rstp;
  input  [TDW-1:0]      t_rsth;
  input  [TDW-1:0]      t_dat0;
  input  [TDW-1:0]      t_dat1;
  input  [TDW-1:0]      t_bits;
  input  [TDW-1:0]      t_zero;
  input                 bus_ren_ctl_sts;
  input                 bus_wen_ctl_sts;
  input                 bus_wen_pwr_sel;
  input                 bus_wen_cdr_n;
  input                 bus_wen_cdr_o;
  input  [7:0]          bus_rdt_ctl_sts;
  input  [PDW-1:0]      bus_rdt_pwr_sel;

  default clocking cb @(posedge clk);
  endclocking
  default disable iff (rst);

  // ---------------------------------------------------------------------------
  // Reset value check: first cycle after (async, active-high) reset release
  // ---------------------------------------------------------------------------
  logic first_cyc;
  always @(posedge clk or posedge rst)
    if (rst) first_cyc <= 1'b1; else first_cyc <= 1'b0;

  a_rst_cdr_n: assert property (first_cyc |-> cdr_n == CDR_N);
  a_rst_cdr_o: assert property (first_cyc |-> cdr_o == CDR_O);
  a_rst_div:   assert property (first_cyc |-> div == 0);
  a_rst_cyc:   assert property (first_cyc |-> owr_cyc == 1'b0);
  a_rst_cnt:   assert property (first_cyc |-> cnt == 0);
  a_rst_irq_e: assert property (first_cyc |-> irq_ena == 1'b0);
  a_rst_irq_s: assert property (first_cyc |-> irq_sts == 1'b0);
  a_rst_pwr:   assert property (first_cyc |-> owr_pwr == 0);
  a_rst_ovd:   assert property (first_cyc |-> owr_ovd == 1'b0);
  a_rst_rst:   assert property (first_cyc |-> owr_rst == 1'b0);
  a_rst_dat:   assert property (first_cyc |-> owr_dat == 1'b0);
  a_rst_oen:   assert property (first_cyc |-> owr_oen == 1'b0);

  // ---------------------------------------------------------------------------
  // cdr_n / cdr_o (CDR_E branch)
  // ---------------------------------------------------------------------------
  a_cdr_n_e1:   assert property (bus_wen_cdr_n |=> cdr_n == $past(bus_wdt[15:0]));
  a_cdr_n_hold: assert property (!bus_wen_cdr_n |=> cdr_n == $past(cdr_n));
  a_cdr_o_e1:   assert property (bus_wen_cdr_o |=> cdr_o == $past(bus_wdt[31:16]));
  a_cdr_o_hold: assert property (!bus_wen_cdr_o |=> cdr_o == $past(cdr_o));

  // ---------------------------------------------------------------------------
  // div
  // ---------------------------------------------------------------------------
  a_div_e1: assert property (bus_wen |=> div == 0);
  a_div_e2: assert property (!bus_wen && pls |=> div == 0);
  a_div_e3: assert property (!bus_wen && !pls |=> div == $past(div) + $past(owr_cyc));

  // ---------------------------------------------------------------------------
  // owr_cyc
  // ---------------------------------------------------------------------------
  a_owr_cyc_e1:   assert property (bus_wen_ctl_sts |=>
                    owr_cyc == ($past(bus_wdt[3]) & ~&$past(bus_wdt[2:0])));
  a_owr_cyc_e2:   assert property (!bus_wen_ctl_sts && (pls & (cnt == t_zero)) |=> owr_cyc == 1'b0);
  a_owr_cyc_hold: assert property (!bus_wen_ctl_sts && !(pls & (cnt == t_zero))
                    |=> owr_cyc == $past(owr_cyc));

  // ---------------------------------------------------------------------------
  // cnt (8-bit, wraps; the 1'b1 literal keeps the subtraction at TDW bits)
  // ---------------------------------------------------------------------------
  a_cnt_e1: assert property (bus_wen_ctl_sts |=>
              cnt == (($past(bus_wdt[1:0]) == 2'b11) ? $past(t_idl)
                    : ($past(bus_wdt[1])     ? $past(t_rst) : $past(t_bit))) - 1'b1);
  a_cnt_e2:   assert property (!bus_wen_ctl_sts && pls |=> cnt == $past(cnt) - 1'b1);
  a_cnt_hold: assert property (!bus_wen_ctl_sts && !pls |=> cnt == $past(cnt));

  // ---------------------------------------------------------------------------
  // irq_ena / irq_sts
  // ---------------------------------------------------------------------------
  a_irq_ena_e1:   assert property (bus_wen_ctl_sts |=> irq_ena == $past(bus_wdt[7]));
  a_irq_ena_hold: assert property (!bus_wen_ctl_sts |=> irq_ena == $past(irq_ena));

  a_irq_sts_e1:   assert property (bus_wen_ctl_sts |=> irq_sts == 1'b0);
  a_irq_sts_e2:   assert property (!bus_wen_ctl_sts && (pls & (cnt == t_zero))
                    |=> irq_sts == 1'b1);
  a_irq_sts_e3:   assert property (!bus_wen_ctl_sts && !(pls & (cnt == t_zero)) && bus_ren_ctl_sts
                    |=> irq_sts == 1'b0);
  a_irq_sts_hold: assert property (!bus_wen_ctl_sts && !(pls & (cnt == t_zero)) && !bus_ren_ctl_sts
                    |=> irq_sts == $past(irq_sts));

  // ---------------------------------------------------------------------------
  // owr_pwr (OWN==1 branch), owr_ovd, owr_rst
  // ---------------------------------------------------------------------------
  a_owr_pwr_e1:   assert property (bus_wen_ctl_sts |=> owr_pwr == $past(bus_wdt[4]));
  a_owr_pwr_hold: assert property (!bus_wen_ctl_sts |=> owr_pwr == $past(owr_pwr));

  a_owr_ovd_e1:   assert property (bus_wen_ctl_sts |=> owr_ovd == $past(req_ovd));
  a_owr_ovd_hold: assert property (!bus_wen_ctl_sts |=> owr_ovd == $past(owr_ovd));

  a_owr_rst_e1:   assert property (bus_wen_ctl_sts |=> owr_rst == $past(bus_wdt[1]));
  a_owr_rst_hold: assert property (!bus_wen_ctl_sts |=> owr_rst == $past(owr_rst));

  // ---------------------------------------------------------------------------
  // owr_dat
  // ---------------------------------------------------------------------------
  a_owr_dat_e1:   assert property (bus_wen_ctl_sts |=> owr_dat == $past(bus_wdt[0]));
  a_owr_dat_e2:   assert property (!bus_wen_ctl_sts && (pls & (cnt == t_zero))
                    |=> owr_dat == $past(owr_smp));
  a_owr_dat_hold: assert property (!bus_wen_ctl_sts && !(pls & (cnt == t_zero))
                    |=> owr_dat == $past(owr_dat));

  // ---------------------------------------------------------------------------
  // owr_oen (nested: one hold per nesting level)
  // ---------------------------------------------------------------------------
  a_owr_oen_e1: assert property (bus_wen_ctl_sts |=> owr_oen == (~&$past(bus_wdt[1:0])));
  a_owr_oen_e2: assert property (!bus_wen_ctl_sts && pls && (owr_rst & (cnt == t_rsth))
                  |=> owr_oen == 1'b0);
  a_owr_oen_e3: assert property (!bus_wen_ctl_sts && pls && !(owr_rst & (cnt == t_rsth))
                  && (owr_dat & (cnt == t_dat1))
                  |=> owr_oen == 1'b0);
  a_owr_oen_e4: assert property (!bus_wen_ctl_sts && pls && !(owr_rst & (cnt == t_rsth))
                  && !(owr_dat & (cnt == t_dat1)) && (cnt == t_dat0)
                  |=> owr_oen == 1'b0);
  a_owr_oen_hold_in: assert property (!bus_wen_ctl_sts && pls && !(owr_rst & (cnt == t_rsth))
                  && !(owr_dat & (cnt == t_dat1)) && !(cnt == t_dat0)
                  |=> owr_oen == $past(owr_oen));
  a_owr_oen_hold_out: assert property (!bus_wen_ctl_sts && !pls |=> owr_oen == $past(owr_oen));

  // ---------------------------------------------------------------------------
  // owr_smp (no reset). owr_iln is only defined for owr_sel==0 (OWN==1).
  // ---------------------------------------------------------------------------
  a_owr_smp_e1: assert property (pls && (owr_rst & (cnt == t_rstp)) && (owr_sel == 0)
                  |=> owr_smp == $past(owr_iln));
  a_owr_smp_e2: assert property (pls && !(owr_rst & (cnt == t_rstp))
                  && (~owr_rst & (cnt == t_bits)) && (owr_sel == 0)
                  |=> owr_smp == $past(owr_iln));
  a_owr_smp_hold_in: assert property (pls && !(owr_rst & (cnt == t_rstp))
                  && !(~owr_rst & (cnt == t_bits))
                  |=> owr_smp == $past(owr_smp));
  a_owr_smp_hold_out: assert property (!pls |=> owr_smp == $past(owr_smp));

  // ---------------------------------------------------------------------------
  // Bus decode (combinational)
  // ---------------------------------------------------------------------------
  a_bus_ren_ctl_sts: assert property (bus_ren_ctl_sts == (bus_ren & (bus_adr[0] == 1'b0)));
  a_bus_wen_ctl_sts: assert property (bus_wen_ctl_sts == (bus_wen & (bus_adr[0] == 1'b0)));
  a_bus_wen_pwr_sel: assert property (bus_wen_pwr_sel == (bus_wen & (bus_adr[0] == 1'b0)));
  a_bus_wen_cdr_n:   assert property (bus_wen_cdr_n == (bus_wen & (bus_adr[0] == 1'b1)));
  a_bus_wen_cdr_o:   assert property (bus_wen_cdr_o == (bus_wen & (bus_adr[0] == 1'b1)));

  a_req_ovd: assert property (req_ovd == (bus_wen_ctl_sts & bus_wdt[2]));

  // ---------------------------------------------------------------------------
  // Timing wires (evaluated values; OVD branch selected by req_ovd / owr_ovd)
  //   t_idl : ovd 96,  norm 200
  //   t_rst : ovd 96,  norm 192
  //   t_bit : ovd 8,   norm 13
  //   t_rstp: ovd 38,  norm 81
  //   t_rsth: ovd 48,  norm 96
  //   t_dat0: ovd 2,   norm 1
  //   t_dat1: ovd 7,   norm 12
  //   t_bits: ovd 6,   norm 10
  // ---------------------------------------------------------------------------
  a_t_idl_ovd:  assert property (req_ovd  |-> t_idl == 96);
  a_t_idl_nrm:  assert property (!req_ovd |-> t_idl == 200);
  a_t_rst_ovd:  assert property (req_ovd  |-> t_rst == 96);
  a_t_rst_nrm:  assert property (!req_ovd |-> t_rst == 192);
  a_t_bit_ovd:  assert property (req_ovd  |-> t_bit == 8);
  a_t_bit_nrm:  assert property (!req_ovd |-> t_bit == 13);
  a_t_rstp_ovd: assert property (owr_ovd  |-> t_rstp == 38);
  a_t_rstp_nrm: assert property (!owr_ovd |-> t_rstp == 81);
  a_t_rsth_ovd: assert property (owr_ovd  |-> t_rsth == 48);
  a_t_rsth_nrm: assert property (!owr_ovd |-> t_rsth == 96);
  a_t_dat0_ovd: assert property (owr_ovd  |-> t_dat0 == 2);
  a_t_dat0_nrm: assert property (!owr_ovd |-> t_dat0 == 1);
  a_t_dat1_ovd: assert property (owr_ovd  |-> t_dat1 == 7);
  a_t_dat1_nrm: assert property (!owr_ovd |-> t_dat1 == 12);
  a_t_bits_ovd: assert property (owr_ovd  |-> t_bits == 6);
  a_t_bits_nrm: assert property (!owr_ovd |-> t_bits == 10);
  a_t_zero:     assert property (t_zero == 0);

  a_pls_ovd: assert property (owr_ovd  |-> pls == (div == cdr_o));
  a_pls_nrm: assert property (!owr_ovd |-> pls == (div == cdr_n));

  // ---------------------------------------------------------------------------
  // Bus read data
  // ---------------------------------------------------------------------------
  a_bus_rdt_pwr_sel: assert property (bus_rdt_pwr_sel == 24'h000000);
  a_bus_rdt_ctl_sts: assert property (bus_rdt_ctl_sts ==
                       {irq_ena, irq_sts, 1'b0, owr_pwr[0], owr_cyc, owr_ovd, owr_rst, owr_dat});
  a_bus_rdt_ctl:     assert property (!bus_adr[0] |-> bus_rdt == {bus_rdt_pwr_sel, bus_rdt_ctl_sts});
  a_bus_rdt_cdr:     assert property (bus_adr[0] |-> bus_rdt == (cdr_o << 16 | cdr_n));

  // ---------------------------------------------------------------------------
  // IO
  // ---------------------------------------------------------------------------
  a_bus_irq:  assert property (bus_irq == (irq_ena & irq_sts));
  a_owr_p:    assert property (owr_p == owr_pwr);
  a_owr_e:    assert property (owr_e == (owr_oen << owr_sel));
  a_owr_e_s0: assert property (owr_sel == 0  |-> owr_e == owr_oen);
  a_owr_e_s1: assert property (owr_sel != 0  |-> owr_e == 1'b0);
  a_owr_iln:  assert property (owr_sel == 0  |-> owr_iln == owr_i[0]);

  // ---------------------------------------------------------------------------
  // Covers (reachable behaviour)
  // ---------------------------------------------------------------------------
  c_wr_ctl:   cover property (bus_wen_ctl_sts);
  c_wr_cdr_n: cover property (bus_wen_cdr_n);
  c_wr_cdr_o: cover property (bus_wen_cdr_o);
  c_req_ovd:  cover property (req_ovd);
  c_owr_ovd:  cover property (owr_ovd);
  c_pls:      cover property (pls);
  c_cyc_end:  cover property (pls && (cnt == t_zero));
  c_irq_sts:  cover property (irq_sts);
  c_bus_irq:  cover property (bus_irq);
  c_rd_clr:   cover property (bus_ren_ctl_sts && irq_sts);
  c_owr_oen:  cover property (owr_oen);
  c_owr_dat:  cover property (owr_dat);
  c_owr_rst:  cover property (owr_rst && owr_oen);
  c_owr_cyc:  cover property (owr_cyc);
  c_owr_pwr:  cover property (owr_pwr);
  c_div_clr:  cover property (bus_wen && (div != 0));

endmodule

bind sockit_owm sockit_owm_sva #(
  .OVD_E(OVD_E), .CDR_E(CDR_E), .BDW(BDW), .OWN(OWN), .BAW(BAW),
  .BTP_N(BTP_N), .BTP_O(BTP_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_RSTP_N(T_RSTP_N),
  .T_DAT0_N(T_DAT0_N), .T_DAT1_N(T_DAT1_N), .T_BITS_N(T_BITS_N),
  .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_RSTP_O(T_RSTP_O),
  .T_DAT0_O(T_DAT0_O), .T_DAT1_O(T_DAT1_O), .T_BITS_O(T_BITS_O),
  .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O),
  .CDR_N(CDR_N), .CDR_O(CDR_O)
) u_sva (.*);
