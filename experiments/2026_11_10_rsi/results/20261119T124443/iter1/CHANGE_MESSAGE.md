Create a generic doc+RTL SVA generator prompt with a truth checklist

Problem
  Iteration 1: there is no prompt yet. The generator (a haiku agent) needs
  a self-contained, design-agnostic task description that makes it write a
  bound SVA checker for an arbitrary RTL design from its documentation and
  RTL, without knowing it is being evaluated.

  Design of the initial prompt:
  - Workspace description and fixed deliverables (`sva/<top>_sva.sv` with
    checker + bind, `<top>_sva.f`), with `<top>` derived from the filelist
    name, so no path is hard-coded.
  - A procedure: read the documentation completely (PDFs page range by page
    range), read the RTL completely (reset values, update conditions,
    priority, elaborated generate branches), read the setup tcl for
    clock/reset, plan, write, syntax-check, self-review.
  - "What to write": two sources/two levels (documentation -> high-level,
    RTL -> designer-intent), an explicit no-transcription rule with the two
    canonical examples, a completeness instruction (every register, output,
    branch, data path, set/clear path, priority case), no cover statements,
    a source comment per assertion.
  - "Making sure each assertion is true": a checklist of the usual classes
    of false/vacuous assertions (unconstrained inputs and interfering bus
    accesses, assumptions, unreset/undriven registers, reset handling,
    `|->`/`|=>`/`$past` alignment, widths, parameters, reachable antecedents,
    short temporal depth, priority between simultaneous updates).
  - A checker skeleton with default clocking / disable iff and a `.*` bind.
  - Traceability: asks for plain-text reasoning, especially when an
    assertion is weakened/rewritten/deleted, and a source comment per
    assertion.

Change
  - New file: the whole prompt as described above.

Expected effect
  Baseline. Expect most asserts proven; likely failures are timing
  misalignment and interference from unconstrained bus writes. Formal
  coverage is expected to be moderate (counter/timing logic is the hardest
  to specify without transcription).

Constraint check
  Generic: contains no module, signal, parameter or file names or
    documentation facts from any design; examples use placeholders.
  Evaluation-blind: no mention of proofs, scores, coverage measurement or
    any tool run other than `check_syntax.sh`.
  Transcription: explicitly forbidden with the two canonical examples and
    an alternative (state intent / end-to-end effects).

Result (fill in after step 7)
  Mixed. run1: proven 60/67 (89.6 %), non-vacuous 100 %, formal 59.6 % of
  achievable (a lower bound: coverage measurement was cut off by the time
  limit). run2 wrote nothing: the "only command is ./check_syntax.sh" wording
  stopped it from listing doc/. 4 of 7 CEX were assertions the generator
  knowingly wrote against the RTL.
