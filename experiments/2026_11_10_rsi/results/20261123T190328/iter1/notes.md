# Iteration 1 notes

## Evaluation changes made during this iteration (user-directed)

- `designs/sockit_owm/sockit_owm.tcl`: `check_cov -init -type coi` (was
  mutation), `prove -all -per_property_time_limit 30s -time_limit 2m`, and
  `check_cov -measure -time_limit 2m`. The user asked for a much faster
  evaluation. Backups are `<run>/.sockit_owm.tcl.before_proofcore` and
  `<run>/.metrics.py.before`.
- `common/metrics.py`: excludes only stimuli-proven unreachable/dead items
  from the formal denominator (the user's edit).
- Consequence: COI coverage saturates at 298/299 for both runs, even though
  30–35% of their asserts are false. Until something finer is used, metric 3
  has almost no resolution, and metrics 1 and 2 drive the loop.

## Failure classes (see AUTOPSY.md)

- Bug hunting / known-false assertions (run1): a_cnt_idle_hold,
  a_dat_hold_idle, a_irq_only_end, a_no_drive_cyc0, a_e_mirror_oen,
  a_sample_slot, a_sample_presence.
- Blackboxed `*` in checker functions (run2): a_cyc_len, a_cyc_line,
  a_cyc_end_irq, a_cyc_end_bus_irq, a_cyc_dat_latch, a_pri_end_rd.
- Divider register taken as its reset value (run2): a_cyc_busy_noirq,
  a_cyc_dat_hold.
- Undetermined, with a 26-bit modelling counter and runtime product (run1):
  a_cyc_hold, a_cyc_end, a_oen_hold, a_oen_release.
- Vacuous, `rst |-> ...` (run1): a_rst_regs, a_rst_outs, a_rst_cdr.
- Missed coverage: only the `bus_wen_pwr_sel` toggle, which has no reader for
  OWN=1.

## Transcription estimate

Sample: all 33 (run1) and all 29 (run2) asserts.

- run1: about 8/33 (24%). Examples: `a_irq_wr_clr: ctl_wr |=> !irq_sts`
  restates `if (bus_wen_ctl_sts) irq_sts <= 0`, and `a_pwr_out: ctl_wr |=>
  owr_p[0] == $past(bus_wdt[4])` restates the `owr_pwr` update. Its helper
  wires also copy the RTL (`pls`, `end_ev`, `t_rstp`, `t_bits`, ...), so
  `a_sample_*` restate the `owr_smp` update.
- run2: about 5/29 (17%). Examples: `a_nostart_nocyc`, `a_pwr_out`, and
  `a_rb_cyc` (which copies `bus_wdt[3] & ~&bus_wdt[2:0]`). Its cycle tracker
  derives timing from documented durations instead of copying the counter, so
  it is not transcription.

## Documentation vs RTL

- Split: run1 has about 22 doc-sourced and 11 RTL-sourced asserts; run2 about
  24 and 5.
- Genuine conflicts behind a CEX (not prompt failures):
  - With overdrive and a divider ratio of 0, the counter runs while idle, so
    irq is set and dat reloaded outside any cycle (a_irq_only_end,
    a_dat_hold_idle). Doc 4.4 says this only happens at the end of a cycle.
  - A control write with cyc=0 still drives the line (a_no_drive_cyc0).
    Doc 4.4 says cyc=0 means "no action".
  - With OWN=1, `owr_sel` is set only by an `initial` block, so the line
    select is free in formal. Doc 2.1.2 says select is ignored for OWN=1. This
    is a tool/RTL artifact rather than a pure doc conflict.

## Compliance

- User covers: none in either run.
- Assumes: run1 wrote `asm_cdr_idle` and quoted doc 4.2 for it (allowed).
- Timing-heavy properties: both runs check exact cycle durations through
  checker-side trackers. The current optimizer prompt no longer forbids this.

## Did the change have the expected effect?

The baseline prediction was "mostly proven; failures around counter/pulse
timing and unreset registers". Partly right. The dominant failures were
instead bug hunting (run1) and a tool artifact, blackboxed multiplication
(run2). Proven is 69.5% mean / 66.7% min.
