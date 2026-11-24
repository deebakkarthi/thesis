# Iteration 5 autopsy

| run | proven | CEX | undetermined | vacuous | formal (COI) |
|---|---|---|---|---|---|
| run1 | 49/50 | 0 | 1 | 0 | 298/299 |
| run2 | 52/56 | 4 | 0 | 0 | 298/299 |

The iteration-5 change hit its target. Both runs count base-period ticks,
relate the tick counter to the design's cycle counter in every cycle
(run1: "cnt + tk = t_len-1"; run2: `cnt + tk_cnt == len-1`), and every
long-duration property proved:
- normal reset 960 clocks;
- idle 1000 clocks;
- overdrive reset.

There were 6 long-duration undetermined asserts in iteration 4, and 0 now.

## run2

### F1. a_wr1_release, a_wr0_release, a_rst_release (CEX): same-cycle control write not excluded

- **What happened**: `owr_cyc && ... && pls && tk_cnt == tk_X |=> !owr_oen`.
  In the RTL a control write has priority over the tick-driven release and
  reloads `owr_oen`. The antecedent does not exclude a write in the same
  cycle.
- **Scratch experiment**: adding `!bus_wen &&` to these three antecedents
  makes all three prove (scratch rerun: 55/56 proven).
- **Generator's reasoning**: the comment says "Holds by the reset release
  branch". It looked only at the tick branch of the `owr_oen` if-chain, not
  at the write branch above it.
- **Root cause**: generator ignored a prompt rule. The rule is:
  "**Same-cycle priority.** When two events can happen in the same cycle
  (for example a software write and an internal end-of-operation), decide
  from the RTL which one wins and make your assertion account for both."
  run2 applied it to its irq properties ("read clears unless a write or end
  tick wins") but not to the line-release properties.
- **Prompt-level fix**: possibly a self-review step, "for every assertion
  triggered by an internal event, check what happens if a bus write arrives
  in the same cycle". This is not applied, because this was the last
  iteration.

### F2. a_smp_window (CEX, 135 cycles): unresolved

- **What happened**: `owr_cyc && pls && !smp_pt |=> $stable(owr_smp)`. It
  still fails with `!bus_wen` added, on a 135-cycle trace. `smp_pt` is the
  generator's tick-index version of the RTL's `cnt == t_rstp` /
  `cnt == t_bits` sample conditions. The trace was not dumped, so it is
  unknown which case breaks the mapping between the tick index and the
  sample point (mode bit, divider value, or counter wrap).
- **Generator's reasoning**: "Holds because the sampling conditions are
  cnt == t_rstp / cnt == t_bits and tk_cnt tracks cnt in a running cycle."
- **Root cause**: misread the RTL (the exact case is not determined).
- **Prompt-level fix**: none identified.

## run1

### F3. a_div_cnt (undetermined): recurring RTL transcription

- **What happened**: `owr_cyc && !pls && !bus_wen |=> div == $past(div) + 1`.
  This is the same property as iteration 3's `a_div_step`, and it is
  undetermined again.
- **Root cause**: generator ignored the no-transcription rule. It is a
  restatement of `div <= pls ? 0 : div + owr_cyc`. The comment says so
  ("during a cycle without a tick or bus write, the divider counts up by one
  clock").
- **Prompt-level fix**: strengthen the transcription rule with a counter
  example. "Counter X increments by one" is a transcription when the RTL
  says exactly that; describe instead what the counter *achieves* (the tick
  period).

## Missed formal coverage

Only the `bus_wen_pwr_sel` toggle (no reader), unchanged.

## Ranked root causes

1. Same-cycle bus write not excluded from internal-event properties
   (run2: 3 CEX). The prompt rule exists; the generator applied it
   unevenly.
2. RTL transcription of counter steps (run1: 1 undetermined). This has
   recurred since iteration 3.
3. Sample-point mapping error (run2: 1 CEX), unresolved.

Recurring patterns:
- No CEX from bug hunting, free registers, blackboxed arithmetic, reset
  vacuity or consequent-side input conditions since iteration 3.
- Long-duration timing is now fixed.
- The remaining errors are local per-assertion mistakes, not systematic
  prompt gaps.
