// SVA checker for sockit_owm (1-wire master), default parameters.
// Sources:
//   DOC  = doc/sockit_owr.pdf (sections 2.1-4.5, Tables 8-12)
//   RTL  = rtl/sockit_owm.v (named construct)
//
// Derived timing model (used by the cycle/line/sample assertions):
//   pc  : number of base-period pulses (pls) seen while owr_cyc is set since
//         the last control write (W0). At pulse P_k the value is pc = k-1.
//   exp_n : cycle length in base periods, latched at W0 from the written
//         ovd/rst/dat bits (DOC Table 12 / Table 7).

module sockit_owm_sva #(
  parameter BDW     = 32,
  parameter BAW     = 1,
  parameter OWN     = 1,
  parameter CDR_E   = 1,
  parameter CDR_N   = 4,
  parameter CDR_O   = 0,
  parameter T_RSTH_N = 96, parameter T_RSTL_N = 96, parameter T_RSTP_N = 15,
  parameter T_DAT0_N = 12, parameter T_DAT1_N = 1,  parameter T_BITS_N = 3,
  parameter T_RCVR_N = 1,  parameter T_IDLE_N = 200,
  parameter T_RSTH_O = 48, parameter T_RSTL_O = 48, parameter T_RSTP_O = 10,
  parameter T_DAT0_O = 6,  parameter T_DAT1_O = 1,  parameter T_BITS_O = 2,
  parameter T_RCVR_O = 2,  parameter T_IDLE_O = 96,
  parameter CDW = (CDR_E ? ((BDW == 32) ? 16 : 8) : $clog2(CDR_N)),
  parameter TDW = ((T_RSTH_O + T_RSTL_O) > (T_RSTH_N + T_RSTL_N))
                ? $clog2(T_RSTH_O + T_RSTL_O) : $clog2(T_RSTH_N + T_RSTL_N)
)(
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
  input  [OWN-1:0]     owr_pwr,
  input                owr_cyc,
  input                owr_ovd,
  input                owr_rst,
  input                owr_dat,
  input                owr_oen,
  input                owr_smp,
  input                owr_iln,
  input                irq_ena,
  input                irq_sts,
  input  [CDW-1:0]     div,
  input  [CDW-1:0]     cdr_n,
  input  [CDW-1:0]     cdr_o,
  input  [TDW-1:0]     cnt,
  input                pls
);

default clocking @(posedge clk); endclocking
default disable iff (rst);

//////////////////////////////////////////////////////////////////////////////
// auxiliary logic
//////////////////////////////////////////////////////////////////////////////

// control register write (ctl at address 0), cdr write (address 1), ctl read
wire w0 = bus_wen & ~bus_adr[0];
wire w1 = bus_wen & bus_adr[0];
wire r0 = bus_ren & ~bus_adr[0];

// end of count: the RTL end event (pls & cnt==0), and the same qualified by a running cycle
wire endp = pls & (cnt == '0);
wire endc = endp & owr_cyc;

// cycle type of the currently latched control bits
wire typ_w0 = ~owr_rst & ~owr_dat;   // write 0 slot
wire typ_w1 = ~owr_rst &  owr_dat;   // write 1 / read slot
wire typ_rs =  owr_rst & ~owr_dat;   // reset + presence slot
wire typ_id =  owr_rst &  owr_dat;   // timed idle slot

// pulse indices (pc value at the pulse) for release, presence sample, bit sample
wire [7:0] rel_w0  = owr_ovd ? 8'(T_DAT0_O - 1)            : 8'(T_DAT0_N - 1);
wire [7:0] rel_w1  = owr_ovd ? 8'(T_DAT1_O - 1)            : 8'(T_DAT1_N - 1);
wire [7:0] rel_rs  = owr_ovd ? 8'(T_RSTL_O - 1)            : 8'(T_RSTL_N - 1);
wire [7:0] pres_pc = owr_ovd ? 8'(T_RSTL_O + T_RSTP_O - 1) : 8'(T_RSTL_N + T_RSTP_N - 1);
wire [7:0] samp_pc = owr_ovd ? 8'(T_BITS_O - 1)            : 8'(T_BITS_N - 1);

// cycle length in base periods for a control write (DOC Table 12, Table 7)
function automatic [7:0] cyc_len(input logic o, input logic r, input logic d);
  if (!o) begin
    if (!r)      cyc_len = T_DAT0_N + T_RCVR_N;   // write 0 / write 1 (65 us)
    else if (!d) cyc_len = T_RSTL_N + T_RSTH_N;   // reset + presence (960 us)
    else         cyc_len = T_IDLE_N;              // timed idle (1000 us)
  end else begin
    if (!r)      cyc_len = T_DAT0_O + T_RCVR_O;   // overdrive write (8 us)
    else if (!d) cyc_len = T_RSTL_O + T_RSTH_O;   // overdrive reset (96 us)
    else         cyc_len = 8'd0;                  // overdrive zero-time idle: no cycle
  end
endfunction

logic [7:0] pc;
logic [7:0] exp_n;

always @(posedge clk or posedge rst)
  if (rst) begin
    pc    <= 8'd0;
    exp_n <= 8'd0;
  end else if (w0) begin
    pc    <= 8'd0;
    exp_n <= cyc_len(bus_wdt[2], bus_wdt[1], bus_wdt[0]);
  end else if (pls & owr_cyc) begin
    pc    <= pc + 8'd1;
  end

//////////////////////////////////////////////////////////////////////////////
// reset values (DOC Table 10; RTL reset branches)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC 4.2 "reset value of the registers will be as defined by CDR_N"
a_rst_cdr_n: assert property ($past(rst) |-> cdr_n == CDR_N);

// Source: DOC 4.2 "... and CDR_O parameters"
a_rst_cdr_o: assert property ($past(rst) |-> cdr_o == CDR_O);

// Source: DOC Table 10 reset column (ien, irq, pwr, cyc, ovd, rst = 0); RTL resets
// owr_dat and owr_pwr to 0 as well. No 1-wire cycle is active after reset.
a_rst_ctl: assert property ($past(rst) |-> !owr_cyc && !irq_ena && !irq_sts &&
                                           !owr_pwr && !owr_ovd && !owr_rst && !owr_dat);

// Source: RTL output register reset (owr_oen <= 0); line is not driven after reset.
a_rst_line: assert property ($past(rst) |-> !owr_oen);

// Source: RTL clock divider and cycle counter reset (div <= 0, cnt <= 0).
a_rst_div: assert property ($past(rst) |-> div == '0 && cnt == '0);

//////////////////////////////////////////////////////////////////////////////
// write / read-back of the control/status register (DOC Table 10, 11)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC Table 11 bit 7 ien. A control write followed by a read returns the bit.
a_rb_ien: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[7] == $past(bus_wdt[7]));

// Source: DOC Table 11 bit 6 irq: cleared by a control write (RTL irq_sts priority).
a_rb_irq: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[6] == 1'b0);

// Source: DOC Table 11 bit 4 pwr (readback of the written value).
a_rb_pwr: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[4] == $past(bus_wdt[4]));

// Source: DOC Table 11 bit 3 cyc: a write with cyc=1 and not the zero-time idle code reads back 1.
a_rb_cyc: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |->
          bus_rdt[3] == $past(bus_wdt[3] & ~(bus_wdt[2] & bus_wdt[1] & bus_wdt[0])));

// Source: DOC Table 11 bit 2 ovd.
a_rb_ovd: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[2] == $past(bus_wdt[2]));

// Source: DOC Table 11 bit 1 rst.
a_rb_rst: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[1] == $past(bus_wdt[1]));

// Source: DOC Table 11 bit 0 dat (write value, read back before any cycle end).
a_rb_dat: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[0] == $past(bus_wdt[0]));

// Source: DOC 4.2 / Table 8: address 1 holds cdr_n (bits 15..0) and cdr_o (bits 31..16);
// one write to address 1 loads both, a read returns them unchanged.
a_rb_cdr: assert property ((bus_wen & bus_adr[0]) ##1 (bus_ren & bus_adr[0]) |->
          bus_rdt == $past(bus_wdt));

// Source: DOC Table 11 bit 6 read: the status bit reads the interrupt status flag.
a_rb_irq_status: assert property (r0 |-> bus_rdt[6] == irq_sts);

// Source: DOC Table 11 read column: a read of the control/status register returns the
// current enable, power, cycle status, overdrive, reset and data/presence bits.
a_rd_status: assert property (r0 |-> (bus_rdt[7] == irq_ena) && (bus_rdt[4] == owr_pwr[0]) &&
                                     (bus_rdt[3] == owr_cyc) && (bus_rdt[2] == owr_ovd) &&
                                     (bus_rdt[1] == owr_rst) && (bus_rdt[0] == owr_dat));

// Source: DOC Table 8 / 4.2: address 1 read returns cdr_n (15..0) and cdr_o (31..16).
a_rd_cdr: assert property ((bus_ren & bus_adr[0]) |-> bus_rdt == {cdr_o, cdr_n});

//////////////////////////////////////////////////////////////////////////////
// holding behaviour: registers keep their value unless their documented event occurs
//////////////////////////////////////////////////////////////////////////////

// Source: RTL cdr_n/cdr_o load only on a write to address 1 (DOC 4.2 "written ... while no cycle").
a_hold_cdr_n: assert property (!w1 |=> $stable(cdr_n));
a_hold_cdr_o: assert property (!w1 |=> $stable(cdr_o));

// Source: RTL irq_ena, owr_pwr, owr_ovd, owr_rst load only on a control write.
a_hold_ctl: assert property (!w0 |=> $stable({irq_ena, owr_pwr, owr_ovd, owr_rst}));

// Source: RTL owr_cyc changes only on a control write or on the cycle end event.
a_hold_cyc: assert property (!w0 && !endc |=> $stable(owr_cyc));

// Source: RTL owr_dat loads on control write or on the end event (pls & cnt==0).
a_hold_dat: assert property (!w0 && !endp |=> $stable(owr_dat));

// Source: RTL irq_sts holds unless a control write, a control read, or the end event occurs.
a_hold_irq: assert property (!w0 && !r0 && !endp |=> $stable(irq_sts));

// Source: RTL owr_oen loads on control write or on a base-period pulse.
a_hold_oen: assert property (!w0 && !pls |=> $stable(owr_oen));

// Source: RTL cnt loads on control write and decrements only on pls.
a_hold_cnt: assert property (!w0 && !pls |=> $stable(cnt));

// Source: RTL owr_smp loads only on a base-period pulse (its enable is pls).
a_hold_smp: assert property (!pls |=> $stable(owr_smp));

// Source: DOC 4.3 "power ... directly connected" to owr_p; changes only with pwr writes.
a_hold_p: assert property (!w0 |=> $stable(owr_p));

//////////////////////////////////////////////////////////////////////////////
// power output (DOC 2.2.2, 4.3, Table 11 bit 4)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC 4.3 "power[15:0] ... pwr bit from the control/status register is used" (OWN=1).
a_pwr_wr: assert property (w0 |=> owr_p == $past(bus_wdt[4]));

//////////////////////////////////////////////////////////////////////////////
// control write starts/aborts a 1-wire cycle (DOC Table 11 bit 3, Table 12)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC Table 11 bit 3 (write 1 starts a cycle); zero-time idle (ovd=rst=dat=1) is
// the RTL code `wdt[3] & ~&wdt[2:0]` = 0 and DOC Table 12 "0us zero time idle".
a_w0_cyc_start: assert property (w0 |=>
                owr_cyc == $past(bus_wdt[3] & ~(bus_wdt[2] & bus_wdt[1] & bus_wdt[0])));

// Source: RTL `owr_oen <= ~&bus_wdt[1:0]` on a control write: the line is enabled unless
// the written code is the idle cycle (rst=dat=1). NOTE: DOC Table 11 says cyc=0 is no action;
// the RTL still updates owr_oen then (see report). This assertion states the RTL behaviour.
a_w0_line: assert property (w0 |=> owr_oen == !$past(bus_wdt[1] & bus_wdt[0]));

//////////////////////////////////////////////////////////////////////////////
// cycle timing (DOC Table 12, Table 7; counter in base periods)
//////////////////////////////////////////////////////////////////////////////

// Source: RTL cnt loads (T-1) on W0 and decrements per pulse (counter step).
a_cnt_step: assert property (pls & ~w0 & (cnt != '0) |=> cnt == $past(cnt) - 1);

// Source: DOC Table 12 cycle lengths (65/960/1000 us normal, 8/96 us overdrive, in base
// periods) and RTL cnt end condition: the end pulse (cnt==0) is the (exp_n)-th pulse.
// Covers start value, end condition and the restart by a new control write.
a_cyc_len: assert property ((pls & owr_cyc & ~w0) |->
           ((pc == exp_n - 8'd1) == (cnt == '0)));

// Source: RTL `if (pls & cnt==0) owr_cyc <= 0`: the cycle ends at the end event.
a_cyc_end: assert property (endc & ~w0 |=> ~owr_cyc);

//////////////////////////////////////////////////////////////////////////////
// 1-wire line drive (DOC Table 12 waveforms; RTL owr_oen chain)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC 3.2 / Drawing 5: write 0 slot drives the line for T_DAT0 base periods.
// RTL: owr_oen is held 1 until the pulse with cnt==t_dat0 (= pc == T_DAT0-1).
a_line_w0_pre: assert property (owr_cyc & typ_w0 & (pc < rel_w0) |-> owr_oen);
a_line_w0_rel: assert property (pls & owr_cyc & typ_w0 & (pc == rel_w0) & ~w0 |=> ~owr_oen);
a_line_w0_post: assert property (owr_cyc & typ_w0 & (pc > rel_w0) |-> ~owr_oen);

// Source: DOC 3.2 / Drawing 6: write 1 / read slot drives the line for T_DAT1 base periods.
a_line_w1_rel: assert property (pls & owr_cyc & typ_w1 & (pc == rel_w1) & ~w0 |=> ~owr_oen);

// Source: DOC 4.5 / Table 12 reset slot: line low for T_RSTL base periods, then released.
a_line_rs_pre: assert property (owr_cyc & typ_rs & (pc < rel_rs) |-> owr_oen);
a_line_rs_rel: assert property (pls & owr_cyc & typ_rs & (pc == rel_rs) & ~w0 |=> ~owr_oen);
a_line_rs_post: assert property (owr_cyc & typ_rs & (pc > rel_rs) |-> ~owr_oen);

// Source: DOC Table 12 "timed idle cycle" and RTL idle branch: the line is never driven in idle.
a_line_idle: assert property (owr_cyc & typ_id |-> ~owr_oen);

// Source: DOC 2.2.2 / 4.3: the line driver output (owr_e) is only active when the internal
// enable is set. The select mux is unconstrained for OWN=1, so only the implication holds.
a_line_drv: assert property ((|owr_e) |-> owr_oen);

// Source: RTL cycle end clears the line enable (any cycle end).
a_line_end: assert property (endc & ~w0 |=> ~owr_oen);

//////////////////////////////////////////////////////////////////////////////
// sampling and data path (DOC 2.3, 4.4 bit 0; RTL owr_smp/owr_dat)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC 4.4 bit 0 "presence detect status" and RTL presence sample (owr_rst & cnt==t_rstp).
// Sampled at pc = T_RSTL + T_RSTP - 1, i.e. 15 base periods after the reset release (normal).
a_samp_pres: assert property (pls & owr_cyc & ~w0 & typ_rs & (pc == pres_pc)
                              |=> owr_smp == $past(owr_iln));

// Source: DOC 4.4 bit 0 "data receive status" and RTL read sample (cnt==t_bits, pc = T_BITS-1).
a_samp_rd: assert property (pls & owr_cyc & ~w0 & typ_w1 & (pc == samp_pc)
                            |=> owr_smp == $past(owr_iln));

// Source: DOC 4.4 bit 0 (read value of the slot) and RTL end latch (owr_dat <= owr_smp at end).
a_dat_rd: assert property (endc & ~w0 & typ_w1 |=> owr_dat == $past(owr_smp));

// Source: DOC 4.4 bit 0 (presence status) and RTL end latch after reset slot.
a_dat_pres: assert property (endc & ~w0 & typ_rs |=> owr_dat == $past(owr_smp));

//////////////////////////////////////////////////////////////////////////////
// clock divider (DOC 2.1.3 / 4.2 and RTL div logic)
//////////////////////////////////////////////////////////////////////////////

// Source: RTL `if (bus_wen) div <= 0` (a bus write restarts the divider).
a_div_wr: assert property (bus_wen |=> div == '0);

// Source: RTL `div <= div + owr_cyc` only inside a cycle: the divider is idle otherwise.
a_div_idle: assert property (~owr_cyc |-> div == '0);

// Source: RTL `div <= div + owr_cyc` (counter step while a cycle runs, no pulse, no write).
a_div_step: assert property (owr_cyc & ~bus_wen & ~pls |=> div == $past(div) + 1);

// Source: RTL pls = (div == ratio) and div <= 0 at pls: no back-to-back pulses for ratio != 0.
a_div_gap: assert property (pls & ~bus_wen & ((owr_ovd ? cdr_o : cdr_n) != '0) |=> ~pls);

//////////////////////////////////////////////////////////////////////////////
// interrupt (DOC Table 11 bits 6/7, 2.2.1; RTL irq logic)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC Table 11 bit 6 "set on end of 1-wire cycle": RTL `pls & cnt==0` sets irq_sts.
a_irq_set: assert property (endc & ~w0 |=> irq_sts);

// Source: RTL irq_sts priority: it can only be set by the end event.
a_irq_set_only_end: assert property (~irq_sts & ~endp |=> ~irq_sts);

// Source: RTL irq_sts priority: a control write has priority over the end event (clears).
a_irq_wr_wins: assert property (w0 & endp |=> ~irq_sts);

// Source: DOC Table 11 bit 6 "cleared by bus read": RTL `else if (bus_ren_ctl_sts) irq_sts <= 0`.
a_irq_rd_clr: assert property (r0 & ~w0 & ~endp |=> ~irq_sts);

// Source: DOC 2.2.1 "interrupt is cleared after reading the control/status register".
// Interrupt output = enable AND status (RTL assign bus_irq).
a_irq_out_set: assert property (endc & ~w0 & irq_ena |=> bus_irq);
a_irq_out_gate: assert property (~irq_ena |-> ~bus_irq);
a_irq_out_sts: assert property (irq_ena & irq_sts |-> bus_irq);
a_irq_out_clr: assert property (r0 & ~w0 & ~endp |=> ~bus_irq);

endmodule

bind sockit_owm sockit_owm_sva #(
  .BDW(BDW), .BAW(BAW), .OWN(OWN), .CDR_E(CDR_E), .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_RSTP_N(T_RSTP_N),
  .T_DAT0_N(T_DAT0_N), .T_DAT1_N(T_DAT1_N), .T_BITS_N(T_BITS_N),
  .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_RSTP_O(T_RSTP_O),
  .T_DAT0_O(T_DAT0_O), .T_DAT1_O(T_DAT1_O), .T_BITS_O(T_BITS_O),
  .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);
