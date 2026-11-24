Count repeated sub-periods and tie auxiliary counters to design state

Problem
  Iteration 4: proven 94.6% mean / 89.3% min, non-vacuous 100/100, and
  0 CEX. The only root cause in iter4/AUTOPSY.md is monolithic clock
  counters for long durations (run2, 6 undetermined). run2 followed the
  iteration-4 rule's letter, "Timing windows are counted in clocks since
  the last bus write (`qc`)". It then asserted
  `(!bus_wen && k_nr && qc == 11'd960) |-> !owr_cyc`. That is still a
  single 960-cycle claim. run1, under the same prompt, counted divider
  ticks (at most 200) and clocks within a tick (at most 5), and wrote
  one-step properties. All of them proved.

Change
  - "Bounded time, checked step by step": add two rules.
    (a) When a duration consists of repeated shorter periods, count the
    periods, not raw clocks, and check one period's length separately.
    (b) Assert in every cycle how the auxiliary counter corresponds to the
    design's own progress state, so that each timing property looks only
    one cycle ahead.
    Both rules describe the structure that made run1's timing section
    hold.

Expected effect
  The remaining long-duration asserts should become one-step claims, and
  proven % should approach 100 in both runs. Risk: rule (b) can invite
  near-transcriptions such as "my counter == design counter + k". It
  relates two state variables rather than restating an assignment, so it
  is acceptable, but the transcription sample should be watched.

Constraint check
  Generic: "prescaler tick, bit time, beat" are generic notions.
  Evaluation: nothing about tools, proofs or metrics.
  Transcription: the counter counts documented periods. The
  correspondence is an invariant, not a copied RTL statement.

Result (fill in after step 7)
  Long-duration undetermined 6 -> 0 (960/1000-clock checks proven in both
  runs). Proven 95.4 mean / 92.9 min, non-vacuous 100/100. Remaining: 3
  same-cycle-write CEX, 1 mapping CEX, 1 transcribed counter step.
