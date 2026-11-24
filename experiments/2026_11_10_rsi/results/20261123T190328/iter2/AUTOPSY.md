# Iteration 2 autopsy

| run | proven | CEX (distinct asserts) | undetermined | vacuous | formal (COI) |
|---|---|---|---|---|---|
| run1 | 30/60 (46 user asserts; JG adds `:safety_in_liveness` children) | 16 | 0 | 0 | 298/299 |
| run2 | 35/35 | 0 | 0 | 2 | 298/299 |

The iteration-2 change worked for what it targeted:
- No run wrote an assertion it expected to fail. Both reports list the
  doc/RTL discrepancies as findings and add "I did not write assertions that
  fail on the RTL".
- Neither run asserts values that depend on the undriven select register.
  run2: "The checker does not assert anything about read data or the owr_e
  level".
- There were no blackbox warnings.

## run1

### F1. a_cyc_{w0,w1,rst,idl}_{n,o}, a_drv_{w0,w1,rst,idl}_{n,o}, a_div_first_n, a_div_next_n (16 CEX): input restrictions written into the consequent

- **What happened**: every one of these has the form
  `start |=> ((state && !bus_wen) throughout pls[->N]) ##1 end`, or
  `start |=> ((!bus_wen && !pls)[*CDR_N]) ##1 pls`. A bus write during the
  cycle is a legal input. It makes `!bus_wen` false inside the consequent, so
  the assertion fails instead of being excused. The unbounded `pls[->N]` also
  makes each one a liveness property: JG adds a `:safety_in_liveness`
  child, and that child fails too. These 16 asserts account for all 30
  failing properties.
- **Generator's reasoning**: the section header says the intent: "A cycle
  lasts exactly the number of base periods given in Table 12: the pulse that
  completes the count clears owr_cyc, and no bus write may interrupt it." It
  meant "assuming no bus write interrupts it". It encoded that as a
  requirement on the environment, inside the consequent.
- **Root cause**: wrong SVA semantics plus overlooked environment freedom.
  The prompt says inputs are unconstrained. It does not say that a condition
  on inputs which the property relies on belongs in the antecedent (or in a
  `disable iff`), never in the consequent. It also does not warn against
  unbounded repetition, which makes a property one that is never finished
  checking.
- **Prompt-level fix**: add a rule. A condition that the property *relies
  on* (no interrupting write, no reset) goes into the antecedent, for example
  `start ##1 (!wr)[*N] |-> ...`, or `start ##1 !wr[*0:$] ##1 ...`
  restructured as a bounded antecedent. Conditions in the consequent are
  claims about the design, and they can only mention inputs the design
  controls. Use bounded windows (`##[0:N]`, `[*N]`) instead of open-ended
  `[->N]`, `s_eventually` or `##[1:$]`, unless the bound is genuinely
  unknown.

## run2

### F2. a_rst_cdr, a_rst_ctl (vacuous): recurring from iteration 1 (F5)

- **What happened**: `disable iff (1'b0) rst |=> ...`. Reset is never active
  after initialisation, so the precondition is unreachable.
- **Generator's reasoning**: trace line 462: "The check is written as rst
  |=> ... with the default disable iff ... would hide them". This is the same
  belief that run1 held in iteration 1.
- **Root cause**: a prompt instruction misled it, for the second time. The
  reset bullet ("put reset-value checks in a form that does not depend on
  `$past` across reset, or check them only where they are observable")
  steers generators away from the working `$past(rst)` form and towards
  "trigger on rst".
- **Prompt-level fix**: replace that sentence with an explicit form. Check
  reset values in the first cycle after reset is released
  (`$past(<reset active>) |-> ...`), and never as an assertion triggered by
  the reset being active, which is never exercised.

## Missed formal coverage

Both runs: only the `bus_wen_pwr_sel` toggle, which has no reader. Same as
iteration 1.

## Ranked root causes

1. **Input restrictions in the consequent, plus unbounded repetition.**
   run1: 16 asserts (30 failing properties). New this iteration; the larger,
   more ambitious timing section in run1 exposed it. Prompt silent.
2. **Reset-value checks triggered on active reset.** run2: 2 vacuous.
   Recurring (iter1 run1: 3). The prompt wording misleads.

Recurring patterns: reset vacuity has now appeared in 3 of 4 runs. The
iteration-1 causes (bug hunting, blackboxed arithmetic, free select
register) did not recur. The divider-as-reset-value cause (iter1 F7) did
not recur either; run1 restricted it explicitly (`cdr_n == CDR_N` in the
antecedent).
