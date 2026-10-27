# Agent Comparison: LTL vs SVA

## Method

- The 5 LTL runs (`artifacts/20261022T135819_ltl/sockit_owm.ltl_{1..5}`) were concatenated into one file (257 lines, 183 distinct).
- The 5 SVA runs (`artifacts/20261022T135822_sva/sockit_owm.sva_{1..5}`) were concatenated into another (391 lines, about 385 distinct).
- 5 independent Claude agents each got both files with the same prompt: concisely list the differences between them, ignoring repetition within a file, and treating each file as the set of distinct things it says. The agents didn't see each other's answers or the earlier text-similarity results.
- Their answers were merged by majority vote. A point is kept only if at least 3 of the 5 agents raised it; the count is shown in brackets.

## Differences (majority view)

### Only in SVA

- **Arithmetic and data values** [5/5]. SVA checks:
  - that `cnt` counts down: `cnt == $past(cnt) - 1`
  - that `div` counts up: `div == $past(div) + owr_cyc`
  - that `cnt` reloads from `t_idl` / `t_rst` / `t_bit` minus 1
  - that `cdr_n` / `cdr_o` load from `bus_wdt[15:0]` / `[31:16]`

  LTL can't express arithmetic: values become quoted atoms like `"cnt==0"`. So it only says a value holds, resets, or equals a hard-coded constant (`cnt==12/7/191/95/199`, `cdr_n==4`, `cdr_o==0`).
- **Timing values are defined** [5/5]. SVA defines every derived timing signal (`t_bit`, `t_bits`, `t_dat0`, `t_dat1`, `t_idl`, `t_rst`, `t_rsth`, `t_rstp`, `t_zero`) from the `T_*_N/O` parameters. LTL either hard-codes numbers (`cnt==96/48/12/7/2/1`) or uses atoms like `"cnt==t_dat0"` that it never defines.
- **Design parameters are covered** [5/5]. SVA has properties guarded on `OVD_E`, `CDR_E`, `BDW` (8 vs 32) and `OWN` (1 vs >1). It covers multi-wire `owr_sel`, `owr_pwr` and `bus_wen_pwr_sel`, plus `owr_e == owr_oen << owr_sel` and `$onehot0(owr_e)`. LTL assumes the default configuration only: one wire, 32-bit bus (`owr_e <-> owr_oen`, `"owr_i[0]"`).
- **Extra sanity checks** [5/5]. Examples: `bus_wen_ctl_sts |-> bus_wen`, `(bus_wen_ctl_sts || bus_wen_cdr_n) == bus_wen`, `bus_irq |-> irq_ena`, and that a control write and a divider write (`bus_wen_cdr_o`) never happen together. LTL only states that a control write and a `bus_wen_cdr_n` write never coincide.
- **What causes `owr_cyc` to fall** [4/5]. SVA states it: `$fell(owr_cyc) |-> $past(bus_wen_ctl_sts || (pls && cnt == t_zero))`. LTL has no matching property.

### Only in LTL

- **Liveness** [5/5]. LTL has "eventually" properties, for example:
  - `G((owr_cyc & G(!rst & !bus_wen)) -> F !owr_cyc)`
  - `... -> F irq_sts`
  - `G(owr_cyc -> F(irq_sts | bus_wen | rst))`

  These say a transfer eventually ends and raises the interrupt. SVA is all safety: no `s_eventually`, `until`, `##` delays or `[*]` repetition.
- **Small facts** [3/5 each]:
  - `!irq_ena -> !bus_irq`
  - a family of "stays low unless written" formulas, e.g. `(!owr_ovd & !bus_wen_ctl_sts) -> X !owr_ovd`

### Same idea, written differently

- **Operators** [5/5].
  - SVA uses `|->` (same cycle) and `|=>` (next cycle), with `$past`, `$stable`, `$rose`, `$fell`, and sometimes `$onehot0` / `$isunknown`.
  - LTL uses only `G`, `X`, `F`, `<->` and Boolean connectives. "Unchanged" becomes `p <-> X p`, and a rising edge becomes `!p & X p`.
- **Cause-of-change properties** [4/5]. SVA looks back: `$rose(owr_cyc) |-> $past(cause)`. LTL looks forward from the cause: `(!owr_cyc & X owr_cyc) -> cause`.
- **Level of detail** [5/5].
  - SVA writes each register update as one equation, e.g. `owr_cyc == $past(bus_wdt[3] & ~&bus_wdt[2:0])`, and reads registers back as a concatenation `{irq_ena, irq_sts, 1'b0, ...}`.
  - LTL splits the same update into separate set and clear formulas for each bit (`"bus_wdt[0]" -> X owr_dat` and `!"bus_wdt[0]" -> X !owr_dat`), and checks read-back one bit at a time (`"bus_rdt[0]" <-> owr_dat`, ...).
- **Reset** [5/5].
  - SVA switches checks off during reset with `disable iff (rst)`, checks reset values both in the same cycle (`rst |->`) and the next (`rst |=>`), and also covers the reset values of `owr_e`, `owr_p`, `owr_sel` and `bus_irq`.
  - LTL writes `!rst` (sometimes `X !rst`) into each condition by hand, and checks reset values only one cycle later with a single large `rst -> X(...)` formula.
  - LTL is also inconsistent: some formulas have no reset guard at all [3/5].

### Overall [3/5]

SVA is broader and mirrors the RTL closely, across all parameter settings. LTL is a flattened, bit-level, single-configuration version of the same control logic, and its one unique contribution is liveness.

## Raised by only 1–2 agents (left out)

- LTL writes the same address condition several different ways (`!bus_adr`, `"bus_adr==0"`, `"bus_adr[0]==0"`) [2/5]. The surface-level analysis in `text_similarities.md` measured this independently.
- SVA's real distinct content is only about 120–150 properties once the different spellings are merged (`cnt == 0` / `'0` / `'d0` / `t_zero`) [2/5].
- Both formats cover essentially the same core control and status register behaviour [2/5].
- SVA's same-cycle reset checks (`rst |->`) suggest an asynchronous reset [1/5].
- Some LTL formulas compare the next value with a current input (`X owr_dat <-> "bus_wdt[0]"`), which is only correct because LTL reads inputs at the earlier time point [1/5].

## Inputs

- `/private/tmp/claude-501/-Users-deebakkarthi--local-src-thesis-experiments-2026-10-20-ltl-vs-sva/19fc5c46-b3d2-49a3-8aa9-0e24e37884e4/scratchpad/all_ltl.txt`
- `/private/tmp/claude-501/-Users-deebakkarthi--local-src-thesis-experiments-2026-10-20-ltl-vs-sva/19fc5c46-b3d2-49a3-8aa9-0e24e37884e4/scratchpad/all_sva.txt`

Both can be rebuilt with:

```
cat artifacts/*_ltl/sockit_owm.ltl_{1..5} > all_ltl.txt
cat artifacts/*_sva/sockit_owm.sva_{1..5} > all_sva.txt
```

---

# Verification Engineer Preference

## Method

- 5 new independent Claude agents each got the RTL (`sockit_owm.v`) and the same two combined files (all LTL runs and all SVA runs).
- Each was asked to act as the verification engineer signing off this RTL: say which property set it would prefer and give a rationale, ignoring repetition within a file.
- The agents didn't see each other's answers or any earlier results.
- Their rationales were merged by majority vote. A point is kept only if at least 3 of the 5 agents raised it; the count is shown in brackets.

## Verdict: SVA as the sign-off base, plus LTL's liveness properties [5/5]

All 5 agents chose SVA. All 5 also said the SVA set should borrow the LTL set's liveness properties.

### Why SVA

1. **It checks the timing logic** [5/5]. SVA checks:
   - that `cnt` counts down: `cnt == TDW'($past(cnt) - 1)`
   - that `div` counts up: `div == CDW'($past(div) + $past(owr_cyc))`
   - the `cnt` load mux: `t_idl` / `t_rst` / `t_bit` minus 1
   - that writes to `cdr_n` / `cdr_o` are stored: `cdr_n == $past(bus_wdt[15:0])`

   LTL has none of these, so a bug in slot timing would pass the whole LTL set.
2. **It follows the design parameters** [5/5]. SVA is written in terms of `T_*`, `CDR_N` and `t_*`, and has checks guarded on `OWN`, `BDW`, `CDR_E` and `OVD_E`. LTL hard-codes default-build numbers (`"cnt==191"`, `"cnt==96"`, `"cdr_n==4"`, `owr_e <-> owr_oen`). Those numbers are correct, but they silently go stale if a parameter changes.
3. **It runs in standard tools as written** (JasperGold, VC Formal, SymbiYosys, simulators) [5/5]. LTL has no clock. Its quoted atoms, like `"div==(owr_ovd ? cdr_o : cdr_n)"` and `"bus_rdt==(cdr_o << 16 | cdr_n)"`, need a custom layer to map them to signals.
4. **Its reset handling is consistent** [5/5]. SVA uses `disable iff (rst)` throughout. LTL guards against reset in three different ways (`!rst`, `!rst & X !rst`, or not at all), which matters because this design resets asynchronously.
5. **It's easier to maintain** [4/5]. SVA properties have names. The LTL writes the same condition several ways (`!bus_adr` / `"bus_adr==0"` / `"bus_adr[0]==0"`).

### Where LTL is better: liveness [5/5]

`G((owr_cyc & G(!rst & !bus_wen)) -> F irq_sts)` and `... -> F !owr_cyc` say that a started cycle finishes. These are the only end-to-end properties in either set. All 5 agents would rewrite them into the SVA set (`s_eventually`, or a bounded `##[1:N]`).

### Correctness

- No agent found a property in either set that describes the RTL wrongly [5/5]. Several of them checked LTL's hard-coded numbers against the default parameters, and all were correct: loads of 199/191/12 (normal) and 95/95/7 (overdrive), release points 1/2, 12/7 and 96/48.
- The SVA set needs cleanup:
  - Same-cycle reset checks (`rst |-> reg == 0`) should become `rst |=>` [5/5]. They are fragile or redundant with an asynchronous reset.
  - Property names repeat once all five runs are put in one file, so they'd need renaming before it compiles [3/5]. That comes from combining the runs, not from any single run.

### Gaps in both sets

- No 1-wire protocol-level checks, such as how long the line is held low for reset and data slots, or where sampling happens relative to release [5/5].
- Both mostly restate the RTL line by line instead of checking what it should do [4/5].
- No `cover` properties, so there's no way to tell a real pass from a check that never triggered [4/5].
- **Both sets miss what looks like a real RTL bug** [3/5].
  - With the default `CDR_O = 0`, when an overdrive cycle has finished, `div` stays 0, so `pls = (div == cdr_o)` stays high on every clock.
  - `cnt` keeps counting down and wrapping. Each time it reaches 0, `irq_sts` is set again and `owr_dat` is overwritten with `owr_smp`.
  - Both sets restate this behaviour (`pls && cnt == 0 |=> irq_sts`), so both pass it. A check of intent such as `$rose(irq_sts) |-> $past(owr_cyc)` would catch it.
  - Reading the RTL confirms the code behaves this way (`sockit_owm.v:297-302`, `:353`, `:378`, `:393`). Whether it is a real bug or intended behaviour depends on the spec. It was not run in a simulator.

## Raised by only 1–2 agents (left out)

- A `CDR_E=0` sizing bug: `CDW = $clog2(CDR_N)` gives 2 bits, too narrow to hold `CDR_N = 4` [1/5].
- One SVA counter-decrement variant without a width cast would fail when `cnt` wraps from 0 to 255 [1/5].
- `owr_smp` hold checks need a guard against unknown values, because `owr_smp` has no reset [2/5].
- SVA's hold checks are more complete, e.g. `owr_oen` staying stable on a `pls` with no matching release point [2/5].
- `!owr_cyc |-> div == 0` is a useful invariant [1/5].
- LTL's `owr_cyc -> (F !owr_cyc | F bus_wen)` is too weak to keep, because the environment can satisfy it [1/5].
