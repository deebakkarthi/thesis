Allow listing the workspace; forbid RTL assertions believed to be false

Problem
  Two prompt-caused root causes from iter1/AUTOPSY.md, ranked 1 and 2:

  (1) F1, blocked run. run2 produced no checker (0 asserts, 0 formal
  coverage). The prompt said "The only command you may run is
  `./check_syntax.sh` … You may read any file in the workspace", but gave
  no way to discover the documentation's file name, which does not match
  `<top>`. The generator followed the rule literally: "I'll use the Read
  tool for the rest of the workspace, since TASK.md allows only
  `check_syntax.sh` as a shell command", guessed ~15 file names and stopped:
  "BLOCKED: I could not finish the task because I cannot locate the
  documentation in `doc/`." run1 ignored the rule, used `ls`, and finished.

  (2) F5–F8, knowingly false RTL-intent assertions. 4 of run1's 7 CEX
  (`a_idle_cnt_hold`, `a_idle_no_pulse`, `a_irq_rise_at_end`,
  `a_idle_line_off`) were predicted by the generator before any check:
  "Several of these will fail on the RTL … I'll report them rather than
  weaken the assertions", "Predicted failures (designed to fail, per the
  task's rule to follow the doc where doc and RTL disagree, or to catch
  designer-intent violations)". It applied the documentation-wins rule to
  its own invented "designer intent", which no documentation statement
  supports. proven = 89.6 % (run1). Without these four it would have been
  63/67 = 94 %.

Change
  - Hunk 1 (fixes 1): replace "the only command you may run" with an
    explicit permission for read-only inspection (list directories,
    read/search files), an instruction to start by listing `doc/` and
    `rtl/` because documentation file names are unknown, and keep
    `./check_syntax.sh` as the only program that may be run besides that.
  - Hunk 2 (fixes 2): new paragraph "Only write assertions you believe
    hold": the documentation-wins rule covers only explicit documentation
    statements; RTL-level properties must describe what the RTL does; never
    write an assertion expected to fail or invent intent; report suspected
    bugs in text and assert the actual behaviour or nothing.

  The two edits address unrelated root causes. They are combined because
  the iteration budget is small (5) and hunk 1 is a pure enabling fix that
  cannot interact with assertion quality, apart from giving the second run
  a chance to produce output at all.

Expected effect
  - Both runs produce a checker (runs ok 2/2).
  - proven % rises (the four knowingly false RTL-intent CEX disappear).
    Documentation-sourced CEX (over-read documentation, genuine conflicts)
    may remain.
  - Risk: the generator may drop some RTL-level properties it is unsure
    about, slightly lowering formal coverage.

Constraint check
  Generic: no design names, signals, values or documentation facts; the
    rule is about a class of mistake (asserting suspected bugs).
  Evaluation-blind: mentions only file inspection and `check_syntax.sh`;
    nothing about proofs, metrics or measurement.
  Transcription: unchanged; "assert what the RTL really does" sits next to
    the existing no-transcription rule, which still applies.

Result (fill in after step 7)
  TBD
