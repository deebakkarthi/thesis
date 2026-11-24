Keep environment conditions in antecedents and give reset checks a fixed form

Problem
  Iteration 2: proven 75.0% mean / 50.0% min, non-vacuous 97.1 / 94.3.
  The two root causes in iter2/AUTOPSY.md:

  (1) Rank 1: input restrictions in the consequent, plus unbounded
  repetition (run1, 16 asserts, 30 failing properties). The section
  comment says "the pulse that completes the count clears owr_cyc, and
  no bus write may interrupt it". It was encoded as
  `start |=> ((owr_cyc && !bus_wen) throughout pls[->N]) ##1 !owr_cyc`,
  so any legal bus write mid-cycle violates the assertion. The open-ended
  `[->N]` also turns each one into a liveness property.

  (2) Rank 2, recurring: reset checks triggered on active reset (run2:
  a_rst_cdr, a_rst_ctl vacuous; iter1 run1: 3 vacuous). The trace says
  "written as rst |=> ... with the default disable iff ... would hide
  them". The prompt's reset bullet ("a form that does not depend on
  `$past` across reset") steers generators to exactly this form.

Change
  - Truth section: new bullet "Conditions you rely on go in the
    antecedent". The consequent may only require what the design
    controls, and environment conditions such as "no new write meanwhile"
    belong on the left. This addresses (1).
  - Truth section: new bullet "Bounded time". Prefer `##N`, `[*N]` and
    bounded ranges over open-ended `[->N]`, `s_eventually` and `##[1:$]`.
    This addresses the liveness half of (1).
  - Reset bullet: replace the vague sentence with the explicit
    `$past(<reset active>) |-> ...` form, and state that reset-triggered
    assertions are never exercised. This addresses (2).

Expected effect
  run1-style timing properties should become provable or be restricted
  correctly, so proven % should rise towards 100. Non-vacuous should reach
  100 with no reset vacuity. Risk: long bounded antecedents
  (`(!write)[*N]` with N in the hundreds) may be slow to prove or remain
  undetermined within the time limits.

Constraint check
  Generic: SVA semantics only, no design content.
  Evaluation: "never exercised" is phrased as simulation and engineering
  semantics, with no mention of tools or metrics.
  Transcription: unaffected.

Result (fill in after step 7)
  Both targets fixed: 0 CEX, 0 liveness children, 0 vacuous (100/100).
  Proven 88.0 mean / 77.6 min. The named risk materialised: 17 long-window
  asserts in run1 remain undetermined.
