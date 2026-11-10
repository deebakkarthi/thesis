# RSI: a general-purpose SVA generation prompt

Your goal is to produce `SLAVE_PROMPT.md`: a prompt that makes a `haiku`
agent write high-quality SystemVerilog Assertions for **any** RTL design. You
tune it by running it on the designs in `designs/` and reading the metrics.
The prompt is judged by how it performs on designs it has never seen.

Paths below are relative to this directory
(`experiments/2026_11_10_rsi`).

## Designs

Each design lives in `designs/<name>/` and contains `rtl/`, `<name>.f` (RTL
filelist) and `<name>.tcl` (the frozen JasperGold evaluation script). The top
module is `<name>`. Never edit anything in `designs/`.

- Tuning designs: every directory in `designs/` not listed as held-out.
- Held-out designs: none yet. If any are listed here, evaluate them **only**
  in the final iteration, and never let what you see in them change the
  prompt.

## Hard constraints on `SLAVE_PROMPT.md`

1. **Generic.** It must work verbatim on an unseen design. It must not
   contain anything taken from a specific design: no module, signal or
   parameter names, no parameter values, no line numbers, no
   design-specific file names, and no assertions written for a particular
   design. Test: if you pasted the prompt next to a different RTL, every
   sentence must still make sense. You may add rules for *classes* of
   mistakes you observed (e.g. "registers that are never assigned are free
   in formal; never assert their value").
2. **No verification feedback for the slave.** The slave must not run
   proofs or coverage, or read any metrics or logs. It may only compile
   its checker with `common/syntax_check.sh`. The prompt must say this.
3. **Fixed interface.** The slave is given a workspace directory. It must
   write `sva/<top>_sva.sv` (checker module plus `bind`) and `<top>_sva.f`
   (one line: `./sva/<top>_sva.sv`) in that workspace, and nothing else.
   The prompt must not hard-code a workspace path; the path is passed in
   the invocation message (see Loop).

## Metrics (in priority order)

`common/metrics.py` prints these for each run; `common/summarize.py`
aggregates them.

1. **proven %** = proven / user asserts. Must be 100%: a false or
   undetermined assert is the worst outcome.
2. **covered %** = covered / user-written covers. Must be 100%.
3. **non-vacuous %** = asserts whose antecedent is reachable (the tool's
   `:precondition` covers). Should be 100%; a vacuous assert proves nothing.
4. **formal % of achievable** = covered_and_checked /
   (total − unreachable_or_undetectable) of the top instance's
   `formal_coverage_local` (mutation coverage). Maximise this once 1–3 are
   at 100%. The raw % is printed too, but items the tool marks
   unreachable/undetectable (e.g. reset branches, undriven signals) cannot
   be reached by any assertion, so don't chase them.

Do not inflate 1–2 by asking for fewer or trivial assertions: a prompt that
loses formal coverage to gain proven % is worse.

## Tools (all in `common/`)

| Script | Who | What it does |
|---|---|---|
| `prepare.sh <design> <iter> <k>` | master | Creates a fresh workspace `work/iter<iter>/<design>/run<k>/` (RTL, filelist and tcl only) and prints its path. |
| `syntax_check.sh <workspace>` | slave | Runs the design tcl up to `elaborate` (compile only) and prints ERROR/WARNING lines, then `SYNTAX OK` or `SYNTAX FAIL`. |
| `eval.sh <design> <iter> <k>` | master | Copies the workspace's output into `results/iter<iter>/<design>/run<k>/` with the frozen design files, runs JasperGold there (with timeout, `< /dev/null` and a private project dir, so there are no hangs or lock files), prints the metrics, and appends to `results/iter<iter>/summary.tsv`. Takes about 1 minute per run. |
| `metrics.py <run_dir>` | master | Re-prints one run's metrics, listing every CEX, unreachable cover and vacuous assert by name. |
| `list_uncovered.sh <run_dir>` | master | Re-runs the proof and writes `<run_dir>/uncovered.txt`, listing every formal-coverage item that was missed (with source location and expression). Use it to find the *class* of logic the assertions miss. |
| `summarize.py` | master | Rewrites `RESULTS.md`: mean / min per iteration and design. |

You may also read the slave's checker, the jg logs, and the RTL, and you
may edit a **copy** of a slave's checker in your scratchpad to test a
hypothesis (e.g. "does splitting this hold assertion change coverage?").
Findings from such experiments may only enter the prompt as generic rules.

## Loop

Run N = 5 iterations. In iteration `i`:

1. For each tuning design `d` and each `k` in 1..K (K = 2):
   `ws=$(common/prepare.sh d i k)`.
2. Spawn one `haiku` agent per workspace (they may run in parallel), with
   exactly this message:
   > Read `<abs path>/SLAVE_PROMPT.md` and follow it. Your workspace
   > directory is `<ws>`. The syntax checker is
   > `<abs path>/common/syntax_check.sh`.
3. When all agents are done, run `common/eval.sh d i k` for every run. Run
   them **sequentially** unless you have checked that parallel jg licenses
   are available.
4. Run `common/summarize.py`.
5. Write `results/iter<i>/notes.md`: the failure classes you saw (with
   evidence: assert names, uncovered items), the change you are making to
   the prompt, and why it is generic.
6. Edit `SLAVE_PROMPT.md`. Do not edit it while agents of the current
   iteration are running; `eval.sh` snapshots it into
   `results/iter<i>/`.

Stop early if every tuning design is at 100% for metrics 1–3 and
≥ 99% of achievable formal coverage in the min over K runs for two
consecutive iterations. Then spend the remaining effort on making the
prompt shorter and clearer without losing score.

**Final step:** if held-out designs exist, run the final prompt on them
(K runs each) and report their scores separately.

## Deliverables

- `SLAVE_PROMPT.md`: the final prompt.
- `RESULTS.md`: the table from `summarize.py`.
- `results/iter*/notes.md`: per-iteration reasoning.
- A short final summary: the score trajectory, what changed in each
  iteration, and any limitations (e.g. metric artifacts you could not
  resolve).

## Housekeeping

- `work/` is scratch (git-ignored). Delete it at the end if it is large.
- `results/run0/` holds the earlier 5-iteration run on `sockit_owm` (before
  this structure existed). Its final prompt is the current `SLAVE_PROMPT.md`.
- Don't commit unless asked.
