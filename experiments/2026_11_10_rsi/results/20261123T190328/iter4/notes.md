# Iteration 4 notes

## Metrics

Proven: 94.6% mean / 89.3% min. Non-vacuous: 100 / 100. COI formal:
99.7 / 99.7.

- run1: 51/51 proven, the first fully clean run.
- run2: 50/56 proven.

The early-stop criterion (100% for metrics 1 and 2 in the min over K, for
two consecutive iterations) is not met.

## Failure classes

- Undetermined, with a flat clock counter over 960 or 1000 cycles (run2):
  a_nr_busy, a_nr_end, a_ni_busy, a_ni_end, a_nr_oen_hi, a_nr_oen_rel.
- Metric artifact: 3 undetermined `:precondition` covers are shown as
  "user covers 0/3". No user covers exist.

## Transcription estimate

Sample: 20 asserts per run.

- run1: about 3/20. Examples:
  - `a_div_*` ("one tick every ratio+1 clocks") is phrased as behaviour, but
    a_div_reset restates `if (bus_wen) div <= 0`.
  - `a_cyc_end` ties to the end event, not to the RTL expression.
- run2: about 5/20. Examples: "cnt counts down by one on each tick (wraps)"
  and the cnt hold, which restate the RTL counter update.

## Documentation vs RTL

Both runs repeat the known conflicts and assert none of them:
- a cyc=0 write drives the line or aborts a cycle;
- idle overdrive ticks set irq;
- owr_sel is undriven.

run1 adds that the doc contradicts itself on overdrive idle: Table 12 gives
zero time, while Table 7 gives tDLY=96.

## Compliance

No user covers, though the metrics show 3; see above. No assumes.

## Did the change have the expected effect?

Partly:
- Undetermined fell from 17+1 to 0+6.
- Proven rose from 88.0/77.6 to 94.6/89.3.
- run1 fully adopted the step-wise form (tick counter plus sub-tick counter)
  and is clean.
- run2 used a counter but counted raw clocks over the whole duration, which
  is no easier to check than the unrolled window it replaced.
