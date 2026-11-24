# Iteration 4 autopsy

| run | proven | CEX | undetermined | vacuous | formal (COI) |
|---|---|---|---|---|---|
| run1 | 51/51 | 0 | 0 | 0 | 298/299 |
| run2 | 50/56 | 0 | 6 | 0 (3 preconditions undetermined) | 298/299 |

run1 is the first fully clean run of this optimisation: 100% proven and
100% non-vacuous.

Metric artifact: `metrics.py` reports run2 as "covered 0/3 (user covers)".
The checker contains no `cover` statement. The 3 are `:precondition` covers
of a_nr_end, a_ni_end and a_nr_oen_rel that came out *undetermined*.
`metrics.py` counts only covered and unreachable preconditions as
preconditions and labels the remainder "user covers". This is not a
compliance failure. It is recorded in SUMMARY limitations.

## run2

### F1. a_nr_busy, a_nr_end, a_ni_busy, a_ni_end, a_nr_oen_hi, a_nr_oen_rel (undetermined): one wide clock counter over the whole duration

- **What happened**: run2 followed the new rule's letter. It used an
  auxiliary counter and per-cycle relations, for example
  `(!bus_wen && k_nr && qc == 11'd960) |-> !owr_cyc`, with
  `qc <= bus_wen ? 0 : qc + 1`. But `qc` counts raw clocks since the last bus
  write, up to 960 and 1000. Each property is a single comparison against a
  far-away counter value. Nothing ties `qc` to the design's own state (its
  divider and cycle counter) at intermediate points. So the claim is still
  only checkable by walking all 960 or 1000 cycles.
  - The short windows with the same form proved: a_nb_busy and
    a_irq_quiet_nb at 64 clocks, and the overdrive ones at 8 and 96 clocks.
  - run1 split the duration instead. It used `ticks`, the number of divider
    ticks (at most 200), and `sub`, clocks since the last tick (at most 5).
    Its step properties `a_cyc_hold: (owr_cyc && !cyc_end && !wr_ctl) |=>
    owr_cyc` and `a_cyc_end: cyc_end && !wr_ctl |=> !owr_cyc` each look only
    one cycle ahead. All of them proved.
- **Generator's reasoning**: "Timing windows are counted in clocks since the
  last bus write (`qc`) ... Windows exclude bus writes, since writes restart
  the divider."
- **Root cause**: the prompt was silent on structure. The iteration-4 rule
  says "keep a small auxiliary counter ... assert relations between that
  counter and the design's state that hold in every cycle". Its examples
  ("while fewer than N ticks have elapsed, busy is high") do not say that:
  - when a duration is built from repeated sub-periods, the counter should
    count those sub-periods, with a sub-period length checked separately;
  - the counter should be related to the design's own state, so that each
    property is a one-step claim.
- **Prompt-level fix**: add those two points. Count the coarsest repeated
  event (a prescaler tick, a bit time, a beat) and check the length of one
  such period in a separate property. Also assert in every cycle how the
  auxiliary counter corresponds to the design's own progress state (its
  counter, its phase), so that every timing property is a one-step claim.

## run1

No failures.

## Missed formal coverage

Only the `bus_wen_pwr_sel` toggle (no reader), unchanged.

## Ranked root causes

1. **Monolithic clock counters for long durations** (run2: 6 undetermined,
   10.7% of its asserts). The prompt is under-specified; this is the third
   iteration of the long-timing theme (iter3: unrolled windows, 17;
   iter4: flat counter, 6).

Recurring patterns:
- Long-duration timing is the last open class. CEX have been at 0 for two
  iterations, and vacuity at 0 for two.
- Transcription in run2 is about 5/20 (`a_div_*` and cnt "counts down by one
  on each tick"), similar to iteration 3.
