# Iteration 1 autopsy

Evaluation note: mid-iteration the user replaced mutation coverage with COI
coverage and set the limits to 30 s per property and 2 m in total, so that runs
finish fast. Both runs were scored with that script. Under COI both runs reach
298/299; the one missed item is the toggle of `bus_wen_pwr_sel`, which drives
nothing for OWN=1. So formal coverage does not tell these runs apart this
iteration, and the autopsy concentrates on metrics 1 and 2.

| run | proven | CEX | undetermined | vacuous | formal (COI) |
|---|---|---|---|---|---|
| run1 | 22/33 | 7 | 4 | 3 | 298/299 |
| run2 | 21/29 | 8 | 0 | 0 | 298/299 |

## run1

### F1. a_cnt_idle_hold, a_dat_hold_idle, a_irq_only_end (CEX): the generator knew they would fail

- **What happened**: `!owr_cyc && !bus_wen |=> $stable(cnt)`,
  `!owr_cyc && !bus_wen |=> $stable(owr_dat)` and
  `$rose(irq_sts) |-> $past(owr_cyc)` all fail. With overdrive and a divider
  ratio of 0, the RTL's base-period pulse is high on every clock even while
  idle. The counter keeps decrementing, and on wrap-around the end-of-cycle
  event sets `irq_sts` and reloads `owr_dat`.
- **Generator's reasoning**: it found this behaviour itself and wrote the
  assertions *in order to* fail. Its checker comment says: "The RTL decrements
  cnt on pls without checking owr_cyc ... This is expected to fail (see the
  report)." Its final report says: "Expected to FAIL on the current RTL ...
  these are the bugs the checker is meant to catch".
- **Root cause**: a prompt instruction misled it. The "Specify the whole
  design" section says the assertions should be such "that a bug anywhere in
  the logic would violate at least one of them". The generator read the task
  as bug hunting. Nothing in the prompt says that an assertion it believes the
  RTL violates must not be written.
  - `a_irq_only_end` and `a_dat_hold_idle` come from documentation statements
    (4.4: irq is set at the end of a cycle; dat changes only at the end of a
    cycle or on a write). They are genuine documentation/RTL conflicts, which
    are not counted as prompt failures.
  - `a_cnt_idle_hold` is an RTL-level "intent" property that contradicts what
    the RTL does. That one is a prompt failure.
- **Prompt-level fix**: state that the generator is not looking for bugs. An
  RTL-level property must describe what the RTL actually does, so a property
  it believes this RTL violates is deleted, not kept. Drop the "a bug anywhere"
  wording.

### F2. a_no_drive_cyc0 (CEX): documentation/RTL conflict

- **What happened**: `ctl_wr && !bus_wdt[3] && !owr_cyc |=> !owr_oen` fails.
  The RTL loads `owr_oen` on every control write regardless of cyc.
- **Generator's reasoning**: the comment quotes doc 4.4 ("cyc=0 means no
  action") and notes "The RTL updates owr_oen on every control write,
  regardless of cyc".
- **Root cause**: documentation/RTL conflict, not a prompt failure. It is
  written in the same "expected to fail" spirit as F1, though.
- **Prompt-level fix**: none needed beyond F1.

### F3. a_e_mirror_oen, a_sample_slot, a_sample_presence (CEX): values that depend on an undriven register

- **What happened**: with OWN=1 the select register `owr_sel` is zero-width.
  It has only an `initial` block, which the tool ignores: the syntax check
  prints "'initial' construct is ignored". So `owr_e = owr_oen << owr_sel` and
  `owr_iln = owr_i[owr_sel]` depend on a free value, and all three assertions
  get a CEX.
- **Generator's reasoning**: "on the current RTL this depends on owr_sel,
  which is never written when OWN=1 (no reset, only an initial block), so this
  is expected to fail." It also listed the sample checks under "Expected to
  FAIL".
- **Root cause**: the generator ignored a prompt rule: "a register that is
  never assigned is arbitrary forever. Never assert the value of such a
  register." It applied the rule to the register itself, not to signals
  computed from it, and it was also bug hunting (F1).
- **Prompt-level fix**: extend the rule to every signal whose value depends on
  such a register, and say that registers set only in `initial` blocks are
  unassigned. Plus the F1 framing fix.

### F4. a_cyc_hold, a_cyc_end, a_oen_hold, a_oen_release (undetermined)

- **What happened**: these four compare a 26-bit free-running clock counter
  `ccnt` with `mul9x17(tlen, cdr+1)`, a shift-and-add product. None of them
  resolves within 30 s.
- **Generator's reasoning**: "a shift-and-add function instead of `*`, which
  avoids a blackboxed multiplier". It sized `ccnt` for the longest possible
  cycle with any divider value.
- **Root cause**: the prompt is silent on keeping auxiliary modelling logic
  small. A 26-bit counter compared with a runtime product is very hard for the
  prover.
- **Prompt-level fix**: keep checker-internal state as narrow as possible.
  Prefer relating events to the design's own counters or event signals over
  free-running wide counters and runtime arithmetic. Lower priority than
  F1/F3/F5.

### F5. a_rst_regs, a_rst_outs, a_rst_cdr (vacuous)

- **What happened**: written as `disable iff (1'b0) rst |-> ...`. The reset
  is never asserted again after initialisation, so the antecedent is
  unreachable.
- **Generator's reasoning**: "Reset is asynchronous, so the registers already
  hold their reset values in every cycle where rst is high. These checks
  therefore do not use the default disable iff, which would hide them."
- **Root cause**: a prompt instruction was too vague to guide it. "Put
  reset-value checks in a form that does not depend on `$past` across reset,
  or check them only where they are observable" pushed it away from the
  `$past(rst)` form, and that is the form run2 used successfully.
- **Prompt-level fix**: say that reset values are checked in the first cycle
  after reset is released (e.g. `$past(<reset active>) |-> ...`), and that an
  assertion triggered by reset being active is never exercised.

## run2

### F6. a_cyc_len, a_cyc_line, a_cyc_end_irq, a_cyc_end_bus_irq, a_cyc_dat_latch, a_pri_end_rd (CEX, 2–3 cycles): a blackboxed multiplier made the tracker's targets free

- **What happened**: the checker's length functions compute
  `(...) * (CDR_x + 1)` with a variable left operand. The syntax check printed
  three `WNL018 ... multiplication operator mult_32s_4s (size 36)
  automatically blackboxed` warnings, so `dlen`, `rlen` and `slen` are
  arbitrary. A dumped CEX shows the same write (`bus_wdt=11`, a timed idle)
  loading `dlen=0` in one trace and `dlen=1` in another, and `slen=65535`. A
  scratch rerun with divider writes assumed away still has exactly these 6
  CEX.
- **Generator's reasoning**: it saw the warnings (trace step 11) and
  summarised: "Only warnings are width truncations and the RTL's own owr_sel
  warning." It did not register the blackbox warning.
- **Root cause**: the prompt is silent on tool warnings. It only says "fix
  every error until it prints SYNTAX OK", which taught it that warnings don't
  matter.
- **Prompt-level fix**: read every warning that names the checker file.
  Treat a warning that an operator or module was blackboxed or removed as an
  error, because its output is then arbitrary. Avoid `*`, `/` and `%` on
  non-constant operands in auxiliary logic.

### F7. a_cyc_busy_noirq, a_cyc_dat_hold (CEX): divider ratio taken from the reset-value parameter

- **What happened**: the CEX writes 0 to the divider register, then starts a
  cycle. The real cycle is 5× shorter than the checker's `dlen`, which is
  computed from `CDR_N + 1`.
- **Generator's reasoning**: its timing model is labelled "default
  parameters, BP = base period = CDR+1 clocks". It cancels tracking on any bus
  write, so it knew a divider write mattered *during* a cycle. It never
  considered a divider write *before* the start.
- **Root cause**: overlooked environment freedom. A software-writable
  configuration register was treated as its reset value. The prompt's
  "Inputs are unconstrained" bullet covers bus writes in general but says
  nothing about configuration registers that software can change.
- **Prompt-level fix**: when a behaviour depends on a software-writable
  register, use that register's current value (or the value latched at the
  start of the operation), never its reset-value parameter.

## Missed formal coverage

Both runs: one item, the `bus_wen_pwr_sel` toggle (line 128). It is
unreachable or undetectable for OWN=1, because nothing reads it. No class of
logic is missed. Note that COI coverage only asks whether some proven
assertion has the item in its cone of influence, so it is much weaker than
mutation coverage. Both runs saturate it despite 30–35% false asserts.

## Ranked root causes

1. **Wrote assertions it believed the RTL violates (bug-hunting framing,
   misled by "a bug anywhere ... would violate").** run1: 7 CEX
   (F1, F2, F3). Of these, 3 are doc/RTL conflicts, but the mindset produced
   them all. Prompt-caused.
2. **Ignored tool warnings: blackboxed arithmetic in the checker.** run2: 6
   CEX (F6). Prompt silent.
3. **Free (undriven or initial-only) registers propagated through derived
   signals.** run1: 3 CEX (F3), overlapping with 1. The prompt rule is too
   narrow.
4. **Reset-value checks triggered on active reset.** run1: 3 vacuous (F5).
   The prompt wording is vague.
5. **Software-writable configuration taken as its reset value.** run2: 2 CEX
   (F7). Prompt silent.
6. **Wide auxiliary counters and runtime arithmetic.** run1: 4 undetermined
   (F4). Prompt silent.

Recurring patterns: iteration 1, so there are no earlier autopsies. Both runs
independently spotted the RTL's idle-overdrive counter behaviour. Only run1
turned it into failing assertions; run2 avoided asserting idle behaviour.
