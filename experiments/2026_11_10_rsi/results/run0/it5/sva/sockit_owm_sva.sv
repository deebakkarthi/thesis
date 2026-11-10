//////////////////////////////////////////////////////////////////////////////
// SVA checker for sockit_owm (1-wire master, Avalon-style bus)
//
// Top        : sockit_owm (single module, no submodules)
// Clock      : clk  (posedge)
// Reset      : rst==1'b1 (active high, ASYNCHRONOUS: posedge rst in all
//              always blocks of the DUT that have a reset branch)
//
// Step 0 - parameters as elaborated (DUT defaults, tcl does not override):
//   OVD_E=1  CDR_E=1  BDW=32  OWN=1  BAW=1 (no __ICARUS__ => BAW=1)
//   BTP_N="5.0"  BTP_O="1.0"
//   T_RSTH_N=96  T_RSTL_N=96  T_RSTP_N=15  T_DAT0_N=12  T_DAT1_N=1
//   T_BITS_N=3   T_RCVR_N=1   T_IDLE_N=200
//   T_RSTH_O=48  T_RSTL_O=48  T_RSTP_O=10  T_DAT0_O=6   T_DAT1_O=1
//   T_BITS_O=2   T_RCVR_O=2   T_IDLE_O=96
//   CDR_N=5-1=4  CDR_O=1-1=0
//   generate conditions (all selected):
//     CDR_E (true) -> cdr_n/cdr_o always blocks; the "else initial" is dropped
//     BDW==32      -> 32-bit bus read/write decode; BDW==8 branches dropped
//     OWN>1 false  -> sel_implementation else-branch (owr_pwr 1 bit, owr_sel
//                     initial only); OWN>1 branches (bus_rdt_pwr_sel from
//                     owr_pwr, owr_sel write) dropped
//     OVD_E (true) -> req_ovd = bus_wen_ctl_sts & bus_wdt[2]
//   localparams:
//     PDW = 24          CDW = 16          SDW = $clog2(1) = 0
//     TDW = $clog2(192) = 8   (96 > 192 is false -> normal-mode sum)
//   SDW=0 => owr_sel is declared [-1:0] = 2 bits wide (not zero width).
//   owr_sel and owr_i[owr_sel] / owr_oen<<owr_sel with OWN=1 are index
//   expressions that can be out of range.
//
// Step 1 - signal inventory and priority structure
//
// Sequential (all posedge clk, async reset unless noted):
//   cdr_n [15:0]: reset -> 4
//                 if (bus_wen_cdr_n)  <- e1 (= bus_wdt[15:0])
//                 else                <- hold
//   cdr_o [15:0]: reset -> 0
//                 if (bus_wen_cdr_o)  <- e1 (= bus_wdt[31:16])
//                 else                <- hold
//   div   [15:0]: reset -> 0
//                 if (bus_wen)        <- e1 -> 0
//                 else if (pls)       <- e2 -> 0
//                 else                <- e3 -> div + owr_cyc
//   owr_pwr[0]  : reset -> 0
//                 if (bus_wen_ctl_sts) <- e1 (= bus_wdt[4])
//                 else                 <- hold
//   irq_ena     : reset -> 0
//                 if (bus_wen_ctl_sts) <- e1 (= bus_wdt[7])
//                 else                 <- hold
//   irq_sts     : reset -> 0
//                 if (bus_wen_ctl_sts)                <- e1 -> 0
//                 else if (pls & cnt==t_zero)         <- e2 -> 1
//                 else if (bus_ren_ctl_sts)           <- e3 -> 0
//                 else                                <- hold
//   owr_ovd     : reset -> 0
//                 if (bus_wen_ctl_sts) <- e1 (= req_ovd)
//                 else                 <- hold
//   owr_rst     : reset -> 0
//                 if (bus_wen_ctl_sts) <- e1 (= bus_wdt[1])
//                 else                 <- hold
//   owr_dat     : reset -> 0
//                 if (bus_wen_ctl_sts)                <- e1 (= bus_wdt[0])
//                 else if (pls & cnt==t_zero)         <- e2 (= owr_smp)
//                 else                                <- hold
//   owr_cyc     : reset -> 0
//                 if (bus_wen_ctl_sts)                <- e1 (= bus_wdt[3] & ~&bus_wdt[2:0])
//                 else if (pls & cnt==t_zero)         <- e2 -> 0
//                 else                                <- hold
//   cnt   [7:0] : reset -> 0
//                 if (bus_wen_ctl_sts) <- e1a (&bus_wdt[1:0])        -> t_idl-1
//                                      <- e1b (!&wdt && wdt[1])      -> t_rst-1
//                                      <- e1c (!&wdt && !wdt[1])     -> t_bit-1
//                 else if (pls)        <- e2 -> cnt-1 (wraps)
//                 else                 <- hold
//   owr_oen     : reset -> 0
//                 if (bus_wen_ctl_sts)                    <- e1 (= ~&bus_wdt[1:0])
//                 else if (pls) begin
//                   if (owr_rst & cnt==t_rsth)            <- e2 -> 0
//                   else if (owr_dat & cnt==t_dat1)       <- e3 -> 0
//                   else if (cnt==t_dat0)                 <- e4 -> 0
//                   else                                  <- hold_inner
//                 end
//                 else                                    <- hold_outer
//   owr_smp     : NO RESET (arbitrary start value)
//                 if (pls) begin
//                   if (owr_rst & cnt==t_rstp)            <- e1 (= owr_iln)
//                   else if (~owr_rst & cnt==t_bits)      <- e2 (= owr_iln)
//                   else                                  <- hold_inner
//                 end
//                 else                                    <- hold_outer
//   owr_sel [-1:0]: NOT reset, assigned ONLY in an initial block
//                 -> FREE. No assertion constrains its value; only case splits
//                    on it are written.
//
// Combinational (continuous assigns / outputs):
//   bus_ren_ctl_sts, bus_wen_ctl_sts, bus_wen_pwr_sel,
//   bus_wen_cdr_n, bus_wen_cdr_o           : bus_en & (bus_adr[0] == sel)
//   bus_rdt_ctl_sts [7:0]                  : {irq_ena,irq_sts,0,owr_pwr[0],owr_cyc,owr_ovd,owr_rst,owr_dat}
//   bus_rdt_pwr_sel [23:0]                 : constant 0 (OWN>1 false)
//   bus_rdt [31:0] (output)                : adr[0]==0 ? {pwr_sel,ctl_sts} : {cdr_o,cdr_n}
//   req_ovd                                : bus_wen_ctl_sts & bus_wdt[2]
//   pls                                    : div == (owr_ovd ? cdr_o : cdr_n)
//   t_idl  : req_ovd ? 96 : 200
//   t_rst  : req_ovd ? 96 : 192
//   t_bit  : req_ovd ? 8  : 13
//   t_rstp : owr_ovd ? 38 : 81
//   t_rsth : owr_ovd ? 48 : 96
//   t_dat0 : owr_ovd ? 2  : 1
//   t_dat1 : owr_ovd ? 7  : 12
//   t_bits : owr_ovd ? 6  : 10
//   t_zero : 0
//   owr_iln                                : owr_i[owr_sel]  (OOR for sel 1..3 -> X)
//   owr_e [0:0] (output)                   : owr_oen << owr_sel
//   owr_p [0:0] (output)                   : owr_pwr
//   bus_irq (output)                       : irq_ena & irq_sts
//
// Checker-only helper state (not in DUT):
//   first_cyc : 1 while in reset, used for reset-value asserts.
//   smp_ok    : owr_smp currently holds a sample taken with owr_sel==0.
//   dat_ok    : owr_dat currently holds a defined value (not loaded from an
//               owr_smp that came from an out-of-range owr_iln).
//////////////////////////////////////////////////////////////////////////////

module sockit_owm_sva #(
  // DUT parameters, same names, DUT defaults
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
  parameter CDR_N    = 5-1,
  parameter CDR_O    = 1-1,
  // DUT localparams, recomputed here so they can size ports
  parameter PDW = (BDW==32) ? 24 : 8,
  parameter CDW = CDR_E ? ((BDW==32) ? 16 : 8) : $clog2(CDR_N),
  parameter SDW = $clog2(OWN),
  parameter TDW = ((T_RSTH_O+T_RSTL_O) > (T_RSTH_N+T_RSTL_N))
                ? $clog2(T_RSTH_O+T_RSTL_O) : $clog2(T_RSTH_N+T_RSTL_N)
)(
  // system
  input                 clk,
  input                 rst,
  // bus
  input                 bus_ren,
  input                 bus_wen,
  input  [BAW-1:0]      bus_adr,
  input  [BDW-1:0]      bus_wdt,
  input  [BDW-1:0]      bus_rdt,
  input                 bus_irq,
  // 1-wire
  input  [OWN-1:0]      owr_p,
  input  [OWN-1:0]      owr_e,
  input  [OWN-1:0]      owr_i,
  // internal signals of the DUT (same names and widths)
  input                 bus_ren_ctl_sts,
  input                 bus_wen_ctl_sts,
  input                 bus_wen_pwr_sel,
  input                 bus_wen_cdr_n,
  input                 bus_wen_cdr_o,
  input  [7:0]          bus_rdt_ctl_sts,
  input  [PDW-1:0]      bus_rdt_pwr_sel,
  input  [CDW-1:0]      div,
  input  [CDW-1:0]      cdr_n,
  input  [CDW-1:0]      cdr_o,
  input                 pls,
  input                 owr_cyc,
  input  [TDW-1:0]      cnt,
  input  [SDW-1:0]      owr_sel,
  input                 req_ovd,
  input  [OWN-1:0]      owr_pwr,
  input                 owr_ovd,
  input                 owr_rst,
  input                 owr_dat,
  input                 owr_smp,
  input                 owr_oen,
  input                 owr_iln,
  input                 irq_ena,
  input                 irq_sts,
  input  [TDW-1:0]      t_idl,
  input  [TDW-1:0]      t_rst,
  input  [TDW-1:0]      t_bit,
  input  [TDW-1:0]      t_rstp,
  input  [TDW-1:0]      t_rsth,
  input  [TDW-1:0]      t_dat0,
  input  [TDW-1:0]      t_dat1,
  input  [TDW-1:0]      t_bits,
  input  [TDW-1:0]      t_zero
);

  default clocking cb @(posedge clk); endclocking
  default disable iff (rst);

  //////////////////////////////////////////////////////////////////////////
  // checker-only helper state
  //////////////////////////////////////////////////////////////////////////

  // reset-value window: 1 while in reset, cleared at first clock with rst low
  logic first_cyc;
  always @(posedge clk or posedge rst)
    if (rst) first_cyc <= 1'b1; else first_cyc <= 1'b0;

  // owr_smp load strobe (mirrors the owr_smp always block exactly)
  wire smp_ld = pls && ((owr_rst && (cnt == t_rstp)) || (!owr_rst && (cnt == t_bits)));

  // smp_ok: owr_smp holds a value sampled from owr_i[0] (owr_sel was 0)
  logic smp_ok;
  always @(posedge clk or posedge rst)
    if (rst)          smp_ok <= 1'b0;
    else if (smp_ld) smp_ok <= (owr_sel == 0);

  // dat_ok: owr_dat holds a defined value
  logic dat_ok;
  always @(posedge clk or posedge rst)
    if (rst)                                 dat_ok <= 1'b1;   // owr_dat reset to 0
    else if (bus_wen_ctl_sts)                dat_ok <= 1'b1;   // loaded from bus_wdt[0]
    else if (pls && (cnt == t_zero))         dat_ok <= smp_ok; // loaded from owr_smp

  //////////////////////////////////////////////////////////////////////////
  // reset values (first cycle after reset)
  //////////////////////////////////////////////////////////////////////////

  a_rst_cdr_n:     assert property (first_cyc |-> cdr_n == 4);
  a_rst_cdr_o:     assert property (first_cyc |-> cdr_o == 0);
  a_rst_div:       assert property (first_cyc |-> div == 0);
  a_rst_owr_pwr:   assert property (first_cyc |-> owr_pwr == 0);
  a_rst_irq_ena:   assert property (first_cyc |-> irq_ena == 0);
  a_rst_irq_sts:   assert property (first_cyc |-> irq_sts == 0);
  a_rst_owr_ovd:   assert property (first_cyc |-> owr_ovd == 0);
  a_rst_owr_rst:   assert property (first_cyc |-> owr_rst == 0);
  a_rst_owr_dat:   assert property (first_cyc |-> owr_dat == 0);
  a_rst_owr_cyc:   assert property (first_cyc |-> owr_cyc == 0);
  a_rst_cnt:       assert property (first_cyc |-> cnt == 0);
  a_rst_owr_oen:   assert property (first_cyc |-> owr_oen == 0);

  //////////////////////////////////////////////////////////////////////////
  // cdr_n / cdr_o (clock divider ratio registers)
  //////////////////////////////////////////////////////////////////////////

  a_cdr_n_wr:      assert property (bus_wen_cdr_n  |=> cdr_n == $past(bus_wdt[15:0]));
  a_cdr_n_hold:    assert property (!bus_wen_cdr_n |=> cdr_n == $past(cdr_n));
  a_cdr_o_wr:      assert property (bus_wen_cdr_o  |=> cdr_o == $past(bus_wdt[31:16]));
  a_cdr_o_hold:    assert property (!bus_wen_cdr_o |=> cdr_o == $past(cdr_o));

  //////////////////////////////////////////////////////////////////////////
  // div (clock divider counter)
  //////////////////////////////////////////////////////////////////////////

  a_div_wen:       assert property (bus_wen |=> div == 0);
  a_div_pls:       assert property (!bus_wen && pls |=> div == 0);
  a_div_inc:       assert property (!bus_wen && !pls
                                    |=> div == $bits(div)'($past(div) + $past(owr_cyc)));

  //////////////////////////////////////////////////////////////////////////
  // owr_pwr (power enable, OWN=1)
  //////////////////////////////////////////////////////////////////////////

  a_owr_pwr_wr:    assert property (bus_wen_ctl_sts  |=> owr_pwr == $past(bus_wdt[4]));
  a_owr_pwr_hold:  assert property (!bus_wen_ctl_sts |=> owr_pwr == $past(owr_pwr));

  //////////////////////////////////////////////////////////////////////////
  // irq_ena / irq_sts
  //////////////////////////////////////////////////////////////////////////

  a_irq_ena_wr:    assert property (bus_wen_ctl_sts  |=> irq_ena == $past(bus_wdt[7]));
  a_irq_ena_hold:  assert property (!bus_wen_ctl_sts |=> irq_ena == $past(irq_ena));

  a_irq_sts_wr:    assert property (bus_wen_ctl_sts |=> irq_sts == 0);
  a_irq_sts_set:   assert property (!bus_wen_ctl_sts && pls && (cnt == t_zero)
                                    |=> irq_sts == 1);
  a_irq_sts_ren:   assert property (!bus_wen_ctl_sts && !(pls && (cnt == t_zero))
                                    && bus_ren_ctl_sts
                                    |=> irq_sts == 0);
  a_irq_sts_hold:  assert property (!bus_wen_ctl_sts && !(pls && (cnt == t_zero))
                                    && !bus_ren_ctl_sts
                                    |=> irq_sts == $past(irq_sts));

  //////////////////////////////////////////////////////////////////////////
  // owr_ovd / owr_rst
  //////////////////////////////////////////////////////////////////////////

  a_owr_ovd_wr:    assert property (bus_wen_ctl_sts  |=> owr_ovd == $past(req_ovd));
  a_owr_ovd_hold:  assert property (!bus_wen_ctl_sts |=> owr_ovd == $past(owr_ovd));

  a_owr_rst_wr:    assert property (bus_wen_ctl_sts  |=> owr_rst == $past(bus_wdt[1]));
  a_owr_rst_hold:  assert property (!bus_wen_ctl_sts |=> owr_rst == $past(owr_rst));

  //////////////////////////////////////////////////////////////////////////
  // owr_dat
  //////////////////////////////////////////////////////////////////////////

  a_owr_dat_wr:    assert property (bus_wen_ctl_sts |=> owr_dat == $past(bus_wdt[0]));
  a_owr_dat_smp:   assert property (!bus_wen_ctl_sts && pls && (cnt == t_zero) && smp_ok
                                    |=> owr_dat == $past(owr_smp));
  a_owr_dat_hold:  assert property (!bus_wen_ctl_sts && !(pls && (cnt == t_zero)) && dat_ok
                                    |=> owr_dat == $past(owr_dat));

  //////////////////////////////////////////////////////////////////////////
  // owr_cyc
  //////////////////////////////////////////////////////////////////////////

  a_owr_cyc_wr:    assert property (bus_wen_ctl_sts
                                    |=> owr_cyc == $past(bus_wdt[3] & ~&bus_wdt[2:0]));
  a_owr_cyc_clr:   assert property (!bus_wen_ctl_sts && pls && (cnt == t_zero)
                                    |=> owr_cyc == 0);
  a_owr_cyc_hold:  assert property (!bus_wen_ctl_sts && !(pls && (cnt == t_zero))
                                    |=> owr_cyc == $past(owr_cyc));

  //////////////////////////////////////////////////////////////////////////
  // cnt (cycle counter, 8 bit, wraps)
  //////////////////////////////////////////////////////////////////////////

  a_cnt_ld_idl:    assert property (bus_wen_ctl_sts && (&bus_wdt[1:0])
                                    |=> cnt == $bits(cnt)'($past(t_idl) - 1));
  a_cnt_ld_rst:    assert property (bus_wen_ctl_sts && !(&bus_wdt[1:0]) && bus_wdt[1]
                                    |=> cnt == $bits(cnt)'($past(t_rst) - 1));
  a_cnt_ld_bit:    assert property (bus_wen_ctl_sts && !(&bus_wdt[1:0]) && !bus_wdt[1]
                                    |=> cnt == $bits(cnt)'($past(t_bit) - 1));
  a_cnt_dec:       assert property (!bus_wen_ctl_sts && pls
                                    |=> cnt == $bits(cnt)'($past(cnt) - 1));
  a_cnt_hold:      assert property (!bus_wen_ctl_sts && !pls
                                    |=> cnt == $past(cnt));

  //////////////////////////////////////////////////////////////////////////
  // owr_oen (output enable, nested if: two hold assertions)
  //////////////////////////////////////////////////////////////////////////

  a_owr_oen_wr:    assert property (bus_wen_ctl_sts
                                    |=> owr_oen == $past(~&bus_wdt[1:0]));
  a_owr_oen_rstp:  assert property (!bus_wen_ctl_sts && pls && owr_rst && (cnt == t_rsth)
                                    |=> owr_oen == 0);
  a_owr_oen_dat1:  assert property (!bus_wen_ctl_sts && pls
                                    && !(owr_rst && (cnt == t_rsth))
                                    && owr_dat && (cnt == t_dat1)
                                    |=> owr_oen == 0);
  a_owr_oen_dat0:  assert property (!bus_wen_ctl_sts && pls
                                    && !(owr_rst && (cnt == t_rsth))
                                    && !(owr_dat && (cnt == t_dat1))
                                    && (cnt == t_dat0)
                                    |=> owr_oen == 0);
  a_owr_oen_hold_o: assert property (!bus_wen_ctl_sts && !pls
                                    |=> owr_oen == $past(owr_oen));
  a_owr_oen_hold_i: assert property (!bus_wen_ctl_sts && pls
                                    && !(owr_rst && (cnt == t_rsth))
                                    && !(owr_dat && (cnt == t_dat1))
                                    && !(cnt == t_dat0)
                                    |=> owr_oen == $past(owr_oen));

  //////////////////////////////////////////////////////////////////////////
  // owr_smp (no reset; asserted only one cycle after a load, or as hold)
  //////////////////////////////////////////////////////////////////////////

  a_owr_smp_rd:    assert property (pls && owr_rst && (cnt == t_rstp) && (owr_sel == 0)
                                    |=> owr_smp == $past(owr_iln));
  a_owr_smp_bit:   assert property (pls && !(owr_rst && (cnt == t_rstp))
                                    && !owr_rst && (cnt == t_bits) && (owr_sel == 0)
                                    |=> owr_smp == $past(owr_iln));
  a_owr_smp_hold_i: assert property (pls && !(owr_rst && (cnt == t_rstp))
                                    && !(!owr_rst && (cnt == t_bits)) && smp_ok
                                    |=> owr_smp == $past(owr_smp));
  a_owr_smp_hold_o: assert property (!pls && smp_ok
                                    |=> owr_smp == $past(owr_smp));

  //////////////////////////////////////////////////////////////////////////
  // combinational wires
  //////////////////////////////////////////////////////////////////////////

  a_bus_ren_ctl_sts: assert property (bus_ren_ctl_sts == (bus_ren & (bus_adr[0] == 1'b0)));
  a_bus_wen_ctl_sts: assert property (bus_wen_ctl_sts == (bus_wen & (bus_adr[0] == 1'b0)));
  a_bus_wen_pwr_sel: assert property (bus_wen_pwr_sel == (bus_wen & (bus_adr[0] == 1'b0)));
  a_bus_wen_cdr_n:   assert property (bus_wen_cdr_n   == (bus_wen & (bus_adr[0] == 1'b1)));
  a_bus_wen_cdr_o:   assert property (bus_wen_cdr_o   == (bus_wen & (bus_adr[0] == 1'b1)));

  a_bus_rdt_ctl_sts: assert property (dat_ok |-> bus_rdt_ctl_sts ==
                       {irq_ena, irq_sts, 1'b0, owr_pwr[0], owr_cyc, owr_ovd, owr_rst, owr_dat});
  a_bus_rdt_pwr_sel: assert property (bus_rdt_pwr_sel == 0);

  // bus_rdt mux: one assertion per select value
  a_bus_rdt_ctl:   assert property (dat_ok && (bus_adr[0] == 1'b0)
                                    |-> bus_rdt == {bus_rdt_pwr_sel, bus_rdt_ctl_sts});
  a_bus_rdt_cdr:   assert property ((bus_adr[0] == 1'b1)
                                    |-> bus_rdt == {cdr_o, cdr_n});

  a_req_ovd:       assert property (req_ovd == (bus_wen_ctl_sts & bus_wdt[2]));
  a_pls_ovd:       assert property (owr_ovd  |-> pls == (div == cdr_o));
  a_pls_nrm:       assert property (!owr_ovd |-> pls == (div == cdr_n));

  // owr_iln: only the in-range select is asserted (owr_sel 1..3 is out of range)
  a_owr_iln:       assert property ((owr_sel == 0) |-> owr_iln == owr_i[0]);

  a_owr_e:         assert property ((owr_sel == 0) |-> owr_e == owr_oen);
  a_owr_p:         assert property (owr_p == owr_pwr);
  a_bus_irq:       assert property (bus_irq == (irq_ena & irq_sts));

  //////////////////////////////////////////////////////////////////////////
  // parameter-derived wires: evaluated value per select
  //////////////////////////////////////////////////////////////////////////

  a_t_idl_ovd:     assert property (req_ovd  |-> t_idl == 96);
  a_t_idl_nrm:     assert property (!req_ovd |-> t_idl == 200);
  a_t_rst_ovd:     assert property (req_ovd  |-> t_rst == 96);
  a_t_rst_nrm:     assert property (!req_ovd |-> t_rst == 192);
  a_t_bit_ovd:     assert property (req_ovd  |-> t_bit == 8);
  a_t_bit_nrm:     assert property (!req_ovd |-> t_bit == 13);

  a_t_rstp_ovd:    assert property (owr_ovd  |-> t_rstp == 38);
  a_t_rstp_nrm:    assert property (!owr_ovd |-> t_rstp == 81);
  a_t_rsth_ovd:    assert property (owr_ovd  |-> t_rsth == 48);
  a_t_rsth_nrm:    assert property (!owr_ovd |-> t_rsth == 96);
  a_t_dat0_ovd:    assert property (owr_ovd  |-> t_dat0 == 2);
  a_t_dat0_nrm:    assert property (!owr_ovd |-> t_dat0 == 1);
  a_t_dat1_ovd:    assert property (owr_ovd  |-> t_dat1 == 7);
  a_t_dat1_nrm:    assert property (!owr_ovd |-> t_dat1 == 12);
  a_t_bits_ovd:    assert property (owr_ovd  |-> t_bits == 6);
  a_t_bits_nrm:    assert property (!owr_ovd |-> t_bits == 10);
  a_t_zero:        assert property (t_zero == 0);

  //////////////////////////////////////////////////////////////////////////
  // covers (reachability; single-cycle states)
  //////////////////////////////////////////////////////////////////////////

  c_wr_ctl:        cover property (bus_wen_ctl_sts);
  c_wr_cdr:        cover property (bus_wen_cdr_n);
  c_rd_ctl:        cover property (bus_ren_ctl_sts);
  c_ld_idl:        cover property (bus_wen_ctl_sts && (&bus_wdt[1:0]));
  c_owr_cyc:       cover property (owr_cyc);
  c_pls:           cover property (pls);
  c_owr_ovd:       cover property (owr_ovd);
  c_owr_rst:       cover property (owr_rst);
  c_owr_dat:       cover property (owr_dat);
  c_owr_oen:       cover property (owr_oen);
  c_owr_pwr:       cover property (owr_pwr);
  c_irq_ena:       cover property (irq_ena);
  c_irq_sts:       cover property (irq_sts);
  c_bus_irq:       cover property (bus_irq);
  c_owr_smp:       cover property (owr_smp);
  c_oen_rstp:      cover property (!bus_wen_ctl_sts && pls && owr_rst && (cnt == t_rsth));

endmodule

bind sockit_owm sockit_owm_sva #(
  .OVD_E(1), .CDR_E(1), .BDW(32), .OWN(1), .BAW(1),
  .BTP_N("5.0"), .BTP_O("1.0"),
  .T_RSTH_N(96), .T_RSTL_N(96), .T_RSTP_N(15), .T_DAT0_N(12), .T_DAT1_N(1),
  .T_BITS_N(3),  .T_RCVR_N(1),  .T_IDLE_N(200),
  .T_RSTH_O(48), .T_RSTL_O(48), .T_RSTP_O(10), .T_DAT0_O(6),  .T_DAT1_O(1),
  .T_BITS_O(2),  .T_RCVR_O(2),  .T_IDLE_O(96),
  .CDR_N(4), .CDR_O(0)
) u_sva (.*);

//////////////////////////////////////////////////////////////////////////////
// Final completeness checklist
// - [x] every register: one assert per explicit branch, one per implicit hold
//       at every nesting level (owr_oen, owr_smp: hold_outer + hold_inner),
//       one reset-value assert (12 registers with reset)
// - [x] every continuous assign / output port: exact-value assert
//       (bus_rdt per adr select, owr_iln / owr_e for owr_sel==0)
// - [x] every parameter-derived wire: evaluated-value assert per select
// - [x] no assert on the value of owr_sel (free); owr_smp/owr_dat asserts
//       gated by smp_ok / dat_ok where an out-of-range owr_iln could reach them
// - [x] 16 short reachable covers
// - [x] syntax check clean (jg compile only; warnings are in rtl/ only)
//////////////////////////////////////////////////////////////////////////////
