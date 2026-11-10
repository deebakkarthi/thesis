# Task: Write SystemVerilog Assertions for the RTL in `rtl/`

Working directory: `/var/home/brg8ve/.local/src/thesis/experiments/2026_11_10_rsi`

You are a formal verification engineer. Write an SVA checker for the design
in `rtl/`. It will later be run through a formal tool (Cadence JasperGold)
by someone else. You are graded on three metrics:

1. **proven %** = proven asserts / total asserts. A single false assert
   (counterexample) or undetermined assert lowers your score.
2. **covered %** = reachable cover properties / total covers.
3. **Formal (mutation) coverage**: the tool mutates every statement, branch
   (including the *implicit* "else: keep value" branch of every `if` without
   an `else`) and every bit of every signal, then checks whether some *proven*
   assertion fails. A mutation is "detected" only if an assertion pins down
   the exact value of the mutated logic. So the assertions, taken together,
   must constrain the exact next-state value of **every** register and the
   exact value of **every** output and internal wire.

## Step 0 — Discover the setup (read, don't run)

- Read every file in `rtl/` completely.
- Read the `*.tcl` script in the working directory (do NOT run it). Find:
  the clock name (`clock ...`), the reset expression (`reset ...`), and the
  name of the SVA filelist it optionally loads (e.g. `analyze -sv -f X.f`).
  You must create exactly that filelist.
- Identify the top module and the parameter values that will be elaborated
  (the defaults, unless the tcl overrides them). **Evaluate every parameter,
  localparam and generate condition by hand** and write the results down in a
  comment block at the top of your checker. Only the generate branches that
  are actually selected exist; ignore the rest.

## Step 1 — Build a signal inventory

In a comment block, list every `reg`/`logic` (sequential) and every `wire` /
continuous `assign` / output port of the elaborated design, and for each
register the full priority structure of its `always` block:

```
// <reg>: reset -> <value>
//        if (A)            <- e1
//        else if (B)       <- e2
//        else              <- hold   (implicit if no else)
```

Note specially:
- registers with **no reset** (they start at an arbitrary value),
- registers that are **never assigned** in the elaborated design, or only in
  an `initial` block — formal tools treat these as free, unconstrained
  values that may change every cycle. Never assert anything about their
  value or stability, and treat any logic that depends on them as
  depending on an arbitrary value,
- vectors whose declared width comes out as zero or negative from the
  parameters (e.g. `[N-1:0]` with N=0 gives `[-1:0]`, which is 2 bits wide
  and not zero).

## Step 2 — Write the checker

Create `sva/<top>_sva.sv` with a checker module plus a `bind`, and the
filelist found in Step 0 containing the single line `./sva/<top>_sva.sv`.

```systemverilog
module <top>_sva #(/* same parameter names as the DUT, with the DUT's defaults */) (
  input clk, input rst, // ... every port AND every internal signal you check,
                        // with the SAME name and width as in the DUT
);
  default clocking cb @(posedge clk); endclocking
  default disable iff (rst);   // use the DUT's reset expression/polarity
  ...
endmodule

bind <top> <top>_sva #(.P1(P1), .P2(P2) /* every parameter */) u_sva (.*);
```

`.*` connects by name, so each checker input must match a DUT signal name
exactly. Pass every parameter and localparam the checker needs (localparams
can be recomputed inside the checker from the passed parameters).

### Assertions — one per branch, mirroring the RTL exactly

For each register, write one assertion per branch in the inventory,
including the hold branch. The antecedent of branch *k* must include the
negation of all higher-priority conditions. Use current-cycle values in the
antecedent and `|=>` with `$past(...)` for the values the RTL used:

```systemverilog
// if (A) r <= x; else if (B) r <= y;   (no else)
a_r_e1:   assert property ( A          |=> r == $past(x));
a_r_e2:   assert property (!A &&  B    |=> r == $past(y));
a_r_hold: assert property (!A && !B    |=> r == $past(r));
```

**Nested ifs: one hold assertion per nesting level.** Every `if` without an
`else` — at any depth — has its own implicit empty branch, and the tool
scores each separately. Do not merge them into one big hold assertion:

```systemverilog
// if (W) r <= v; else if (P) begin if (C1) r <= 0; else if (C2) r <= 0; end
a_r_hold_outer: assert property (!W && !P               |=> r == $past(r));
a_r_hold_inner: assert property (!W &&  P && !C1 && !C2 |=> r == $past(r));
```

**Reset values.** Mutations of the reset assignment are only detected if an
assertion checks the value right after reset. Add one auxiliary flop to the
checker and assert every reset value in the first cycle after reset:

```systemverilog
logic first_cyc;
always @(posedge clk or posedge rst)   // match the DUT's reset style/polarity
  if (rst) first_cyc <= 1'b1; else first_cyc <= 1'b0;
a_r_rstval: assert property (first_cyc |-> r == <RTL reset value>);
```

Do this for every register that has a reset (not for unreset or
never-assigned ones). Use the evaluated reset value, cast to the register's
width.

Important: inside the consequent of `|=>`, any signal *not* wrapped in
`$past` is sampled in the *next* cycle. Every right-hand-side term of the
RTL assignment must be wrapped in `$past(...)`.

For every continuous assignment / output, write a combinational assertion
with the exact RTL expression, e.g.
`a_out: assert property (out == (a & b));`. For multiplexed outputs, write
one assertion per select value. For wires computed from parameters, assert
the evaluated value against the condition that selects it.

### Design structures that need extra care

- **Hierarchy**: if the design has submodules, write one checker per module
  type and `bind` it to that module (the bind applies to every instance), so
  internal signals are reached by name. Do not use hierarchical references
  into instances from the top checker.
- **Reset style**: copy the DUT's reset exactly — active-low (`!rst_n`),
  synchronous (`always @(posedge clk) if (rst) ...`) or asynchronous. For a
  synchronous reset the reset value appears one clock after reset is
  asserted; the `first_cyc` pattern still works because the tool starts in
  the reset state. Registers in blocks without any reset branch are
  "unreset" (see Step 1).
- **FSMs** (`case (state)`): one assertion per state per transition branch
  (`state == S_A && cond |=> state == S_B`), one hold assertion per state,
  plus `state` is always a legal encoding. Each `case` item is a branch, and
  a `default` item is a branch too.
- **Arrays / memories**: assert the written entry after a write
  (`we |=> mem[$past(addr)] == $past(wdata)`) and that an entry is unchanged
  when it is not written; use a `generate for` loop over indices if the
  array is small (≤ 32 entries), otherwise assert only through the write and
  read ports.
- **Generate loops / vectors updated per bit**: use `generate for` in the
  checker to emit one assertion per bit or per element, mirroring the RTL.
- **Multiple clocks**: give each assertion an explicit clock
  (`@(posedge clk_b)`) instead of relying on the default clocking, and never
  mix `$past` across clock domains.
- **Combinational `always @*` / `always_comb` blocks**: treat each branch
  as a combinational assertion with the branch condition as the antecedent
  (`|->`, not `|=>`).

Also add, when applicable, higher-level properties (mutual exclusion,
counter ranges, one-hot, "after event X, Y eventually within N cycles" with
small N) — but only if you are certain they hold.

### Covers

Add 10–20 `cover property` statements for clearly reachable behaviour: each
register taking each branch at least once, each output toggling, key
protocol events. Keep them short (1–3 cycles). Do not write covers that
require the reset to be asserted again, a parameter-disabled feature, or a
value outside a register's reachable range.

### Rules that prevent false assertions

- Reset: the tool applies reset once at the start and then keeps it
  inactive. Do not write `rst |=> ...` assertions or covers that need reset
  asserted again (vacuous / unreachable); check reset values only via the
  `first_cyc` pattern above.
- Do not assert values of registers that have no reset or are never assigned,
  except one cycle after an RTL assignment to them, or as hold
  (`r == $past(r)`) under exactly the RTL's hold condition.
- Inputs are unconstrained (no `assume`): any input may take any value in
  any cycle, including in the same cycle as other events. Check whether a
  simultaneous input event (e.g. a bus write) overrides the branch you are
  asserting.
- Watch for width truncation and wrap-around: RTL arithmetic like `cnt - 1`
  wraps; compare with a cast to the register width, e.g.
  `cnt == $bits(cnt)'($past(cnt) - 1)`.
- Variable indexing (`v[idx]`, `a << s`) where `idx`/`s` can exceed the
  declared range yields X or 0 in synthesis-like semantics. If the index can
  be free or out of range, split the assertion by index value
  (`idx == k |-> ...` for each in-range k) and do not assert the
  out-of-range case for bit-selects.
- Avoid `===` / `!==` and `$isunknown`; use `==`.
- No unbounded liveness (`s_eventually`, `[*]`, `##[1:$]`).
- Every assert and cover gets a unique label.

## Step 3 — Syntax check only — do NOT look at verification results

You must NOT run any proof, the tcl script in the working directory,
`prove`, or `check_cov`, and you must NOT read anything under `metrics/` or
`jgproject/`. You MAY use JasperGold purely as a compiler. Write this to
`/tmp/syncheck_$USER.tcl` (adapt the filelist names to what you found in
Step 0):

```tcl
clear -all
analyze -v2k -f <rtl filelist>.f
analyze -sv -f <sva filelist>.f
elaborate -bbox 1
exit -force
```

```bash
cd /var/home/brg8ve/.local/src/thesis/experiments/2026_11_10_rsi && jg -no_gui -tcl /tmp/syncheck_$USER.tcl < /dev/null 2>&1 | grep -E "ERROR|WARNING" | head -40
```

Fix every ERROR and every warning that comes from your checker or the bind
(unknown or unconnected ports, width mismatches). Warnings inside `rtl/` are
not yours to fix, but read them: they often reveal signals that are
undriven or truncated, which you must treat as described above.

## Step 4 — Self-review

Re-audit each assertion line by line against the RTL: the priority guards,
`$past` alignment, widths, generate-branch selection, and the unconstrained-
input and undriven-signal cases. Delete any assertion you are not sure is
true; a false assert costs more than a missing one. Make sure every register,
every hold branch, and every output/wire still has at least one assertion.

Final completeness checklist (tick each in a comment at the end of the file):
- [ ] every register: one assert per explicit branch, one per implicit hold
      at every nesting level, one reset-value assert (if it has a reset)
- [ ] every continuous assign / output port: exact-value assert (per mux
      select value where there is a mux)
- [ ] every parameter-derived wire: evaluated-value assert
- [ ] no assert on never-assigned or unreset values (except relational ones
      described above)
- [ ] 10–20 short, reachable covers
- [ ] syntax check clean

Do not modify anything in `rtl/`, the tcl script, or the RTL filelist.
Finish with a short summary listing the number of asserts and covers.
