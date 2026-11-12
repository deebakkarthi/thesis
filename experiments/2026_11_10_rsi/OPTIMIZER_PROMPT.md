# RSI: a general-purpose SVA generation prompt

Your goal is to produce a generator prompt: a prompt that makes a `haiku`
agent write high-quality SystemVerilog Assertions for **any** RTL design. You
tune it by running it on the designs in `designs/` and reading the metrics.
The prompt is judged by how it performs on designs it has never seen.

Paths below are relative to this directory
(`experiments/2026_11_10_rsi`).

**This run is non-interactive.** No user input will be provided. Never ask
a question or wait for confirmation; make every decision yourself and
record it in the run's notes.

**This run is independent.** First run `common/new_run.sh`. It creates a
fresh, timestamped directory `results/<timestamp>/` and prints its
absolute path, called `<run>` below. Everything this run produces lives in
`<run>`: the working prompt `<run>/GENERATOR_PROMPT.md`, the iteration
folders `<run>/iter<i>/`, `<run>/RESULTS.md` and the scratch symlinks
`<run>/work/`. Every script in `common/` except `new_run.sh` takes `<run>`
as its first argument. Shell variables do not persist between commands,
so write the literal path into every call.

Do not read, reuse, modify or delete anything outside `<run>` that another
optimizer run left behind: other directories under `results/`, any
top-level `GENERATOR_PROMPT.md`, `RESULTS.md` or `work/`, and workspaces
under `/tmp/$USER/sva_ws/` you did not create.

## Designs

Each design lives in `designs/<name>/` and contains `rtl/`, `<name>.f` (RTL
filelist), `<name>.tcl` (the frozen JasperGold evaluation script) and the
design's documentation (e.g. a PDF datasheet; its file name need not match
`<name>`). The top module may not be `<name>`. Never edit anything in `designs/`.

## Hard constraints on `<run>/GENERATOR_PROMPT.md`

1. **Generic.** It must work verbatim on an unseen design. It must not
   contain anything taken from a specific design: no module, signal or
   parameter names, no parameter values, no line numbers, no
   design-specific file names, and no assertions written for a particular
   design, and no facts taken from a specific design's documentation.
   Test: if you pasted the prompt next to a different RTL and its
   documentation, every sentence must still make sense. You may add rules
   for *classes* of mistakes you observed (e.g. "registers that are never
   assigned are free in formal; never assert their value").
2. **The generator knows nothing about evaluation.** It must not see the
   metrics, and it must not know that metrics, scores or an evaluation
   exist. Neither `GENERATOR_PROMPT.md` nor the invocation message may mention
   grading, scores, metrics, percentages, "proven/covered" rates, formal or
   mutation coverage, JasperGold evaluation runs, `check_cov`, or that its
   output will be measured or compared. Phrase every quality goal as plain
   engineering practice, e.g. "every assertion must hold for all legal
   input sequences", "every assertion's condition must be reachable",
   "together the properties should specify all of the design's observable
   behaviour". Never copy text from this file, `RESULTS.md` or anything
   under `results/` into the prompt. The isolation is enforced as follows:
   - The generator works in a workspace under `/tmp`, outside this experiment
     tree. Never mention or pass it any path inside this directory.
   - The workspace contains only `rtl/`, `doc/` (the design's
     documentation), `<top>.f`, a setup-only `<top>.tcl`
     (analyze/elaborate/clock/reset, with every proof, coverage and report
     command stripped), `check_syntax.sh` (compile only) and `TASK.md` (a
     copy of `<run>/GENERATOR_PROMPT.md`).
   - The generator never runs proofs. The only tool it may run is
     `./check_syntax.sh`.
3. **Two sources, two levels, no verbatim transcription.** The generator
   is not hunting for bugs. It writes assertions that it believes are true
   of the design, drawn from two sources:
   - **Documentation → high-level assertions.** The documentation is the
     golden truth about what the design does. Take from it the
     architectural behaviour: register-map semantics (a write followed by a
     read returns the written value; reserved bits read as zero; reset
     values), interface and handshake protocols, the effects of control
     and status bits, end-to-end relations between inputs and outputs,
     legal mode and state sequences through their observable effects.
   - **RTL → low-level, designer-intent assertions.** Use the RTL for what
     the designer evidently intended at the implementation level and the
     documentation does not spell out: invariants on internal state, legal
     ranges of counters and state registers, mutual exclusion and one-hot
     conditions, relations between internal signals that carry a meaning
     (a state, a count, a mode), and how internal registers map to what
     the documentation describes.

   When the two disagree, the documentation wins. Record such conflicts in
   `notes.md`; do not tune the prompt to make the generator distrust the
   documentation.

   Low-level assertions must still not be verbatim transcriptions of RTL
   statements. Such an assertion only restates the code. Two examples:
   copying an `assign` right-hand side (`y == (a & b)` for
   `assign y = a & b`), and turning `if (c) r <= e;` into
   `c |=> r == $past(e)` with the same expression structure. A low-level
   property must say something the RTL text does not already say literally.
   Formal coverage reached through transcription does not count: a prompt
   that scores well by transcribing has failed this constraint, whatever
   its numbers.

   **No timing-heavy properties.** The prompt must not ask for, or steer
   the generator towards, cycle-accurate timing: durations measured in
   cycles, "exactly N cycles after", bounded liveness with a computed N,
   checker-local cycle counters, or reference models that track time. Such
   properties are very hard to get right from the RTL alone. The generator
   may still write a timing property when the documentation states the
   timing explicitly, but the prompt must not push for one.

   **No covers.** The generator writes no `cover property` statements. The
   formal tool generates the covers it needs (e.g. precondition covers for
   every assertion), so user covers are extraneous. The prompt must tell
   the generator not to write any.
4. **Fixed interface.** The generator works in the workspace given in its
   invocation message. It must write `sva/<top>_sva.sv` (checker module
   plus `bind`) and `<top>_sva.f` (one line: `./sva/<top>_sva.sv`) there,
   and nothing else. The prompt must not hard-code any path.
5. **Traceable reasoning.** The autopsy (see Loop) depends on being able
   to see why the generator wrote each assertion, and its thinking blocks
   may be stored without text. So the prompt must ask the generator, as
   plain engineering practice, to:
   - give every assertion a short comment naming its source (the
     documentation section or the RTL construct it comes from) and why it
     holds, and
   - state its reasoning in plain text messages as it works, in particular
     whenever it weakens, rewrites or deletes an assertion and why.

   Do not tell it that this reasoning will be read or reviewed.

## Metrics (in priority order)

`common/metrics.py` prints these for each run; `common/summarize.py`
aggregates them.

1. **proven %** = proven / user asserts. Must be 100%: a false or
   undetermined assert is the worst outcome. Exception: a CEX caused by a
   genuine conflict between documentation and RTL (constraint 3) is
   recorded in `notes.md` as such, not treated as a prompt failure.
2. **non-vacuous %** = asserts whose antecedent is reachable (the tool's
   `:precondition` covers). Should be 100%; a vacuous assert proves nothing.
3. **formal % of achievable** = covered_and_checked /
   (total − unreachable_or_undetectable) of the top instance's
   `formal_coverage_local` (mutation coverage). Maximise this once 1–2 are
   at 100%. The raw % is printed too, but items the tool marks
   unreachable/undetectable (e.g. reset branches, undriven signals) cannot
   be reached by any assertion, so don't chase them.

`metrics.py` also prints a **covered %** for user-written covers. Since the
generator writes none, it reads `0/0` (nan). Any user cover that appears
is a prompt-compliance failure: note it.

Do not inflate metric 1 by asking for fewer or trivial assertions: a
prompt that loses formal coverage to gain proven % is worse.

4. **Transcription rate** (reviewed by you, not computed by a script): the
   fraction of user asserts that are verbatim restatements of RTL
   statements as defined in constraint 3. Sample at least 20 asserts per
   run, or all of them if there are fewer, and record the estimate in
   `notes.md`. It should go down over the iterations. Metric 3 only counts
   as progress if this stays low.

Expect a tension between metric 3 and constraint 3: transcription is the
cheapest way to pin every register. Resolve it with documentation-level
properties that still constrain observable behaviour exactly (for example,
"after writing X to the register, reading it returns X until the next
write") and with RTL-level invariants, never by allowing transcription back
in and never by pushing for timing-heavy properties.

## Tools (all in `common/`)

| Script | Who | What it does |
|---|---|---|
| `new_run.sh` | optimizer | Creates `results/<timestamp>/` for this run and prints its absolute path (`<run>`). Run it once, first. |
| `prepare.sh <run> <design> <iter> <k>` | optimizer | Creates an isolated workspace under `/tmp/$USER/sva_ws/` (see constraint 2), copying the design's documentation into `doc/`, and prints its path. Also keeps a symlink `<run>/work/iter<iter>/<design>/run<k>` to it for `eval.sh`. Run it after the final edit of `<run>/GENERATOR_PROMPT.md` for the iteration, because it copies that prompt in as `TASK.md`. |
| `syntax_check.sh` | generator | Copied into each workspace as `check_syntax.sh`. Analyzes and elaborates only, then prints ERROR/WARN lines and `SYNTAX OK` or `SYNTAX FAIL`. |
| `eval.sh <run> <design> <iter> <k>` | optimizer | Copies the workspace's output (and the `TASK.md` it was given) into `<run>/iter<iter>/<design>/run<k>/` with the frozen design files, runs JasperGold there (with timeout, `< /dev/null` and a private project dir, so there are no hangs or lock files), prints the metrics, and appends to `<run>/iter<iter>/summary.tsv`. Takes about 1 minute per run. |
| `metrics.py <run_dir>` | optimizer | Re-prints one run's metrics, listing every CEX, unreachable cover and vacuous assert by name. |
| `list_uncovered.sh <run_dir>` | optimizer | Re-runs the proof and writes `<run_dir>/uncovered.txt`, listing every formal-coverage item that was missed (with source location and expression). Use it to find the *class* of logic the assertions miss. |
| `summarize.py <run>` | optimizer | Rewrites `<run>/RESULTS.md`: mean / min per iteration and design. |
| `trace.py <transcript> <out.md>` | optimizer | Converts a generator agent's JSONL transcript (the `output_file` reported when the agent is spawned) into a readable Markdown trace: text messages, thinking (when stored), every tool call in order (each Write/Edit of the checker in full), and truncated tool results. Never read the raw transcript directly; it is too large. |
| `prompt_patch.sh <run> <iter>` | optimizer | Snapshots `<run>/GENERATOR_PROMPT.md` into `<run>/iter<iter>/` and writes `GENERATOR_PROMPT.patch`, a unified diff against the previous iteration's prompt in this run (for iteration 1, against an empty file). |

You may also read the generator's checker, the jg logs, and the RTL, and you
may edit a **copy** of a generator's checker in your scratchpad to test a
hypothesis (e.g. "does splitting this hold assertion change coverage?").
Findings from such experiments may only enter the prompt as generic rules.

## Loop

Run N = 5 iterations. Each iteration opens with one prompt change and then
measures it. In iteration `i`:

1. **Change the prompt.** Edit `<run>/GENERATOR_PROMPT.md`. For `i = 1`,
   create it from scratch, following the hard constraints above. For
   `i > 1` the change must follow from the root causes in
   `<run>/iter<i-1>/AUTOPSY.md`: target the highest-impact prompt-caused
   root cause, and use `notes.md` for the supporting metrics. A change that
   no autopsy root cause motivates is not allowed.
2. **Record the change.** Run `common/prompt_patch.sh <run> i`, then write
   `<run>/iter<i>/CHANGE_MESSAGE.md` (format below). Do not touch the
   prompt again until the iteration's runs are evaluated.
3. For each tuning design `d` and each `k` in 1..K (K = 2):
   `common/prepare.sh <run> d i k` (prints the workspace path `<ws>`).
4. Spawn one `haiku` agent per workspace (they may run in parallel), with
   exactly this message and nothing more:
   > Your workspace is `<ws>`. Read `<ws>/TASK.md` and follow it.

   Write down the transcript path (`output_file`) reported for each agent,
   keyed by design and `k`.
5. When all agents are done, run `common/eval.sh <run> d i k` for every
   run. Run them **sequentially** unless you have checked that parallel jg
   licenses are available. Then, for every run, extract its trace:
   `common/trace.py <transcript> <run>/iter<i>/d/run<k>/trace.md`.
   For each run with a CEX, a vacuous assert or missed formal-coverage
   items, also run `common/list_uncovered.sh <run>/iter<i>/d/run<k>`.
6. Run `common/summarize.py <run>`.
7. **Autopsy.** Write `<run>/iter<i>/AUTOPSY.md`. Read each run's
   `trace.md` and checker, and for every failure explain *why the generator
   made that mistake*, not just what the mistake is. Failures are:
   - every CEX and undetermined assert,
   - every vacuous assert,
   - every user cover or timing-heavy property (compliance failures),
   - every transcribed assert found in your sample,
   - each *class* of missed formal-coverage items (group the
     `uncovered.txt` entries by the logic they belong to, e.g. "status
     register clear paths", "internal data path with no port visibility").

   For each failure, find the point in the trace where the generator made
   the decision: the step that first wrote the assertion, the edit that
   changed it, or, for missed coverage, the absence of any assertion on
   that logic. Quote the relevant text or code from the trace. Then give:
   - **What happened**: the assertion (or missing assertion) and the tool
     result (the CEX trace in `jg.log`, the uncovered items).
   - **Generator's reasoning**: what the generator believed, from its text
     messages, assertion comments and the order of its edits. Say so when
     the trace does not reveal it, instead of guessing.
   - **Root cause**, in one of these categories:
     prompt instruction misled it (quote the instruction); prompt silent
     on this class of situation; generator ignored a prompt rule (quote the
     rule); misread the documentation; misread the RTL; wrong SVA
     semantics (`$past` alignment, widths, implication); overlooked
     environment freedom (unconstrained inputs, interfering bus access,
     free registers); documentation/RTL conflict (not a prompt failure);
     never considered that logic; considered it and dropped it (say why).
   - **Prompt-level fix**: the generic rule or wording change that would
     have prevented it, or "none" if the cause is not in the prompt's reach.

   End with a ranked list of root causes across all runs, by number of
   failures and their impact on the metrics, and recurring patterns
   compared with earlier autopsies in this run. This ranking determines
   the next iteration's change.
8. Write `<run>/iter<i>/notes.md` covering:
   - the failure classes you saw, with evidence (assert names, uncovered
     items)
   - the transcription-rate estimate, with 2–3 example asserts
   - the split between documentation-level and RTL-level asserts, and any
     documentation/RTL conflicts behind a CEX
   - any user covers or timing-heavy properties that appeared
   - whether the change described in this iteration's
     `CHANGE_MESSAGE.md` had the expected effect.

   Fill in the Result section of `CHANGE_MESSAGE.md`. The autopsy and
   these notes are the evidence for the next iteration's change.

### Change messages

Every prompt change is delivered as a pair of files in the iteration's
results folder: the patch (`GENERATOR_PROMPT.patch`, made by
`prompt_patch.sh`) and `CHANGE_MESSAGE.md`. Write the message the way a
careful engineer writes a commit message or the description of a change
request for review. A reader who sees only the patch and the message should
understand what changed and why. This is purely a writing convention: do not
use git or any other version control, and do not run any git commands.

Format:

```
<Subject: imperative mood, at most 72 characters, says what the prompt now does>

Problem
  What went wrong in the previous iteration and why it matters. Name the
  root cause(s) from the previous `AUTOPSY.md` that this change addresses,
  with the trace quote that shows the generator's faulty reasoning. Cite
  evidence: metric values (mean/min), names of failing or vacuous asserts,
  classes of uncovered items, transcription examples. For iteration 1,
  describe the design of the initial prompt and how it meets the hard
  constraints.

Change
  - One bullet per logical edit to the prompt, matching the hunks of the
    patch, each saying why that edit addresses the problem.

Expected effect
  Which metrics should move and in which direction, and any risk (e.g.
  "may lower formal coverage on registers with no port-visible effect").

Constraint check
  One line each confirming that the change is generic (no design-specific
  content), reveals nothing about evaluation, and does not invite
  transcription.

Result (fill in after step 7)
  The measured outcome against the expected effect, in 1–3 lines.
```

Keep each change focused. If you want to make two unrelated changes,
explain both separately in the message, or better, spread them over two
iterations so each one's effect can be measured.

Stop early if every tuning design is at 100% for metrics 1–2 and
≥ 99% of achievable formal coverage in the min over K runs for two
consecutive iterations. Then spend the remaining effort on making the
prompt shorter and clearer without losing score.

**Final step:** if held-out designs exist, run the final prompt on them
(K runs each) and report their scores separately.

## Deliverables

All inside `<run>`:

- `GENERATOR_PROMPT.md`: the final prompt.
- `RESULTS.md`: the table from `summarize.py`.
- For each iteration, in `iter<i>/`: `GENERATOR_PROMPT.md`
  (snapshot), `GENERATOR_PROMPT.patch`, `CHANGE_MESSAGE.md` (with its
  Result section filled in), `AUTOPSY.md`, `notes.md`, `summary.tsv`, and
  the per-run folders (each holds the checker, the `TASK.md` it was given,
  `trace.md`, `jg.log`, the metrics JSON and, where produced,
  `uncovered.txt`).
- `SUMMARY.md`: a short final summary with the score trajectory, the
  subject line of each iteration's change message, and any limitations
  (e.g. metric artifacts you could not resolve). Print it at the end too.

## Housekeeping

- `<run>/work/` is scratch (symlinks to this run's workspaces). At the
  end, delete the workspaces in `/tmp/$USER/sva_ws/` that it points to,
  and no others, then delete `<run>/work/`.
- Do not commit or run any git command.
