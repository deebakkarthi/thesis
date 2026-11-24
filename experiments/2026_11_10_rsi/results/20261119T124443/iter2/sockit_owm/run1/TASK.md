# Task: write a SystemVerilog Assertion checker for an RTL design

You are a verification engineer. Your workspace (given in your invocation
message) contains:

- `rtl/` — the RTL of the design,
- `doc/` — the design's documentation (datasheet, specification, ...),
- `<top>.f` — the RTL file list (its name gives you `<top>`, the top module),
- `<top>.tcl` — the tool setup script; read it to learn the clock and the
  reset signal (name and active level),
- `check_syntax.sh` — compiles the RTL together with your checker and prints
  `SYNTAX OK` or `SYNTAX FAIL` with the errors.

Your job is to write a set of SystemVerilog assertions that, together,
specify the observable behaviour of the design as completely as you can,
where every assertion is true of the design for every legal input sequence.

## Deliverables (write exactly these two files, nothing else)

1. `sva/<top>_sva.sv` — one checker module plus a `bind` statement that
   binds it into `<top>`.
2. `<top>_sva.f` — a single line: `./sva/<top>_sva.sv`

You may freely inspect the workspace: list directories (e.g. `ls`, or your
file-search tool), and read or search any file in it. Start by listing
`doc/` and `rtl/` to find every file — the documentation file names are not
known in advance and need not match `<top>`. Apart from read-only
inspection, the only program you may run is `./check_syntax.sh` (from the
workspace directory). Read PDF documentation with your file-reading tool, a
range of pages at a time, until you have read all of it.

## Procedure

1. **Read the documentation completely.** It is the authoritative statement
   of what the design must do. Note every register, bit field, reset value,
   access type (read/write, read-to-clear, write-only, reserved), every
   protocol or timing rule, every mode and every statement of the form
   "when X then Y" or "X never happens".
2. **Read the RTL completely.** For every register note: its reset value
   (or that it has none), every condition that changes it, and its priority
   order among those conditions. For every output note how it is derived.
   Note which parameters / generate branches are active with the default
   parameter values (the design is elaborated with its defaults).
3. **Read `<top>.tcl`** for the clock and reset.
4. **Plan** the properties (see "What to write") before writing code. State
   your plan in a short text message.
5. **Write the checker**, run `./check_syntax.sh`, fix errors, repeat until
   `SYNTAX OK`.
6. **Review every assertion** against the checklist in "Making sure each
   assertion is true" and fix or remove the ones that fail it.

Explain your reasoning in plain text messages as you go: what you learned
from the documentation, what you learned from the RTL, any place where they
disagree, and — whenever you weaken, rewrite or delete an assertion — what
was wrong with it and why the new version is right.

## What to write

Write assertions from two sources, at two levels:

- **Documentation → high-level assertions.** Turn each documented behaviour
  into a property: register reset values, read-back of written fields, how
  each control bit affects the outputs, status flags (when they set, when
  they clear, what clears them), interrupt behaviour, protocol sequencing and
  timing, mode-dependent behaviour, and "never" statements. When the
  documentation and the RTL disagree, the documentation is the reference:
  write the assertion as the documentation describes it and mention the
  disagreement in your text messages.
- **RTL → low-level, designer-intent assertions.** For behaviour the
  documentation does not spell out, write properties capturing what the
  designer evidently intended: invariants between state registers (e.g. a
  counter stays within its range while a mode is active, a busy flag is low
  whenever a counter is idle), how a counter or state machine progresses
  from one step to the next, which events start and end an operation, what
  happens to outputs at the end of an operation, and the effect of each
  priority case (which of two simultaneous events wins).

**Only write assertions you believe hold.** You are specifying the design,
not hunting for bugs. The "documentation is the reference" rule applies
only to behaviour the documentation states explicitly. An RTL-level
property must describe what the RTL actually does: never write an RTL-level
assertion that you expect the RTL to violate, and never invent an "intended"
behaviour that neither the documentation states nor the RTL implements. If
some RTL behaviour looks like a bug but no documentation statement
contradicts it, mention it in a text message and either assert what the
RTL really does or leave it out.

**Do not transcribe the RTL.** An assertion that copies an `assign`
expression (`y == (a & b)` for `assign y = a & b;`) or rewrites
`if (c) r <= e;` as `c |=> r == $past(e)` with the same expression says
nothing the code does not already say. Instead, state the *intent* in
terms of observable effects: relate inputs to outputs over time, relate
registers to each other, express what an operation achieves end to end,
or use concrete values derived from the documentation (e.g. "after writing
value V to register R, a read of R returns V").

**Cover all of the design.** Go through every register, every output and
every branch of every `always` block and make sure at least one assertion
would fail if that logic were wrong — including the data path (values that
flow from inputs into registers and out to outputs), every clear/set path of
status bits, every mode and every priority case. Logic with no assertion on
it is unspecified. Prefer many small, focused assertions over a few large
ones. Internal signals of `<top>` may be referenced through the `bind` port
connections when outputs alone cannot show a behaviour.

**No cover statements.** Do not write any `cover property` (or `cover`)
statements; write only `assert property` (and, if strictly needed, see
below, `assume property`).

**Comment every assertion** with one short line naming its source (the
documentation section/table, or the RTL construct — e.g. "RTL: counter
reload on start") and why it holds.

## Making sure each assertion is true

Check every assertion against each of these points before you finish:

- **Inputs are unconstrained.** Every input can take any value in every
  cycle, including bus reads/writes to any address at any time, during an
  operation in progress, and simultaneous events. Your assertion must hold
  for all of them. If a documented behaviour only holds when, say, no
  interfering write happens, put that condition in the antecedent (e.g.
  `!write_enable` in the relevant cycles) rather than assuming it.
- **Do not add `assume property`** unless the documentation states an
  explicit requirement on the environment and the property cannot be
  stated without it; keep any assumption minimal.
- **Registers without a reset start with an arbitrary value**, and
  undriven or never-assigned signals are arbitrary in every cycle. Never
  assert a specific value of such a signal unless the design has first
  written it.
- **Reset.** Use `default disable iff (<reset active>)`. Check reset values
  in the first cycle after reset is released (e.g. for an active-high reset,
  `$fell(rst) |-> reg == RESET_VALUE`), taking care with the reset polarity
  and whether the reset is synchronous or asynchronous.
- **Timing alignment.** `a |-> b` checks `b` in the same cycle; `a |=> b`
  checks it one cycle later. A register assigned on a clock edge shows its
  new value in the *next* cycle; `$past(x)` is the value of `x` one cycle
  earlier. Get the cycle count exactly right; if unsure, express the
  property in terms of `$past`/`$rose`/`$fell` of the triggering event.
- **Widths and signedness.** Compare values of the same width; beware of
  truncation in arithmetic such as `counter - 1`.
- **Parameters.** Use the design's parameters (pass them through the
  `bind` or reference them by the same names) rather than hard-coding
  numbers that depend on them; only write assertions for the generate
  branches that are actually elaborated.
- **Reachable antecedents.** Every implication's left-hand side must be able
  to occur in some legal run. Do not write antecedents that combine
  mutually exclusive conditions.
- **Short temporal depth.** Prefer safety properties that relate one cycle
  to the next or to a few cycles later. Do not write unbounded liveness
  (`s_eventually`, `##[1:$]` in a consequent) or very long fixed delays;
  express long-running behaviour as step-by-step invariants instead.
- **Priority.** When several conditions can change a register in the same
  cycle, your antecedent must exclude the higher-priority ones or your
  consequent must account for them.

## Checker structure

```systemverilog
module <top>_sva #(/* same parameters as <top>, same defaults */) (
  input logic clk, rst /* , every port of <top> and any internal signals used */
);
  default clocking cb @(posedge clk); endclocking
  default disable iff (rst /* active level per <top>.tcl */);

  // <source>: <why it holds>
  a_name: assert property ( ... );
endmodule

bind <top> <top>_sva #(/* .P(P) for each parameter */) u_<top>_sva (.*);
```

Use `.*` or explicit connections; every name you connect must exist in
`<top>`. Give every assertion a unique, descriptive label. Use only
synthesizable-style SVA (no `$display`, no `initial` blocks, no classes).

When you are done, reply with a short summary: the number of assertions,
grouped by what they check, and any documentation/RTL disagreements you
found.
