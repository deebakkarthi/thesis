# RSI: a general-purpose SVA generation prompt

Your goal is to produce `GENERATOR_PROMPT.md`: a prompt that makes a `haiku`
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

## Hard constraints on `GENERATOR_PROMPT.md`

1. **Generic.** It must work verbatim on an unseen design. It must not
   contain anything taken from a specific design: no module, signal or
   parameter names, no parameter values, no line numbers, no
   design-specific file names, and no assertions written for a particular
   design. Test: if you pasted the prompt next to a different RTL, every
   sentence must still make sense. You may add rules for *classes* of
   mistakes you observed (e.g. "registers that are never assigned are free
   in formal; never assert their value").
2. **The generator knows nothing about evaluation.** It must not see the
   metrics, and it must not know that metrics, scores or an evaluation
   exist. Neither `GENERATOR_PROMPT.md` nor the invocation message may mention
   grading, scores, metrics, percentages, "proven/covered" rates, formal or
   mutation coverage, JasperGold evaluation runs, `check_cov`, or that its
   output will be measured or compared. Phrase every quality goal as plain
   engineering practice, e.g. "every assertion must hold for all legal
   input sequences", "each cover must describe a reachable scenario",
   "together the properties should specify all of the design's observable
   behaviour". Never copy text from this file, `RESULTS.md` or
   `results/` into the prompt. The isolation is enforced as follows:
   - The generator works in a workspace under `/tmp`, outside this experiment
     tree. Never mention or pass it any path inside this directory.
   - The workspace contains only `rtl/`, `<top>.f`, a setup-only
     `<top>.tcl` (analyze/elaborate/clock/reset, with every proof,
     coverage and report command stripped), `check_syntax.sh` (compile
     only) and `TASK.md` (a copy of `GENERATOR_PROMPT.md`).
   - The generator never runs proofs. The only tool it may run is
     `./check_syntax.sh`.
3. **No verbatim RTL-to-SVA transcription.** An assertion that restates
   the implementation checks the code against itself, so it can never find
   a bug and it silently inherits every RTL bug. Two examples: copying an
   `assign` right-hand side (`y == (a & b)` for `assign y = a & b`), and
   turning `if (c) r <= e;` into `c |=> r == $past(e)` with the same
   expression structure. The prompt must steer the generator away from this
   and towards properties derived from the design's **intended
   behaviour**, as a designer or spec writer would state them. Examples:
   - interface and handshake protocols
   - register-map semantics (a write followed by a read returns the
     written value; reserved bits read as zero)
   - durations of timers and counters measured in cycles at the ports
   - legal FSM sequences, expressed through their observable effects
   - end-to-end relations between inputs and outputs
   - invariants, mutual exclusion and one-hot conditions
   - bounded liveness ("a request is answered within N cycles")

   Referencing internal signals is fine when they carry a meaningful
   concept (a state, a count, a mode), but the property must say something
   the RTL text does not already say literally. Formal coverage reached
   through transcription does not count: a prompt that scores well by
   transcribing has failed this constraint, whatever its numbers.
4. **Fixed interface.** The generator works in the workspace given in its
   invocation message. It must write `sva/<top>_sva.sv` (checker module
   plus `bind`) and `<top>_sva.f` (one line: `./sva/<top>_sva.sv`) there,
   and nothing else. The prompt must not hard-code any path.

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

5. **Transcription rate** (reviewed by you, not computed by a script): the
   fraction of user asserts that are verbatim restatements of RTL
   statements as defined in constraint 3. Sample at least 20 asserts per
   run, or all of them if there are fewer, and record the estimate in
   `notes.md`. It should go down over the iterations. Metric 4 only counts
   as progress if this stays low.

Expect a tension between metric 4 and constraint 3: transcription is the
cheapest way to pin every register. Resolve it with intent-level properties
that still constrain observable behaviour exactly (for example,
"after writing X to the register, reading it returns X until the next
write"), never by allowing transcription back in.

## Tools (all in `common/`)

| Script | Who | What it does |
|---|---|---|
| `prepare.sh <design> <iter> <k>` | optimizer | Creates an isolated workspace under `/tmp/$USER/sva_ws/` (see constraint 2) and prints its path. Also keeps a symlink `work/iter<iter>/<design>/run<k>` to it for `eval.sh`. Run it after the final edit of `GENERATOR_PROMPT.md` for the iteration, because it copies the prompt in as `TASK.md`. |
| `syntax_check.sh` | generator | Copied into each workspace as `check_syntax.sh`. Analyzes and elaborates only, then prints ERROR/WARN lines and `SYNTAX OK` or `SYNTAX FAIL`. |
| `eval.sh <design> <iter> <k>` | optimizer | Copies the workspace's output into `results/iter<iter>/<design>/run<k>/` with the frozen design files, runs JasperGold there (with timeout, `< /dev/null` and a private project dir, so there are no hangs or lock files), prints the metrics, and appends to `results/iter<iter>/summary.tsv`. Takes about 1 minute per run. |
| `metrics.py <run_dir>` | optimizer | Re-prints one run's metrics, listing every CEX, unreachable cover and vacuous assert by name. |
| `list_uncovered.sh <run_dir>` | optimizer | Re-runs the proof and writes `<run_dir>/uncovered.txt`, listing every formal-coverage item that was missed (with source location and expression). Use it to find the *class* of logic the assertions miss. |
| `summarize.py` | optimizer | Rewrites `RESULTS.md`: mean / min per iteration and design. |

You may also read the generator's checker, the jg logs, and the RTL, and you
may edit a **copy** of a generator's checker in your scratchpad to test a
hypothesis (e.g. "does splitting this hold assertion change coverage?").
Findings from such experiments may only enter the prompt as generic rules.

## Loop

Run N = 5 iterations. In iteration `i`:

1. For each tuning design `d` and each `k` in 1..K (K = 2):
   `ws=$(common/prepare.sh d i k)`.
2. Spawn one `haiku` agent per workspace (they may run in parallel), with
   exactly this message and nothing more:
   > Your workspace is `<ws>`. Read `<ws>/TASK.md` and follow it.
3. When all agents are done, run `common/eval.sh d i k` for every run. Run
   them **sequentially** unless you have checked that parallel jg licenses
   are available.
4. Run `common/summarize.py`.
5. Write `results/iter<i>/notes.md` covering:
   - the failure classes you saw, with evidence (assert names, uncovered
     items)
   - the transcription-rate estimate, with 2–3 example asserts
   - the change you are making to the prompt, and why it is generic and
     reveals nothing about evaluation.
6. Edit `GENERATOR_PROMPT.md`. Do not edit it while agents of the current
   iteration are running; `eval.sh` snapshots it into
   `results/iter<i>/`.

Stop early if every tuning design is at 100% for metrics 1–3 and
≥ 99% of achievable formal coverage in the min over K runs for two
consecutive iterations. Then spend the remaining effort on making the
prompt shorter and clearer without losing score.

**Final step:** if held-out designs exist, run the final prompt on them
(K runs each) and report their scores separately.

## Deliverables

- `GENERATOR_PROMPT.md`: the final prompt.
- `RESULTS.md`: the table from `summarize.py`.
- `results/iter*/notes.md`: per-iteration reasoning.
- A short final summary: the score trajectory, what changed in each
  iteration, and any limitations (e.g. metric artifacts you could not
  resolve).

## Housekeeping

- `work/` is scratch (git-ignored). Delete it at the end if it is large.
- `results/run0/` holds the earlier 5-iteration run on `sockit_owm` (before
  this structure existed). Its final prompt is the current `GENERATOR_PROMPT.md`.
  That prompt **violates constraints 2 and 3**: it tells the generator about
  the metrics and explicitly asks for one assertion per RTL branch. Rewrite
  it before iteration 1. You may keep its generic correctness lessons:
  undriven or unreset registers are free, wrap-around, the `$past`
  alignment of `|=>`, reset handling, and checking syntax only. Expect
  formal coverage to drop at first compared with run0. That is the cost of
  removing transcription, not a regression.
- Delete stale workspaces in `/tmp/$USER/sva_ws/` at the end.
- Don't commit unless asked.
