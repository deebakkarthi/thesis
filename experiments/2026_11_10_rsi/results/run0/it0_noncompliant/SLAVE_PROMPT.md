# Task: Write SystemVerilog Assertions for `rtl/sockit_owm.v`

Working directory: `/var/home/brg8ve/.local/src/thesis/experiments/2026_11_10_rsi`

You are a formal verification engineer. Write SVA for the 1-wire master in
`rtl/sockit_owm.v` (read the whole file first). The properties are proven with
Cadence JasperGold, and you are graded on:

1. **proven %** = proven asserts / total asserts  (a failing or undetermined assert hurts you)
2. **covered %** = covered cover properties / total covers (an unreachable cover hurts you)
3. **Formal coverage** (mutation-based, `check_cov`): the fraction of RTL code
   (statements, branches, toggle bits of every register/wire) whose mutation is
   detected by at least one *proven* assertion. To score well, the asserts must
   together constrain the exact next-state value of **every** register and
   every output.

## Files you must create

1. `sva/sockit_owm_sva.sv` — a checker module plus a `bind`:
   ```systemverilog
   module sockit_owm_sva #(parameter BDW=32, OWN=1, BAW=1, CDW=16, TDW=8) (
     input clk, rst, ... // every port AND every internal signal you check
   );
     default clocking cb @(posedge clk); endclocking
     default disable iff (rst);
     ...
   endmodule

   bind sockit_owm sockit_owm_sva #(.BDW(BDW), .OWN(OWN), .BAW(BAW), .CDW(CDW), .TDW(TDW))
     u_sva (.*);
   ```
   `.*` connects by name, so every input of the checker must have the *same
   name* as a signal (port, reg, wire) inside `sockit_owm`. Use `.*` and name
   the checker inputs exactly as in the RTL.
2. `sockit_owm_sva.f` — one line: `./sva/sockit_owm_sva.sv`

Do NOT modify `rtl/`, `sockit_owm.tcl`, or `sockit_owm.f`.

## Design facts (default parameters — these are what get elaborated)

- `BDW=32`, `OWN=1`, `BAW=1`, `OVD_E=1`, `CDR_E=1`, so `CDW=16`, `PDW=24`,
  `SDW=$clog2(1)=0`.
- `BTP_N="5.0"`, `BTP_O="1.0"` → normal: RSTH=96 RSTL=96 RSTP=15 DAT0=12
  DAT1=1 BITS=3 RCVR=1 IDLE=200; overdrive: RSTH=48 RSTL=48 RSTP=10 DAT0=6
  DAT1=1 BITS=2 RCVR=2 IDLE=96. `TDW=$clog2(192)=8`.
- `CDR_N=4`, `CDR_O=0`.
- Reset `rst` is active-high, async. JasperGold is run with `reset rst==1'b1`.
- With BDW==32, address bit `bus_adr[0]` selects: 0 → ctl/sts register,
  1 → clock divider register (`cdr_n` = wdt[15:0], `cdr_o` = wdt[31:16]).
  Note `bus_wen_pwr_sel` == `bus_wen_ctl_sts` when BDW==32.
- Avoid `owr_sel`/`SDW` (zero-width when OWN=1). Don't reference `owr_smp`'s
  reset value (it has no reset).

## How to write high-value assertions

Write one "next-state" assertion per register branch, mirroring the RTL
priority exactly, using `$past` or `|=>`. Examples of the style wanted:

```systemverilog
// irq_ena
a_irq_ena_wr:   assert property (bus_wen && !bus_adr[0] |=> irq_ena == $past(bus_wdt[7]));
a_irq_ena_hold: assert property (!(bus_wen && !bus_adr[0]) |=> $stable(irq_ena));
// div
a_div_wen: assert property (bus_wen |=> div == 0);
a_div_pls: assert property (!bus_wen && pls |=> div == 0);
a_div_cnt: assert property (!bus_wen && !pls |=> div == $past(div) + $past(owr_cyc));
// combinational outputs
a_irq_out: assert property (bus_irq == (irq_ena & irq_sts));
a_rdt0:    assert property (!bus_adr[0] |-> bus_rdt == {24'h0, irq_ena, irq_sts, 1'b0, owr_pwr[0], owr_cyc, owr_ovd, owr_rst, owr_dat});
```

Cover every register and output: `cdr_n`, `cdr_o`, `div`, `pls`, `owr_pwr`,
`irq_ena`, `irq_sts`, `owr_ovd`, `owr_rst`, `owr_dat`, `owr_cyc`, `cnt`,
`owr_oen`, `owr_smp` (only its update conditions, under `pls`), `owr_e`,
`owr_p`, `bus_rdt` (both address cases), `bus_irq`, and the timing wires
(`t_rstp`, `t_bits`, etc. as functions of `owr_ovd`/`req_ovd`). Also write
asserts for every branch of `cnt` and `owr_oen` (respect if/else-if priority:
the guard of a later branch must include the negation of earlier ones).

Also add 10–20 `cover property` statements for interesting reachable
scenarios (a reset cycle starts, a data cycle completes and `irq_sts` rises,
overdrive mode entered, `owr_oen` falls, `bus_irq` asserts, `cdr_n` written).
Keep covers short and obviously reachable.

Rules:
- Only assert things that are actually true of the RTL. Re-derive each one
  from the code; think about reset (`default disable iff (rst)`) and about the
  first cycle after reset (`$past` of a reset cycle). Prefer
  `|=>` with antecedent on current values over raw `$past` in the consequent
  where it is cleaner.
- No `assume` properties (inputs are unconstrained — the design must work for
  any bus activity).
- Every assertion and cover gets a unique label.

## Run and iterate (required)

Run JasperGold yourself:

```bash
cd /var/home/brg8ve/.local/src/thesis/experiments/2026_11_10_rsi && jg -no_gui -tcl ./sockit_owm.tcl 2>&1 | tail -80
```

It writes a timestamped json under `metrics/`. Check it with:

```bash
python3 -c "import json,glob;d=json.load(open(sorted(glob.glob('metrics/*.json'))[-1]));print(d['fpv']['summary'])"
```

Also look at `jgproject/` logs or the jg stdout for compile errors and for the
names of failing (cex) / undetermined asserts and unreachable covers. Fix
compile errors first. For each failing assertion, re-read the RTL and correct
it (or delete it if you cannot make it correct). Repeat until there are zero
compile errors, zero cex, and zero unreachable covers. Run at most ~6 times.

Finish with a short summary: number of asserts proven/total and covers covered/total.
