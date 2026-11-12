# Task: write a SystemVerilog Assertion checker for the RTL in `rtl/`

Your workspace directory is given in the message that invoked you. All
paths below are relative to it. Work only inside it.

**Output (exactly these two files, nothing else):**
- `sva/<top>_sva.sv`: a checker module plus a `bind` statement
- `<top>_sva.f`: one line, `./sva/<top>_sva.sv`

You are a verification engineer. Your checker is the executable
specification of the design: a reviewer who has never seen the RTL should
be able to read your properties and understand what the block does, how its
interfaces behave, and how long everything takes. Every assertion must hold
for all legal input sequences, every cover must describe a reachable
scenario, and together the properties should specify all of the design's
observable behaviour, exactly enough that any change to that behaviour
would violate at least one assertion.

## The cardinal rule: specify intent, do not copy the code

A property that restates an RTL statement checks the code against itself:
it can never find a bug and it inherits every bug in the RTL. Forbidden
patterns:

- copying the right-hand side of an `assign`
  (`assign y = a & b;`  ->  `y == (a & b)`)
- turning `if (c) r <= e;` into `c |=> r == $past(e)` with the same
  condition and expression structure
- walking the `if/else` priority chain of an `always` block and writing one
  assertion per branch
- re-implementing an RTL `always` block line by line inside the checker as a
  "model"

Instead, state what a designer or a datasheet would say, preferably in terms
of the **ports** (bus transactions, outputs, interrupt, external lines) and
of **time measured in clock cycles**. Self-test for every assertion: *could
I have written this from a datasheet of the block, without seeing the code
line it covers?* If not, rewrite it at a higher level. Referring to an
internal signal is fine when it carries a meaningful concept (a state, a
count, a mode bit), as long as the property says something the RTL text
does not already say literally.

## Step 0 — Read and set up

- Read every file in `rtl/` completely, including the header comments: they
  often describe the intended behaviour, timing and register map.
- Read the `*.tcl` file in the workspace (do NOT run it). Find the clock
  (`clock ...`), the reset expression and polarity (`reset ...`), the top
  module (its name is `<top>` in the output file names) and any parameter
  overrides or defines.
- Evaluate every parameter, localparam and generate condition by hand for
  the elaborated configuration and write the results in a comment block at
  the top of the checker. Only the selected generate branches exist. A
  macro that is not defined selects the `else` side of an `ifdef`.

## Step 1 — Write the specification first (as a comment block)

Before writing any property, write a short datasheet of the block, in your
own words, in a comment at the top of the checker:

1. **Purpose**: one paragraph on what the block does.
2. **Interfaces**: each port group (bus, interrupt, external I/O) and its
   protocol: when a read or write takes effect, read latency, which strobes
   matter.
3. **Register map**: for every software-visible address, each field, its
   bit position, access type (read/write, read-only status, write-to-start,
   clear-on-read, clear-on-write, ...), reset value, and the side effects of
   reading or writing it. Note fields that always read as zero.
4. **Operations and timing**: each operation the block performs (a
   transfer, a timed pulse, a counted delay, ...), what starts it, how its
   duration in clock cycles depends on configuration, what the outputs do
   during it, and how it ends (status bits, interrupt).
5. **Modes**: configuration bits that change behaviour, and how.
6. **Free values**: registers with no reset, registers that are never
   assigned in the elaborated design (or only in an `initial` block), and
   inputs. These are arbitrary: they may hold any value and, if never
   assigned, may change every cycle. Never assert their value; treat logic
   that depends on them as depending on an arbitrary value.

Then list the properties you plan, grouped by spec item. Every spec item
should be covered by at least one assertion.

## Step 2 — Property styles to use

Prefer these, roughly in this order:

- **Register-map semantics through the bus.** "After a write of value V to
  address A, a read of A returns the written fields of V (and reserved bits
  as zero) until the next write to A or an event documented to change the
  field." Determine from the code whether read data is combinational or has
  a fixed latency, and say so in the spec.
- **Reset values seen at the ports.** In the first cycle after reset, a
  read of each address returns the documented reset value, and outputs are
  at their idle values. Use a checker-local flag that is 1 only in that
  cycle (see template).
- **Timing measured in cycles.** "Once an operation starts, output X is
  asserted for exactly N cycles", "the done flag rises exactly N cycles
  after start", "nothing changes until the prescaler has produced K
  ticks". Use a small checker-local counter or `##N` / `[*N]` sequences
  to measure time between port-visible events. Derive N from the
  parameters and configuration registers, and compute it in the checker
  with a `localparam` or function written from the spec formula, not by
  copying an RTL expression.
- **Side effects of software access.** Writing a control register starts an
  operation, clears status, or aborts an operation in progress; reading a
  status register clears it; and the field does not change without such a
  cause ("stays stable unless X, Y or Z happens").
- **Outputs in architectural terms.** For example: "the interrupt output is
  high exactly when the enable bit and the pending bit, as seen through the
  register map, are both set"; "the external line is driven only while an
  operation is in progress".
- **Invariants.** Mutual exclusion, one-hot, legal ranges of counts and
  states, "busy implies the timer is non-zero", "idle implies the output is
  released".
- **Legal state sequences**, expressed through their observable effects.
- **Bounded liveness.** "An operation started with configuration C ends
  within N cycles", with a concrete, computed N.

Checker-local helper logic (flags, counters, shadow copies of fields
written through the bus) is encouraged, as long as it models the
**specification** ("the last value written to this field", "cycles since
the operation started") and not the RTL's internal implementation.

## Step 3 — Write the checker

```systemverilog
module <top>_sva #(/* parameters you need, same names and defaults as the DUT */) (
  input clk, input rst,  // every port and internal signal you reference,
                         // SAME name and width as in the DUT, all inputs
);
  default clocking cb @(posedge clk); endclocking
  default disable iff (rst);   // the DUT's reset expression and polarity

  // 1 only in the first cycle after reset is released
  logic first_cyc;
  always @(posedge clk or posedge rst)   // match the DUT's reset style
    if (rst) first_cyc <= 1'b1; else first_cyc <= 1'b0;
  ...
endmodule

bind <top> <top>_sva #(.P1(P1) /* each parameter you declared */) u_sva (.*);
```

`.*` connects by name, so every checker input must exactly match a DUT
signal name. If the design has submodules, write one checker per module
type and bind it to that module type; do not use hierarchical references.
With several clocks, give each property its explicit clock and never mix
`$past` across clock domains.

### Correctness rules (a false assertion is worse than a missing one)

- **Environment.** Reset is applied once at the start and then stays
  inactive. Inputs are otherwise unconstrained: any input may take any
  value in any cycle, including bus reads and writes in the same cycle as
  other events, writes in the middle of an operation, and writes to any
  address. Antecedents must account for every such interference
  (typically "... and no bus write in between").
- Do not write properties that need reset to be asserted again.
- **`|=>` alignment.** In `A |=> B`, `B` is evaluated one cycle after `A`;
  any signal in `B` that should refer to the cycle of `A` must be wrapped
  in `$past(...)`. In `A ##1 B |-> C`, all of `C` is evaluated in the cycle
  of `B`.
- **Widths and wrap-around.** Arithmetic in the RTL wraps at the register
  width; casts like `W'(x - 1)` make that explicit. Values written through
  a bus are truncated to the field width.
- **Out-of-range indexing.** A variable bit-select or shift by an index
  that may exceed the declared range yields X or 0; if such an index is
  free or unreset, do not assert the result.
- Free values (Step 1, item 6): never assert their value or stability.
- Avoid `===`, `!==`, `$isunknown`. No unbounded liveness (`s_eventually`,
  `##[1:$]`, `[*]` without an upper bound).
- Every assert and cover has a unique, descriptive label
  (`a_<spec_item>_...`, `c_<scenario>_...`).

### Covers

Write 10–20 `cover property` statements, one per interesting scenario of
the spec: each operation started and completed in each mode, each status or
interrupt event, each register written and read back, the end of each timed
phase. Covers may be long when the scenario genuinely takes many cycles.
Do not write covers that need reset again, a feature disabled by the
parameters, or a value outside a register's reachable range.

## Step 4 — Syntax check (the only command you may run)

The only command you may run is `./check_syntax.sh` in the workspace
directory. It compiles and elaborates the RTL together with your checker
and prints ERROR/WARNING lines followed by `SYNTAX OK` or `SYNTAX FAIL`.
Do not run any other tool, the tcl script, or any simulator, and do not
read anything outside the workspace.

Fix every ERROR and every warning that comes from your checker or the bind.
Warnings inside `rtl/` are not yours to fix, but read them: they often
reveal undriven or truncated signals, which are free values.

## Step 5 — Self-review

Go through every assertion and check:

1. **Truth.** Is it true for every input sequence, including a bus access
   in any cycle and a write that interrupts an operation? Are `$past`
   alignment, widths and the elaborated parameter values right? If you are
   not sure, narrow the antecedent (e.g. exclude interfering writes) or
   delete the assertion.
2. **Non-vacuity.** Can its antecedent actually happen after reset?
3. **Intent.** Does it pass the datasheet test from the cardinal rule? If it
   is a copy of an RTL statement, rewrite it.
4. **Completeness.** Does every register field, every output, every timed
   phase and every mode appear in at least one assertion that pins its
   exact value or duration? Is every documented side effect checked, and
   also the absence of change when nothing happens?

Do not modify anything in `rtl/`, the tcl script, or the RTL filelist.
Finish with a short summary listing the number of asserts and covers.
