# Iteration 1 autopsy

Design: sockit_owm, K = 2.

| run | asserts | proven | CEX | vacuous | user covers | output |
|---|---|---|---|---|---|---|
| run1 | 67 | 60 | 7 | 0 (67/67 preconditions covered) | 0 | checker written |
| run2 | 0 | – | – | – | – | **no checker (blocked)** |

Formal-coverage results for run1: see the section "Missed formal coverage"
(filled in after the coverage evaluation finished; see notes.md for the
evaluation-infrastructure issue).

---

## F1. run2 wrote no checker (blocked on finding the documentation)

**What happened.** run2 read TASK.md, the tcl, the filelist and the RTL,
then tried to open guessed documentation file names in `doc/` and gave up:

> "BLOCKED: I could not finish the task because I cannot locate the
> documentation in `doc/`. … Tried about 15 guessed filenames in doc/
> (datasheet.pdf, sockit_owm.pdf, spec.pdf, manual.pdf, README.md, etc.).
> None exist. Reading doc/ as a directory returns EISDIR, and I am not
> allowed to run ls."

**Generator's reasoning.** Step 1 used `cat`/`ls` on the workspace root
(which already showed `doc/`, but not its contents); then, trace line 82:

> "I'll use the Read tool for the rest of the workspace, since TASK.md
> allows only `check_syntax.sh` as a shell command. I already ran a `cat`
> and an `ls` above to read the task file, which goes beyond that rule."

It then refused to list `doc/` and also refused to write an RTL-only
checker because "TASK.md requires reading the documentation before writing
any assertion".

**Root cause.** Prompt instruction misled it: *"The only command you may run
is `./check_syntax.sh` (from the workspace directory). You may read any file
in the workspace."* The prompt never says how to discover file names, and
the documentation file name is design-specific (it does not match `<top>`).
run1 ignored the rule (used `ls`) and succeeded; the obedient run failed.

**Prompt-level fix.** Explicitly allow read-only inspection of the
workspace (listing directories, reading files, searching files), and tell
the generator to start by listing `doc/` and `rtl/` to find every file.
Keep `check_syntax.sh` as the only program that compiles or analyses
anything.

---

## F2–F4. CEX on documentation-sourced assertions that the RTL does not implement

All three were written knowingly. Plan message (run1, after reading doc and
RTL):

> "Several of these will fail on the RTL. Those are the doc/RTL
> disagreements and the overdrive-idle issue, and I'll report them rather
> than weaken the assertions."

### F2. `a_doc_cyc0_no_action` (CEX, 3 cycles)

`owr_cyc && ctl_wr && !bus_wdt[3] |=> owr_cyc` — "doc 4.4 says cyc=0 means
'no action' on a write; RTL clears owr_cyc on any control write with cyc=0".
The CEX is a control write with `cyc=0` during a running cycle: the RTL
aborts the cycle.

- Reasoning: comment says "DOC/RTL DISAGREEMENT".
- Root cause: **documentation/RTL conflict** (Table 11: cyc write "0 – no
  action"). Arguably also an over-literal reading — section 4.1 says "on
  every write all controls must have the correct value", i.e. software is
  expected never to write cyc=0 during a cycle. Recorded as a conflict, not
  a prompt failure. Prompt-level fix: none required by constraint 3.

### F3. `a_doc_irq_wr_no_clear` (CEX, 4 cycles)

`irq_sts && ctl_wr && !end_pls |=> irq_sts`: "doc Table 10 marks irq as r/c
and says it is cleared by a register read, but RTL also clears it on a
control write".

- Root cause: **misread the documentation** (over-generalisation). The
  documentation says what clears the bit (a read); it does not say a write
  leaves it unchanged. The generator turned "X clears it" into "only X
  clears it" and asserted that negative. The prompt asks for "status flags
  (when they set, when they clear, what clears them)" and for "'never'
  statements" — but says nothing about not inventing exclusivity the
  documentation does not state.
- Prompt-level fix: "Assert only what the documentation states. 'X clears
  the flag' does not mean 'nothing else clears it'; write a 'nothing else
  changes it' property only from the RTL, after checking every assignment."

### F4. `g_own1.a_doc_pwr_no_cycle` (CEX, 3 cycles)

`owr_pwr[0] && ctl_wr && bus_wdt[4] && bus_wdt[3] && … |=> !owr_cyc`, from
doc 4.3 "While power to a line is enabled it is not possible to perform
1-wire cycles on the same line".

- Root cause: **misread the documentation** — the sentence is a usage
  restriction (the line is driven high, so a cycle cannot work
  electrically), not a statement that the hardware blocks the cycle. The
  generator treated a statement about how the environment/software must
  use the design as a guarantee the hardware enforces. Prompt silent on
  this distinction.
- Prompt-level fix: "Distinguish what the design guarantees from what the
  documentation asks of the user/software ('must', 'should', 'is not
  possible to', 'must not be written while…'). Rules for the user are not
  hardware behaviour; do not assert that the design enforces them."

---

## F5–F7. CEX on RTL-level "designer intent" assertions the generator believed were violated

### F5. `a_idle_cnt_hold`, F6. `a_idle_no_pulse`, F7. `a_irq_rise_at_end`

```
a_idle_cnt_hold:  !owr_cyc && !ctl_wr |=> $stable(cnt);
a_idle_no_pulse:  !owr_cyc |-> !pls;
a_irq_rise_at_end: $rose(irq_sts) |-> $past(cyc_end);
```

CEX (2–3 cycles): with the default divider ratio for overdrive = 0, the
divider compare is true every cycle once overdrive is selected, so the base
pulse fires and the counter keeps decrementing while no cycle is active;
when it reaches 0, `irq_sts` rises without an active cycle.

- Reasoning: the generator *predicted* these failures in its comments
  before any check: "DOC/RTL DISAGREEMENT (designer intent): with CDR_O=0
  (the RTL default) in overdrive mode the pulse is high on every clock, so
  the counter keeps running while no cycle is active." and in the final
  report: "Predicted failures (designed to fail, per the task's rule to
  follow the doc where doc and RTL disagree, or to catch designer-intent
  violations)".
- Root cause: **prompt instruction misled it** together with **generator
  ignored a prompt rule**. The rule "every assertion is true of the design
  for every legal input sequence" was overridden by the generator's reading
  of "When the documentation and the RTL disagree, the documentation is the
  reference: write the assertion as the documentation describes it" — it
  extended this to its *own guesses* of designer intent, which is not
  documentation. The documentation does not say the counter is frozen when
  idle. In effect it went bug-hunting. The prompt never says what to do
  with an RTL behaviour that looks like a bug but contradicts no
  documented statement.
- Prompt-level fix: "RTL-derived properties describe what the RTL actually
  does; never write an RTL-level assertion you believe the RTL violates.
  The documentation-wins rule applies only to behaviour the documentation
  states explicitly. If something looks like a bug but no documentation
  statement covers it, mention it in your text and assert only what the
  design does (or nothing)."

### F8. `a_idle_line_off` (CEX, 2 cycles)

`!owr_cyc |-> !owr_oen` — "DOC/RTL DISAGREEMENT (designer intent): the line
is driven only during a 1-wire cycle. RTL: a control write with cyc=0 and
dat=0 sets owr_oen (pulls the line low) with no cycle running." CEX: exactly
that write.

- Root cause: mixed. The documentation says a cyc=0 write is "no action",
  so driving the line on such a write is a genuine **documentation/RTL
  conflict** (same as F2). But the property itself is a self-invented
  invariant the generator *knew* the RTL breaks, so the F5–F7 cause applies
  as well. Counted under F5–F7 for ranking; the underlying behaviour is
  recorded as a conflict in notes.md.

---

## Vacuity / user covers

None. All 67 precondition covers were reached; no `cover property` in the
checker (the "no covers" rule was followed).

## Missed formal coverage (run1)

run1: formal 161/270 = 59.6 % of achievable (JSON). **This number is
truncated by the evaluation, not only by the assertions**: jg.log line 1126,
`ICOV031: The "check_cov -measure" command has reached the time-out limit
specified by … "set_prove_time_limit"`. Proof-core extraction for 3 proven
properties (`a_div_count`, `a_rst_smp_released`, `g_smp.a_smp_rst`) never
finished (in the first evaluation without a total time limit, those 3 ran
for > 20 min). `check_cov -list` after the cut-off reports only 92 items
checked (vs 161 in the JSON), with 176 of 179 toggle items unchecked.

Controlled experiment (scratchpad `exp2`): a checker with a **single**
port-only read-back assertion of the divider register checks all 32 toggle
items of both divider registers, which run1's equivalent `a_rb_cdr_n/o`
did not get credit for. So most "unchecked" toggle items in run1 are
measurement truncation, not missing assertions.

Classes visible despite the truncation:

- **M1. Hold/else branches of registers updated only on the base pulse**
  (`~pls` empty-else of the sample register, L390; `owr_oen` hold branch when
  no pulse, L400). `a_smp_hold_nopls` exists, but the sample register has no
  reset (free initial value) and the proof core for it was among the slow
  ones. Root cause: **considered it** (assertions exist) — not credited due
  to truncation. Prompt-level fix: none.
- **M2. Deep-state properties starve the analysis.** The three stalled
  properties all have antecedents that require the cycle counter at a
  mid-cycle value of a long (reset) cycle, combined with the 16-bit divider
  — reachable only after hundreds of clocks. The generator wrote them as
  plain one-step implications, which is fine as SVA. Root cause: **not in
  the prompt's reach** without referring to tool effort; the existing
  "short temporal depth" rule was obeyed. Recorded as a metric artifact.
- **M3. Constant wires and constant read-back bits** (timing-constant nets
  `t_*`, unimplemented read-back segment, 24 bits constant 0): stuck-at on a
  bit that is constant at its stuck value is undetectable by any assertion;
  the tool lists them as unchecked, not unreachable. Not a prompt failure.

---

## Ranked root causes (iteration 1)

1. **Prompt forbids listing files (F1)** — 1 of 2 runs produced nothing:
   0 asserts, 0 formal coverage. Highest impact: it zeroes a whole run.
   Prompt-caused; fix is a one-line permission + "start by listing doc/".
2. **Knowingly writing assertions the RTL violates (F5–F7)** — 3 CEX
   (4.5 % of run1's asserts). Prompt-caused (doc-wins rule over-extended to
   self-invented intent; no rule about suspected bugs).
3. **Over-reading the documentation: exclusivity and user-rules as
   guarantees (F3, F4)** — 2 CEX. Prompt silent.
4. Doc/RTL conflict (F2) — 1 CEX, not a prompt failure.

No earlier autopsy in this run to compare with.
