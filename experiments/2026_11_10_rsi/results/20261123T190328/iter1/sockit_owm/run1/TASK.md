# Task: write a SystemVerilog Assertion checker for the RTL design in this workspace

You are a verification engineer. Write a set of SystemVerilog Assertions
(SVA) that specify the behaviour of the design in this workspace, as a
checker module bound to the design's top module.

## Workspace

Your workspace is the directory named in your invocation message. Work only
inside it. It contains:

- `rtl/` — the design's RTL source.
- `doc/` — the design's documentation (datasheet, specification). If it is
  a PDF, extract its text with `pdftotext -layout <file> -` and read all of
  it.
- `<top>.f` — the RTL file list; `<top>.tcl` — the tool setup script
  (it names the clock and the reset, and their active level). `<top>` is the
  base name of these two files. The top module is the one elaborated by the
  setup script; its module name may differ from `<top>`.
- `check_syntax.sh` — compiles the RTL together with your checker and prints
  `SYNTAX OK` or `SYNTAX FAIL` with the errors. This is the only tool you may
  run besides reading files and `pdftotext`.

## Deliverables

Create exactly these two files in the workspace, and nothing else:

1. `sva/<top>_sva.sv` — one checker module plus a `bind` statement that
   instantiates it in the design's top module.
2. `<top>_sva.f` — a single line: `./sva/<top>_sva.sv`

Run `./check_syntax.sh` after writing the checker and after every later
edit, and fix every error until it prints `SYNTAX OK`.

## Two sources, two levels

Your assertions come from two sources.

1. **Documentation → high-level properties.** The documentation is the
   authority on what the design is supposed to do. Turn every concrete,
   checkable statement in it into assertions: register map and read-back
   values, reset values, what each control bit does, what each status bit
   means and when it sets and clears, the order and duration of protocol
   phases, what the outputs do in each mode, interrupt behaviour.
2. **RTL → low-level, designer-intent properties.** Use the RTL for what the
   designer evidently intended at the implementation level and the
   documentation does not spell out: invariants between registers, how a
   counter or state machine progresses, when a register must hold its value,
   which events have priority when they happen in the same cycle,
   relationships between internal state and the outputs.

If the documentation and the RTL disagree, follow the documentation.

**Do not transcribe the RTL.** An assertion that copies an RTL statement
only restates the code and says nothing new. For example, for
`assign y = a & b;` do not write `y == (a & b)`, and for
`if (c) r <= e;` do not write `c |=> r == $past(e)` with the same
expression structure. A low-level property must say something the RTL text
does not already say literally. Good forms are:

- **End-to-end behaviour**: a bus write followed by a read returns the
  written field; a started operation finishes after the documented number
  of time steps and raises its status flag; an input sampled during an
  operation appears later at an output or in a readable register.
- **Invariants** relating several signals: "when no operation is active the
  counter does not move", "the line is never driven while X", "a status bit
  can only be set while/after Y".
- **Hold / stability**: a register keeps its value in every cycle in which
  none of its documented update events happen (state the condition in terms
  of the design's interface events, not by copying the RTL's `if` chain).
- **Sequencing and timing**: what must happen next, or within / exactly
  after N events, expressed as a temporal property.
- **Event semantics**: the effect of an interface event (write, read, start,
  end of operation) on all the state it is documented to affect, including
  same-cycle collisions between events.

## Every assertion must be true

Write only assertions you believe hold for **every** legal input sequence.
Think about the environment before writing each one:

- **Inputs are unconstrained.** Unless the documentation states a usage rule,
  any input can take any value in any cycle: reads and writes can happen in
  the same cycle, back to back, to any address, with any data, and in the
  middle of an ongoing operation (restarting or aborting it). External
  input pins can toggle at any time. An assertion that assumes a "polite"
  software sequence is false.
- **Registers without a reset start with an arbitrary value**, and a register
  that is never assigned is arbitrary forever. Never assert the value of such
  a register, and do not assume it has any value until the design has
  provably written it.
- **Reset.** Use the reset from the setup script with the polarity it gives.
  Disable assertions during reset (`disable iff`). Remember that `$past`,
  `$rose`, `$fell`, `$stable` and `|=>` look one cycle back or ahead; at the
  first cycle after reset the past value is the reset value. Put reset-value
  checks in a form that does not depend on `$past` across reset, or check
  them only where they are observable.
- **Parameters.** The design is elaborated with its default parameter values.
  Read them and compute derived widths and constants yourself. You may write
  parameter-generic assertions, but each one must be correct for the default
  values. Use the design's own parameters and constants inside the checker
  (pass them as checker parameters) rather than literal numbers when a value
  comes from a parameter.
- **Widths and arithmetic.** Match widths exactly; watch truncation,
  wrap-around of counters, signedness, and comparisons of different widths.
- **Same-cycle priority.** When two events can happen in the same cycle (for
  example a software write and an internal end-of-operation), decide from the
  RTL which one wins and make your assertion account for both.
- **Timing.** `a |-> b` checks `b` in the same cycle as `a`; `a |=> b` checks
  it in the next cycle; a register assigned with `<=` shows its new value one
  cycle after the condition. Check each alignment against the RTL by hand.

Before finalising, walk through each assertion and try to construct an input
sequence that violates it. If you find one, fix or delete the assertion and
say so.

## Every assertion must be meaningful

- Its antecedent (the left side of `|->` / `|=>`) must be reachable from reset
  with legal inputs. An assertion whose trigger can never happen proves
  nothing. Avoid antecedents that combine conditions which cannot occur
  together.
- Do not write tautologies or assertions that only check that a signal equals
  itself or a constant that the code ties off.

## Specify the whole design

Together, the assertions should specify all of the design's observable
behaviour, so that a bug anywhere in the logic would violate at least one of
them. Systematically go through:

- every output port, in every mode and phase;
- every register and state variable: its reset value, every event that
  changes it, the value it takes, and the fact that it holds otherwise;
- every readable register field (what a read returns, for every address);
- every counter: start value, step, end condition, what happens at the end;
- every control bit and option, and every combination the documentation
  describes;
- every status/interrupt flag: set condition, clear condition(s), priority;
- every data path from an input to an output or a stored value.

Make a list of these items first (in a message), then write assertions for
each, then check the list again for anything you skipped. Many small,
precise assertions are better than a few large ones.

## Coding rules

- One checker module, e.g. `module <top>_sva (...)`, with an input port for
  every top-module port you use and for every internal signal you need.
  Name the checker ports exactly like the design's signals and bind with
  `bind <top_module> <top>_sva #(...) u_<top>_sva (.*);` so that internal
  signals connect by name. Declare port widths to match the design.
- Use `default clocking @(posedge <clk>); endclocking` and
  `default disable iff (<reset active>);`.
- Give every assertion a label: `a_<short_name>: assert property (...);`.
- Write only `assert property`. Do **not** write any `cover property`
  statements and do not write `assume property` unless the documentation
  states an explicit rule the environment must follow; if you write one,
  quote that rule in its comment.
- Use only synthesizable-style SystemVerilog in the checker: no `initial`
  blocks, no `$display`, no delays (`#`), no classes. Auxiliary logic
  (e.g. a small modelling register to remember a written value) is allowed in
  the checker if it is clocked by the same clock and reset by the same reset.
- Do not modify anything in `rtl/` or any other existing file.

## Document your reasoning

- Above every assertion write a short comment that names its source (the
  documentation section/table, or the RTL construct such as "counter reload
  logic") and explains in one sentence why it holds.
- As you work, explain your reasoning in plain text messages: which
  behaviours you identified, what you plan to assert, and especially every
  time you weaken, rewrite or delete an assertion, say which one and why.

## Procedure

1. Read the setup script, the file list, all RTL, and all documentation.
2. Write the list of behaviours to specify (see "Specify the whole design").
3. Write the checker and the `.f` file.
4. Run `./check_syntax.sh`; fix errors until `SYNTAX OK`.
5. Review every assertion against "Every assertion must be true" and
   "Every assertion must be meaningful"; fix, then re-run the syntax check.
6. Finish with a short summary of what the checker specifies.
