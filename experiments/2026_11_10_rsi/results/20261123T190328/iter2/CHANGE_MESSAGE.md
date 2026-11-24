Require assertions to hold on the RTL as is, and treat checker warnings as errors

Problem
  Iteration 1: proven 69.5% mean / 66.7% min. Two root causes from
  iter1/AUTOPSY.md account for 13 of the 15 CEX.

  (1) Bug hunting, ranks 1 and 3 (run1, 7 CEX). The prompt said the
  assertions should be such "that a bug anywhere in the logic would
  violate at least one of them". run1 took that as a mandate to write
  assertions it expected to fail: "Expected to FAIL on the current RTL ...
  these are the bugs the checker is meant to catch" (a_cnt_idle_hold,
  a_irq_only_end, a_dat_hold_idle, a_no_drive_cyc0, a_e_mirror_oen,
  a_sample_slot, a_sample_presence). Three of these rest on a register
  that only an `initial` block sets: "depends on owr_sel, which is never
  written ... so this is expected to fail". The existing rule ("never
  assert the value of such a register") was read as covering the register
  itself, not signals computed from it.

  (2) Ignored warnings, rank 2 (run2, 6 CEX). The syntax check printed
  "multiplication operator ... automatically blackboxed" three times, and
  run2 summarised: "Only warnings are width truncations and the RTL's own
  owr_sel warning". Its cycle-length functions therefore returned
  arbitrary values (dlen=0 or 1 for the same write in two CEX traces).
  The prompt only said "fix every error until it prints SYNTAX OK".

Change
  - Intro: state that the generator is not looking for bugs, and that
    every assertion must hold on the RTL as it is. This addresses (1) at
    the framing level.
  - Deliverables/syntax check: read every warning that points into the
    checker. Treat blackboxed, removed or undriven logic as an error,
    because its value is arbitrary. Avoid `*`, `/` and `%` with
    non-constant operands in auxiliary logic. This addresses (2).
  - Two sources: RTL-level properties describe what the RTL does. Never
    keep an assertion because you expect it to fail; delete or correct it
    and say so. This addresses (1) for RTL-level properties. The
    "documentation wins" sentence is unchanged.
  - Truth/unassigned registers: `initial`-only registers count as
    unassigned, and the rule now covers every signal computed from such a
    register. This addresses the owr_sel part of (1).
  - "Specify the whole design": replace "a bug anywhere ... would violate"
    with "every behaviour the design exhibits is pinned down". This removes
    the wording that invited bug hunting.

Expected effect
  Proven % should rise sharply. No known-false RTL-level asserts, and no
  blackboxed arithmetic. Documentation-derived asserts that the RTL
  genuinely contradicts may still fail; they count as doc/RTL conflicts.
  Risk: the generator may become over-cautious and drop documented
  behaviour wherever it suspects the RTL differs. Watch the assertion
  count and whether doc-level properties disappear. COI coverage is
  saturated and is not expected to move.

Constraint check
  Generic: no design names, signals or doc facts. `initial` blocks and
  `*` are generic language features.
  Evaluation: mentions only the syntax check's warnings, which the
  generator already sees. No proofs, metrics or coverage.
  Transcription: unchanged rule. "Describe what the RTL does" is still
  bounded by the no-transcription section.

Result (fill in after step 7)
  Targets fixed: no known-false, free-register or blackboxed asserts; run2
  35/35 proven. Proven 75.0 mean / 50.0 min. The min fell because of a new
  SVA-form error (input restrictions in consequents) in run1.
