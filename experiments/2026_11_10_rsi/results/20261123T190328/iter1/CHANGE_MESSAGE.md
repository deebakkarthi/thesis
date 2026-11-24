Create a generic SVA generator prompt with truth, reach and scope rules

Problem
  Iteration 1: no prompt exists yet. The initial prompt has to make a small
  model write a bound SVA checker for an arbitrary RTL design plus its
  documentation, with assertions that are true, non-vacuous and that
  together specify all observable behaviour, without transcribing the RTL
  and without writing covers.

  Design of the initial prompt:
  - Workspace/deliverables section: describes rtl/, doc/ (with pdftotext
    for PDFs), the setup script as the source of clock/reset, and the two
    output files; the syntax check is the only tool.
  - "Two sources, two levels": documentation -> high-level properties,
    RTL -> designer-intent properties; documentation wins on conflict.
    Explicit no-transcription rule with the two canonical examples and a
    list of acceptable non-transcribing forms (end-to-end, invariants,
    hold/stability, sequencing, event semantics).
  - "Every assertion must be true": unconstrained inputs, unreset/unassigned
    registers are arbitrary, reset/$past alignment, default parameters,
    widths, same-cycle priority, |-> vs |=> timing, and a self-review step
    that tries to break each assertion.
  - "Every assertion must be meaningful": reachable antecedents, no
    tautologies.
  - "Specify the whole design": a checklist of outputs, registers,
    readable fields, counters, control bits, flags and data paths, to be
    listed before writing.
  - Coding rules: checker with ports named like design signals, bind with
    .*, default clocking/disable iff, labels, no covers, assumes only for
    documented usage rules.
  - Traceability: source+why comment per assertion; reasoning in plain
    text, especially when weakening or deleting.

Change
  - New file GENERATOR_PROMPT.md with the sections above.

Expected effect
  Baseline. Expect mostly proven assertions; likely failures are timing
  alignment around counters/pulses and asserting values of unreset
  registers. Formal coverage unknown.

Constraint check
  Generic: no design names, signals, parameters or doc facts.
  Evaluation: no mention of metrics, scores, coverage, proofs or tools
  beyond the syntax check.
  Transcription: explicitly forbidden, with examples and alternatives.

Result (fill in after step 7)
  proven 69.5% mean / 66.7% min, non-vacuous 95.5 / 90.9, COI formal 99.7 / 99.7.
  Failures came mainly from bug hunting (run1, 7 CEX) and a blackboxed
  multiplier the generator ignored (run2, 6 CEX), not from timing alignment.
