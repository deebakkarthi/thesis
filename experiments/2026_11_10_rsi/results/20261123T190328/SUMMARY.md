# Summary: run 20261123T190328

One tuning design (sockit_owm), K = 2 runs per iteration, 5 iterations,
haiku generator. Each cell is mean / min.

| iter | proven % | non-vacuous % | formal (COI) % | CEX | undetermined | change subject |
|---|---|---|---|---|---|---|
| 1 | 69.5 / 66.7 | 95.5 / 90.9 | 99.7 / 99.7 | 15 | 4 | Create a generic SVA generator prompt with truth, reach and scope rules |
| 2 | 75.0 / 50.0 | 97.1 / 94.3 | 99.7 / 99.7 | 16* | 0 | Require assertions to hold on the RTL as is, and treat checker warnings as errors |
| 3 | 88.0 / 77.6 | 100 / 100 | 99.7 / 99.7 | 0 | 18 | Keep environment conditions in antecedents and give reset checks a fixed form |
| 4 | 94.6 / 89.3 | 100 / 100 | 99.7 / 99.7 | 0 | 6 | Check long durations with a step-wise event counter, not unrolled windows |
| 5 | 95.4 / 92.9 | 100 / 100 | 99.7 / 99.7 | 4 | 1 | Count repeated sub-periods and tie auxiliary counters to design state |

\* Distinct asserts. JG's `:safety_in_liveness` children double this to 30
failing properties.

Fully clean runs (100% proven and 100% non-vacuous): iter2 run2 (apart
from 2 vacuous reset checks), and iter4 run1 (51/51).

Failure classes eliminated, in order:
- bug hunting (known-false asserts);
- asserting values derived from undriven/initial-only registers;
- blackboxed checker arithmetic;
- reset-triggered vacuous checks;
- input restrictions in consequents and unbounded liveness forms;
- long unrolled timing windows;
- flat long clock counters.

Remaining failures in iteration 5 are local:
- a same-cycle bus write not excluded from 3 release checks (confirmed by a
  scratch rerun);
- one sample-point mapping error, not analysed;
- one transcribed divider step that stays undetermined.

The early-stop criterion (min 100% proven and non-vacuous for two
consecutive iterations) was not reached.

## Limitations

- **The coverage metric is saturated.** Mid-iteration 1 the user switched
  `check_cov` from mutation to COI coverage, and cut the prove and coverage
  limits to 30 s per property and 2 min in total, for faster runs. Every
  run reached 298/299, even iter1 with roughly a third of its asserts false.
  The one missed item is a write-enable toggle that has no reader for
  OWN=1. Metric 3 therefore provided no signal, and coverage completeness
  was never optimised.
- **`metrics.py` misreports undetermined precondition covers as "user
  covers".** iter4 run2 shows "covered 0/3" although the checker has no
  cover statement.
- **Undetermined is partly an artifact of the short time limits.** Some of
  the iter3 and iter4 undetermined asserts might prove with longer limits.
  The prompt changes still made them provable within the limits, which is
  the more robust outcome.
- **Single design, no held-out set.** "Generic" was checked only by
  reading, not by measurement on an unseen design.
- **Transcription is still around 15–25%** in the sampled asserts. It is
  mostly in counter and divider step properties, and the prompt never
  targeted it specifically.
- **Documentation/RTL conflicts are not asserted.** Since iteration 2, the
  generators report them and do not assert the documented behaviour:
  - a cyc=0 write drives the line or aborts a cycle;
  - idle overdrive ticks set irq and dat;
  - the select register is undriven for OWN=1.

  This keeps proven at 100% but leaves those documented behaviours
  unspecified.
- **Scratch kept.** The iter1 scratch experiment (`scratch/run2_nocdr`)
  was kept for reference.

## Suggested next steps

- Return to a mutation-based coverage measure, perhaps restricted to some
  mutation types to keep runs fast, so that metric 3 can discriminate.
- Add the same-cycle-write self-review step (iter5 F1) and a
  counter-transcription example (iter5 F3) as iteration 6.
