# Iteration 3 autopsy

| run | proven | CEX | undetermined | vacuous | formal (COI) |
|---|---|---|---|---|---|
| run1 | 59/76 | 0 | 17 | 0 | 298/299 |
| run2 | 57/58 | 0 | 1 | 0 | 298/299 |

The iteration-3 change removed both targeted failures:
- There are no consequent-side input restrictions and no unbounded
  repetition. JG created no `:safety_in_liveness` children.
- Reset checks now use `$past(rst)`, and both runs are 100% non-vacuous.

This is the first iteration with zero CEX in both runs.

## run1

### F1. 17 undetermined timing asserts with long unrolled windows

- **Affected asserts**: a_n_{w0,w1,rst,idl}_{busy,end,low,rel},
  a_n_w0_irq_{en,rd} and a_o_rst_{busy,end,low,rel}.
- **What happened**: every one of them has the form
  `(go && ok) ##1 (!bus_wen)[*K] |-> / |=> ...`. K is the cycle length in
  clocks: 65, 960 and 1000 in normal mode, and 96 for an overdrive reset.
  Proving them needs reasoning across K consecutive cycles, and none
  finishes within the 30 s limit. The short windows did prove: the 8-clock
  overdrive write and 1-base-period release asserts, and also
  a_n_w0_irq_dis.
- **Generator's reasoning**: "cycle-timing assertions need `cdr_n==CDR_N`
  / `cdr_o==CDR_O` in the antecedent and no bus writes in the window." It
  computed K as "LN_RST * PN // 960".
- **Root cause**: a prompt instruction misled it. The iteration-3 rule gave
  `start ##1 (!write)[*N] |-> done` as *the* example, and the generator
  copied that form for every duration, including ones of hundreds of cycles.
  The prompt never says that such long fixed windows are impractical.
  run2 had the same prompt but used a different form, a pulse counter
  latched from the start write plus per-step relations
  (`pls & owr_cyc & ~w0 |-> ((pc == exp_n-1) == (cnt == 0))`), and all of
  those proved.
- **Prompt-level fix**: when a duration is longer than a few tens of
  cycles, do not unroll it as a repetition. Add a small auxiliary counter
  of the relevant events, reset or loaded by the start event, and assert
  step-wise relations between that counter and the design state that hold
  in every cycle. Keep the short `[*N]` example only for short windows.

## run2

### F2. a_div_step (undetermined)

- **What happened**: `owr_cyc & ~bus_wen & ~pls |=> div == $past(div) + 1`.
  It does not resolve within 30 s. `div` is 16 bits wide, and the property
  relies on `div` never exceeding the ratio, which no other assertion
  states.
- **Generator's reasoning**: source comment "RTL `div <= div + owr_cyc`".
- **Root cause**: it is also a transcription of the RTL update (constraint
  3), so the fix is not to make it provable but to not write it. The prompt
  already forbids this; the generator ignored the rule. See notes for the
  transcription trend.
- **Prompt-level fix**: none specific. The no-transcription rule could be
  reinforced (see rank 2).

## Missed formal coverage

Both runs: only the `bus_wen_pwr_sel` toggle (no reader), unchanged.

## Ranked root causes

1. **Long unrolled timing windows** (run1: 17 undetermined, 22% of its
   asserts). The cause is the example in the iteration-3 prompt.
2. **Transcription creeping back** (run2: about 6/20 sampled,
   1 undetermined). This is a constraint-3 concern rather than a metric
   concern.

Recurring patterns:
- Reset vacuity is fixed; it was seen in 3 of 4 earlier runs and 0 of 2
  now.
- The doc/RTL conflict handling is stable: both runs report the cyc=0 line
  drive, the idle overdrive pulses and the undriven select, and assert none
  of them.
- Assertion counts grew: 33/29, then 46/35, now 76/58.
