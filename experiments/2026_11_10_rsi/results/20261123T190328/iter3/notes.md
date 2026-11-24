# Iteration 3 notes

## Metrics

Proven: 88.0% mean / 77.6% min. Non-vacuous: 100 / 100. COI formal:
99.7 / 99.7, still saturated. There is zero CEX in either run.

## Failure classes

- Undetermined long-window timing asserts (run1, 17): a_n_*_busy/end/low/rel,
  a_n_w0_irq_en, a_n_w0_irq_rd, a_o_rst_*.
- Undetermined RTL transcription (run2, 1): a_div_step.

## Transcription estimate

Sample: 20 asserts per run.

- run1: about 2/20. Its asserts are almost all doc-level start-to-end
  windows and write-to-read relations.
- run2: about 6/20 (30%), up from about 3/20 in iteration 2. Examples:
  - `a_div_wr: bus_wen |=> div == '0`, which restates `if (bus_wen) div <= 0`;
  - `a_div_step`, which restates `div <= div + owr_cyc`;
  - `a_cyc_end: endc & ~w0 |=> ~owr_cyc`, which restates the `owr_cyc` clear.

  41 of its 58 source comments cite the RTL. The "describe what the RTL does"
  sentence from iteration 2 may be nudging RTL-heavy generators toward
  restating code.

## Documentation vs RTL

Split: run1 is mostly doc-level, with 10 of 76 asserts citing the RTL. run2
leans on the RTL, with 41 of 58.

Both runs report the same conflicts as before and assert none of them:
- a cyc=0 write drives the line;
- idle overdrive pulses set irq and dat;
- the select register is undriven for OWN=1.

run2 adds one: the datasheet says the line cannot run cycles while powered,
and the RTL does not implement this.

## Compliance

No covers and no assumes. Timing properties come only from documented
durations.

## Did the change have the expected effect?

Yes:
- Consequent-side input restrictions and liveness forms are gone (16 to 0).
- Reset vacuity is gone (2 to 0), and non-vacuous is 100/100.
- Proven rose from 75.0/50.0 to 88.0/77.6.

The risk named in the change message, that long bounded antecedents would
not resolve, materialised in run1 (17 undetermined). That is the target
for iteration 4.
