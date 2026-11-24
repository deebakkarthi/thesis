Check long durations with a step-wise event counter, not unrolled windows

Problem
  Iteration 3: proven 88.0% mean / 77.6% min, non-vacuous 100/100, and
  0 CEX. The top root cause in iter3/AUTOPSY.md is long unrolled timing
  windows: 17 undetermined asserts in run1, 22% of its asserts. The
  iteration-3 rule gave `start ##1 (!write)[*N] |-> done` as its only
  example, and run1 used it for every duration, for example
  `(go_n_rst && ok_n) ##1 (!bus_wen)[*K_N_RST] |=> ...` with
  "K_N_RST = LN_RST * PN // 960". Windows of 65 to 1000 cycles never
  resolve. run2 had the same prompt but used a pulse counter with per-cycle
  relations, and all of its timing asserts held.

Change
  - Antecedent rule: drop the `[*N]` example from it. The environment
    condition can now also live in the auxiliary logic that defines when
    the property applies (for example a tracker that stops on an
    interrupting write).
  - "Bounded time" becomes "Bounded time, checked step by step". Fixed
    windows are fine for short spans (up to a few tens of cycles). For
    longer ones, use a small auxiliary event counter started by the start
    event and stopped by interruptions, and assert per-cycle relations
    between it and the design state. Two generic examples are given: busy
    while fewer than N ticks have elapsed, and end/status at the N-th tick.

Expected effect
  The undetermined count should fall towards 0, and proven % towards 100
  in both runs. Risk: auxiliary counters bring back iteration-1 mistakes,
  such as a wide free-running counter or using a reset-value parameter
  instead of the programmable value. The earlier rules on arithmetic and
  on environment freedom should limit this.

Constraint check
  Generic: no design content; "ticks, transfers, clock cycles" are
  generic.
  Evaluation: "impractical to check" is engineering language. No tools,
  proofs or metrics are named.
  Transcription: the counter must count documented events and durations,
  so it does not restate the RTL counter.

Result (fill in after step 7)
  Undetermined 18 -> 6; proven 94.6 mean / 89.3 min; run1 100/100 clean.
  run2 used a flat 1000-clock counter and its 960/1000-cycle asserts stay
  undetermined.
