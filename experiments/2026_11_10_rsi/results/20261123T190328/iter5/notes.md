# Iteration 5 notes

## Metrics

| metric | mean | min |
|---|---|---|
| proven | 95.4% | 92.9% |
| non-vacuous | 100 | 100 |
| COI formal | 99.7 | 99.7 |

Neither run had a long-duration timing assertion left undetermined (6 in
iteration 4).

## Failure classes

- A same-cycle control write is not excluded (run2): a_wr1_release,
  a_wr0_release, a_rst_release. A scratch test confirms they prove once
  `!bus_wen` is added.
- The sample-point mapping fails (run2): a_smp_window. The CEX is 135
  cycles long and has not been analysed.
- A transcribed divider step is undetermined (run1): a_div_cnt.

## Transcription estimate

Sample: 20 asserts per run.

- run1, about 4/20. Examples:
  - `a_div_clr: pls |=> div == 0`
  - `a_div_cnt`
  - the cnt hold
- run2, about 5/20. Examples:
  - the divider "counts while running"
  - "counter reload and step"

The cross-counter invariant (`cnt + tk_cnt == len-1`) is not a
transcription. Rule (b) did not visibly raise transcription compared with
iterations 3 and 4.

## Documentation vs RTL

Both runs report the same conflicts and do not assert the documented side:

- a write with cyc=0 drives the line;
- idle overdrive ticks set irq and dat;
- owr_sel is undriven;
- (run2 only) the overdrive zero-time idle runs 96 ticks.

## Compliance

No user covers and no assumes.

## Did the change have the expected effect?

Yes for its target:

- Undetermined long-duration asserts went from 6 to 0.
- Proven went from 94.6/89.3 to 95.4/92.9.

The new failures are unrelated local errors (3 caused by same-cycle
priority, 1 by mapping).
