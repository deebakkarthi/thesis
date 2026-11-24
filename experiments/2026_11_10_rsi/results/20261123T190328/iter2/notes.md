# Iteration 2 notes

## Metrics

Proven: 75.0% mean / 50.0% min. Non-vacuous: 97.1 / 94.3. COI formal:
99.7 / 99.7, still saturated.

- run2: 35/35 proven. Its only defect is 2 vacuous reset checks.
- run1: 16 of 46 user asserts fail, all with the same consequent-side
  `!bus_wen` pattern. The JG liveness children double the failing count, so
  the 30/60 understates its assert-level score, which is 30/46 = 65%.

## Failure classes

- Input restriction in the consequent, plus unbounded `[->N]` (run1):
  a_cyc_*, a_drv_*, a_div_first_n, a_div_next_n.
- Reset-triggered checks (run2): a_rst_cdr, a_rst_ctl.

## Transcription estimate

Sample: 20 per run.

- run1: about 3/20. Examples: `a_wr_ctl_rb` copies the read-mux bit layout,
  including `v[3] & ~(&v[2:0])`; the hold properties are phrased per
  register event. Most of its asserts are end-to-end (write -> read,
  start -> N pulses -> end).
- run2: about 3/20. Example: the irq clear "unless a pulse coincides"
  mirrors the RTL priority chain. The rest are doc-level.

## Documentation vs RTL

- Both runs report, without asserting them:
  - spurious idle interrupts in overdrive;
  - a cyc=0 write driving the line;
  - the undriven owr_sel.
- run1 adds that a cyc=0 write aborts a running cycle. run2 adds that the
  datasheet's CDR defaults (15/2) differ from the RTL's (4/0), and that
  the datasheet gives the dat reset value as "x".
- Since the iteration-2 change, the generators drop assertions in conflict
  areas instead of writing failing ones. This is allowed: the documented
  behaviour is reported rather than asserted. Watch whether this causes
  coverage loss once a finer coverage metric is used.

## Compliance

No user covers, and no assumes. Both runs write timing properties for
documented durations, in base-period pulses.

## Did the change have the expected effect?

Yes for its targets: no known-false asserts, no free-register asserts and
no blackboxed logic in either run, and run2 is fully proven. Proven % rose
only on average (69.5 -> 75.0) and the min fell (66.7 -> 50.0), because of
a new, unrelated SVA-form error in run1. That error is the target for
iteration 3.
