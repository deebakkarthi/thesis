# Generator trace

source: /tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tasks/ae8e167232be12465.output

note: 5 thinking block(s) were stored without text.

### step 1: Bash

```
cat /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/TASK.md; echo ---; ls -la /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/
```

#### result

```
# Task: write a SystemVerilog Assertion checker for the RTL design in this workspace

You are a verification engineer. Write a set of SystemVerilog Assertions
(SVA) that specify the behaviour of the design in this workspace, as a
checker module bound to the design's top module.

You are not looking for bugs. You are writing a specification that this RTL
satisfies: every assertion you write must hold on the RTL exactly as it is.

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
edit, and fix every error until it prints `SYNTAX OK`. Then read every
warning that points into your checker file. A warning that an operator,
function or module was blackboxed, removed or left undriven means the tool
replaced it with an arbitrary value, so everything computed from it is
unconstrained: treat such a warning as an error and rewrite that logic.
In auxiliary logic, avoid `*`, `/` and `%` unless both operands are
constants.

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
RTL-level properties, 
... [8261 more chars]
```

### step 2: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL && cat check_syntax.sh sockit_owm.f sockit_owm.tcl && ls -la doc rtl && wc -l rtl/* && cat rtl/* | head -c 60000
```

### step 3: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL && ls doc && for f in doc/*; do case "$f" in *.pdf) pdftotext -layout "$f" - ;; *) cat "$f" ;; esac; done
```

#### result

```
#!/bin/bash
# Compile-only check: analyzes and elaborates the RTL together with the SVA
# checker in this directory, then exits.
# usage: ./check_syntax.sh [workspace_dir]   (default: the script's directory)
set -uo pipefail
ws=$(cd "${1:-$(dirname "$0")}" && pwd)
tcl=$(ls "$ws"/*.tcl | head -1)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# everything up to the elaborate line (analyze, optional SVA filelist, elaborate)
awk '{print} /^[[:space:]]*elaborate/{exit}' "$tcl" | grep -v '^[[:space:]]*check_cov' > "$tmp/syn.tcl"
echo "exit -force" >> "$tmp/syn.tcl"
cd "$ws"
timeout 300 jg -no_gui -proj "$tmp/proj" -tcl "$tmp/syn.tcl" < /dev/null > "$tmp/syn.log" 2>&1
grep -E "ERROR|\[WARN|WARNING" "$tmp/syn.log" | grep -v "^INFO" | sort -u | head -60
if grep -q "ERROR" "$tmp/syn.log"; then echo "SYNTAX FAIL"; exit 1; else echo "SYNTAX OK"; fi
./rtl/sockit_owm.v
clear -all


analyze -v2k -f sockit_owm.f

if { [file exists sockit_owm_sva.f] == 1 } {
	analyze -sv -f sockit_owm_sva.f
}

# Blackbox missing modules instead of erroring out
elaborate -bbox 1
clock clk
reset rst==1'b1





doc:
total 364
drwxr-xr-x 2 brg8ve users     28 Nov 23 19:59 .
drwx------ 4 brg8ve users    108 Nov 23 19:59 ..
-rw-r--r-- 1 brg8ve users 372000 Nov 23 19:59 sockit_owr.pdf

rtl:
total 20
drwxr-xr-x 2 brg8ve users    26 Nov 23 19:59 .
drwx------ 4 brg8ve users   108 Nov 23 19:59 ..
-r--r--r-- 1 brg8ve users 17641 Nov 23 19:59 sockit_owm.v
419 rtl/sockit_owm.v
//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  Minimalistic 1-wire (onewire) master with Avalon MM bus interface       //
//                                                                          //
//  Copyright (C) 2010  Iztok Jeras                                         //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  This RTL is free hardware: you can redistribute it and/or modify        //
//  it under the terms of the GNU Lesser General Public License             //
//  as published by the Free Software Foundation, either                    //
//  version 3 of the License, or (at your option) any later version.        //
//                                                                          //
//  This RTL is distributed in the hope that it will be useful,             //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this program.  If not, see <http:
... [16091 more chars]
```

#### result

```
<persisted-output>
Output too large (63.1KB). Full output saved to: /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/b1t5sh1gd.txt

Preview (first 2KB):
sockit_owr.pdf
                             sockit_owm
                       1-wire (onewire) master




Copyright (CC BY-SA 3.0) 2010-2011
Iztok Jeras


Project home pages:
https://github.com/jeras/sockit_owm
http://opencores.org/project,sockit_owm



                                          1
Table of Contents
1 Introduction......................................................................................................................................5
   1.1 1-wire protocol and devices......................................................................................................5
   1.2 Features.....................................................................................................................................5
   1.3 List of source files.....................................................................................................................5
2 Verilog module parameters and ports...............................................................................................6
   2.1 Parameters.................................................................................................................................6
      2.1.1 Optional functionality.......................................................................................................6
      2.1.2 Data bus width, number of wires and overdrive enable....................................................6
      2.1.3 Clock divider ratio and base time periods.........................................................................6
   2.2 Ports..........................................................................................................................................7
      2.2.1 CPU bus interface.............................................................................................................8
...
</persisted-output>
```

### step 4: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL && pdftotext -layout doc/sockit_owr.pdf /tmp/brg8ve/sva_ws/owr_doc.txt 2>/dev/null || pdftotext -layout doc/sockit_owr.pdf - > /dev/null; wc -l /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/b1t5sh1gd.txt; sed -n 1,400p /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/b1t5sh1gd.txt | sed 's/  */ /g'
```

#### result

```
1215 /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/b1t5sh1gd.txt
sockit_owr.pdf
 sockit_owm
 1-wire (onewire) master




Copyright (CC BY-SA 3.0) 2010-2011
Iztok Jeras


Project home pages:
https://github.com/jeras/sockit_owm
http://opencores.org/project,sockit_owm



 1
Table of Contents
1 Introduction......................................................................................................................................5
 1.1 1-wire protocol and devices......................................................................................................5
 1.2 Features.....................................................................................................................................5
 1.3 List of source files.....................................................................................................................5
2 Verilog module parameters and ports...............................................................................................6
 2.1 Parameters.................................................................................................................................6
 2.1.1 Optional functionality.......................................................................................................6
 2.1.2 Data bus width, number of wires and overdrive enable....................................................6
 2.1.3 Clock divider ratio and base time periods.........................................................................6
 2.2 Ports..........................................................................................................................................7
 2.2.1 CPU bus interface.............................................................................................................8
 2.2.2 1-wire interface.................................................................................................................8
 2.3 Metastability evaluation............................................................................................................9
3 Supported 1-wire functionality.......................................................................................................10
 3.1 RTL description......................................................................................................................10
 3.2 1-wire cycle timings................................................................................................................10
4 Processor interface..........................................................................................................................13
 4.1 Address space..........................................................................................................................13
 4.2 Clock dividers.......................................................
... [19825 more chars]
```

### step 5: Bash

```
sed -n 400,1215p /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/b1t5sh1gd.txt | sed 's/  */ /g' | grep -v '^\s*$' | head -520
```

#### result

```
tRSTL 480 640 48 80 min reset low
tRSTH 480 ∞ 48 ∞ min reset high (on newer devices this time is lower)
tRSTP 60 75 6 10 max reset presence detect
 +8.1 +1.3 (the extra delay is due to slow slave IO)
tDAT0 60 120 6 16 min data bit 0
tDAT1 5 15 1 2 min data bit 1
tDATS 15 2 max data sample
tREC 5 ∞ 2 ∞ min recovery
tDLY 1ms idle delay (not standard, about tRSTL+ tRSTH)
tRSTT 960 ∞ 69 0 reset pulse cycle (tRSTL+ tRSTH)
tDATT 61 121 7 17 read/write slot cycle (tDAT0+ tREC)
The exact timing of 1-wire cycles is provided as a table with 3 options for normal mode and 2
options for overdrive mode. For exact base time periods only typical values are provided, for range
base time periods minimum and maximum value are provided.
Table 7: Timing options
 normal mode times [μs] overdrive mode times [μs]
name "7.5" "5.0" "6.0" "1.0" "0.5"
timing N typ N typ N min max N typ N min max
base 1 7.5 1 5 1 6 7.5 1 1 1 0.5 0.66
tRSTL 64 480 96 480 80 480 600 48 48 96 48 64
tRSTH 64 480 96 480 80 480 600 48 48 96 48 64
tRSTP 10 75 15 75 10 60 75 10 10 15 7.5 10
tDAT0 8 60 12 60 10 60 75 6 6 12 6 8
tDAT1 1 7.5 1 5 1 6 7.5 1 1 2 1 1.33
tDATS 2 15 3 15 2 12 15 2 2 3 1.5 2
tREC 1 7.5 1 5 1 6 7.5 2 2 4 2 2.66
tDLY 128 960 200 1000 160 960 1200 96 96 192 96 128
The 7.5μs base time period option is also explained with timing diagrams.
The reset cycle is 128 base periods long. Reset low and high time each take 64 base periods. After
the rising edge on the wire a typical 1-wire slave would assert its presence after 4 base periods (min
2, max 8), and keep it asserted for 16 base periods (min 8, max 32). The presence status is sampled
 11
when most stable at 10 base periods after the reset rising edge.
 127... ...64 63... ...0
 tRSTT
 tRSTL tRSTH
 tRSTS
Drawing 4: Reset and presence timing diagram
The write '0' cycle is 9 base periods long. The wire is tight low for 8 base periods than released. The
recovery time is 1 base period.
 8 7 6 5 4 3 2 1 0
 tDATT
 tSLOT = tLOW0 tREC
Drawing 5: Write 0 timing diagram
The write '1' or read cycle is 9 base periods long. The wire is tight low for 1 base period than
released. A typical 1-wire slave would answer with '0' by holding the wire down for 4 base periods
(min 2, max 8) from the falling edge of the read command. Data is sampled at the most stable point
at 2 base periods from the falling edge. There is 1 base period at the end for recovery.
 8 7 6 5 4 3 2 1 0
 tDATT
 tSLOT tREC
 tLOW1
 tDATS
Drawing 7:
 6: Write 11,or
 read
 read
 timing
 timing
 diagram
 diagram
 12
4 Processor interface
The processor interface is described in three steps:
 1. address space
 2. clock dividers
 3. 1-wire line multiplexing and power enable functionality
 4. control/status register description
 5. driver access sequences (polling and interrupts)
The document is focused on describing the 32bit CPU interface. Some aspects of a 8bit interface are
mentioned, but many details are omitted.
4.1 Address space
The sockit_own module is designed to be accessible 
... [26293 more chars]
```

### assistant

Read the task, the RTL, and the datasheet. Next I'll write the checker, then run the syntax check.

### step 6: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL && mkdir -p sva && cat > sva/sockit_owm_sva.sv <<'EOF'
// SVA checker for sockit_owm (1-wire master), default parameters.
// Bound into the top module; port names match the design's signal names.
module sockit_owm_sva #(
  parameter BDW      = 32,
  parameter BAW      = 1,
  parameter OWN      = 1,
  parameter CDW      = 16,   // clock divider register width (BDW=32, CDR_E=1)
  parameter CDR_N    = 4,
  parameter CDR_O    = 0,
  parameter T_RSTH_N = 96,
  parameter T_RSTL_N = 96,
  parameter T_DAT0_N = 12,
  parameter T_DAT1_N = 1,
  parameter T_RCVR_N = 1,
  parameter T_IDLE_N = 200,
  parameter T_RSTH_O = 48,
  parameter T_RSTL_O = 48,
  parameter T_DAT0_O = 6,
  parameter T_DAT1_O = 1,
  parameter T_RCVR_O = 2
)(
  input                clk,
  input                rst,
  input                bus_wen,
  input                bus_ren,
  input  [BAW-1:0]     bus_adr,
  input  [BDW-1:0]     bus_wdt,
  input  [BDW-1:0]     bus_rdt,
  input                bus_irq,
  input  [OWN-1:0]     owr_p,
  input  [OWN-1:0]     owr_e,
  input  [OWN-1:0]     owr_pwr,
  input                owr_oen,
  input                owr_cyc,
  input                owr_ovd,
  input                owr_rst,
  input                owr_dat,
  input                irq_ena,
  input                irq_sts,
  input                pls,
  input  [CDW-1:0]     div,
  input  [CDW-1:0]     cdr_n,
  input  [CDW-1:0]     cdr_o
);

  localparam PW = 9;  // enough for the longest cycle (192 base periods)

  // ------------------------------------------------------------------------
  // Modelling state. Clocked and reset like the design. It records the
  // type of the last control write and counts base periods (pls) since it.
  // A cycle is restarted by every control write, so the state always refers
  // to the cycle that is currently in progress.
  // ------------------------------------------------------------------------

  // cycle length in base periods (1 base period = 1 pls), from the
  // datasheet Table 12 / Table 7 and the design parameters:
  //   write 0 / write 1 or read : T_DAT0 + T_RCVR
  //   reset and presence        : T_RSTL + T_RSTH
  //   timed idle (normal only)  : T_IDLE_N
  //   zero-time idle (ovd=1)    : no cycle is started, length 0
  function automatic [PW-1:0] cyc_len(input o, input r, input d);
    begin
      if (r && d)      cyc_len = o ? 9'd0 : T_IDLE_N;
      else if (r)      cyc_len = o ? (T_RSTL_O + T_RSTH_O) : (T_RSTL_N + T_RSTH_N);
      else             cyc_len = o ? (T_DAT0_O + T_RCVR_O) : (T_DAT0_N + T_RCVR_N);
    end
  endfunction

  reg          mrst, mdat, movd;  // rst, dat, ovd bits of the last control write
  reg [PW-1:0] lenm;              // length of the cycle started by that write
  reg [PW-1:0] pc;                // base periods elapsed in the current cycle

  always @(posedge clk or posedge rst)
    if (rst) begin
      mrst <= 1'b0;
      mdat <= 1'b0;
      movd <= 1'b0;
      lenm <= '0;
      pc   <= '0;
    end else if (bus_wen & ~bus_adr[0]) begin
      mrst <= bus_wdt[1];
      mdat <= bus_wdt[0];
      movd <= bus_wdt[2];
      lenm <= cyc_len(bus_wdt[2], bus_wdt[1], bus_wdt[0]);
      pc   <= '0;
    end else if (owr_cyc & pls) begin
      pc   <= pc + 1'b1;
    end

  // ------------------------------------------------------------------------
  // Derived conditions
  // ------------------------------------------------------------------------
  wire wr_ctl = bus_wen & ~bus_adr[0];                     // control register write
  wire wr_st  = wr_ctl & bus_wdt[3] & ~(&bus_wdt[2:0]);    // starts a 1-wire cycle
  wire wr_zt  = wr_ctl & bus_wdt[3] &  (&bus_wdt[2:0]);    // zero-time idle write
  wire last   = (pc + 1'b1 == lenm);                       // this pulse ends the cycle
  wire end_ev = owr_cyc & pls & last;                      // end-of-cycle event

  wire lw0 = ~mrst & ~mdat;   // write 0 cycle
  wire lw1 = ~mrst &  mdat;   // write 1 / read cycle
  wire lr  =  mrst & ~mdat;   // reset and presence cycle
  wire li  =  mrst &  mdat;   // timed idle cycle

  // release points (in base periods) for the cycle mode in progress
  wire [PW-1:0] T0 = movd ? T_DAT0_O : T_DAT0_N;  // write 0 low time
  wire [PW-1:0] T1 = movd ? T_DAT1_O : T_DAT1_N;  // write 1 low time
  wire [PW-1:0] TL = movd ? T_RSTL_O : T_RSTL_N;  // reset low time

  // ------------------------------------------------------------------------
  // Reset values
  // The reset is asynchronous, so the value is visible in the cycle after rst
  // is sampled high. The check is written as rst |=> ... with the default
  // disable iff turned off, because the default would disable it.
  // ------------------------------------------------------------------------

  // Source: datasheet Table 10 (reset 0 for ien, irq, pwr, cyc, ovd, rst);
  // Table 8/Sec 4.2 (cdr_n, cdr_o reset to the CDR_N / CDR_O parameters).
  // Holds because all these registers have an asynchronous reset.
  a_rst_cdr: assert property (disable iff (1'b0)
    rst |=> (cdr_n == CDR_N) && (cdr_o == CDR_O));

  // Source: datasheet Table 10 and Sec 4.3 (lines released after reset).
  // Holds because these registers have an asynchronous reset to 0.
  a_rst_ctl: assert property (disable iff (1'b0)
    rst |=> (owr_pwr == 0) && !owr_ovd && !owr_rst && !owr_cyc && !owr_oen &&
            !irq_ena && !irq_sts);

  // ------------------------------------------------------------------------
  // Register read-back
  // ------------------------------------------------------------------------

  // Source: Datasheet Table 11 (bits 7 ien, 4 pwr, 2 ovd, 1 rst) and Table 10.
  // A control write followed by a control read returns the written bits,
  // because these bits change only on a control write.
  a_rb_ctl: assert property (
    (bus_wen & ~bus_adr[0]) ##1 (bus_ren & ~bus_adr[0]) |->
      (bus_rdt[7] == $past(bus_wdt[7])) && (bus_rdt[4] == $past(bus_wdt[4])) &&
      (bus_rdt[2] == $past(bus_wdt[2])) && (bus_rdt[1] == $past(bus_wdt[1])));

  // Source: Datasheet Table 8 (address 1 holds cdr_o[31:16], cdr_n[15:0]) and
  // Sec 4.2. A write to address 1 is read back unchanged on the next cycle.
  a_rb_cdr: assert property (
    (bus_wen & bus_adr[0]) ##1 (bus_ren & bus_adr[0]) |-> bus_rdt == $past(bus_wdt));

  // ------------------------------------------------------------------------
  // Interrupt
  // ------------------------------------------------------------------------

  // Source: Datasheet Table 11 bit 6 and Sec 2.2.1 (status cleared by a read).
  // A control read that is not coincident with a base period end clears irq.
  a_irq_rd_clr: assert property (
    (bus_ren & ~bus_adr[0] & ~pls) |=> ~irq_sts);

  // Source: Datasheet Table 11 bit 6 (status is held until read) and the
  // irq logic in the RTL (only a control read or write clears it).
  a_irq_hold: assert property (
    (irq_sts & ~wr_ctl & ~(bus_ren & ~bus_adr[0])) |=> irq_sts);

  // Source: RTL interrupt logic: a control write has priority and clears irq.
  a_irq_wr_clr: assert property (wr_ctl |=> ~irq_sts);

  // Source: Datasheet Table 11 bit 6 ("set on end of 1-wire cycle").
  // The end event is the last base period of a cycle in progress.
  a_irq_set: assert property ((end_ev & ~wr_ctl) |=> irq_sts);

  // Source: Datasheet Table 11 bit 7 (ien enables the interrupt request).
  // The request appears on bus_irq one cycle after the end of an enabled cycle.
  a_irq_out: assert property ((end_ev & ~wr_ctl & irq_ena) |=> bus_irq);

  // ------------------------------------------------------------------------
  // Power output
  // ------------------------------------------------------------------------

  // Source: Datasheet Sec 4.3 ("pwr" drives owr_p[0] when OWN=1) and Table 11 bit 4.
  a_pwr_set: assert property ((wr_ctl & bus_wdt[4]) |=> owr_p[0]);
  a_pwr_clr: assert property ((wr_ctl & ~bus_wdt[4]) |=> ~owr_p[0]);

  // Source: Datasheet Sec 4.3 (power register only written by control write).
  // owr_p changes only on a control write.
  a_pwr_hold: assert property (~wr_ctl |=> $stable(owr_p));

  // ------------------------------------------------------------------------
  // 1-wire line driver
  // owr_e = owr_oen << owr_sel, and owr_sel is never driven when OWN=1, so
  // only the relation to owr_oen is specified here.
  // ------------------------------------------------------------------------

  // Source: Datasheet Sec 2.2.2 (owr_e is the pull-down enable) and RTL IO
  // section (owr_e = owr_oen shifted by owr_sel, one bit wide).
  a_e_gated: assert property (owr_e |-> owr_oen);

  // ------------------------------------------------------------------------
  // Cycle start, zero-time idle, abort, length
  // ------------------------------------------------------------------------

  // Source: Datasheet Table 11 bit 3 (cyc=1 starts a cycle, cyc reads status).
  a_cyc_start: assert property (wr_st |=> owr_cyc);

  // Source: Datasheet Table 12 row "1 1 1 0us zero time idle cycle".
  a_cyc_zero: assert property (wr_zt |=> ~owr_cyc);

  // Source: RTL control logic: a control write with cyc=0 clears owr_cyc.
  a_cyc_abort: assert property ((wr_ctl & ~bus_wdt[3]) |=> ~owr_cyc);

  // Source: Datasheet Table 12 durations (in base periods, Table 7). The cycle
  // ends on its last base period.
  a_cyc_end: assert property ((owr_cyc & pls & last & ~wr_ctl) |=> ~owr_cyc);

  // Source: Datasheet Table 12 durations. The cycle continues until its last
  // base period; it only changes on a pulse or a control write.
  a_cyc_hold: assert property ((owr_cyc & ~(pls & last) & ~wr_ctl) |=> owr_cyc);

  // ------------------------------------------------------------------------
  // Line driving per cycle type
  // ------------------------------------------------------------------------

  // Source: Datasheet Drawing 5 and Table 7 (write 0: line low for tDAT0 base
  // periods, then released). owr_oen is set by the write and cleared at the
  // base period T0, and it stays cleared until the cycle ends.
  a_w0_drive: assert property ((wr_st & ~bus_wdt[1] & ~bus_wdt[0]) |=> owr_oen);
  a_w0_hold: assert property ((owr_cyc & lw0 & ~wr_ctl & (pc < T0) &
                               ~(pls & (pc + 1'b1 == T0))) |=> owr_oen);
  a_w0_rel: assert property ((owr_cyc & lw0 & ~wr_ctl & pls & (pc + 1'b1 == T0))
                             |=> ~owr_oen);
  a_w0_after: assert property ((owr_cyc & lw0 & ~wr_ctl & (pc >= T0)) |=> ~owr_oen);

  // Source: Datasheet Drawing 6 and Table 7 (write 1 / read: line low for tDAT1
  // base periods, then released).
  a_w1_drive: assert property ((wr_st & ~bus_wdt[1] & bus_wdt[0]) |=> owr_oen);
  a_w1_hold: assert property ((owr_cyc & lw1 & ~wr_ctl & (pc < T1) &
                               ~(pls & (pc + 1'b1 == T1))) |=> owr_oen);
  a_w1_rel: assert property ((owr_cyc & lw1 & ~wr_ctl & pls & (pc + 1'b1 == T1))
                             |=> ~owr_oen);
  a_w1_after: assert property ((owr_cyc & lw1 & ~wr_ctl & (pc >= T1)) |=> ~owr_oen);

  // Source: Datasheet Drawing 4 and Table 7 (reset: line low for tRSTL base
  // periods, then released for the rest of the cycle).
  a_r_drive: assert property ((wr_st & bus_wdt[1] & ~bus_wdt[0]) |=> owr_oen);
  a_r_hold: assert property ((owr_cyc & lr & ~wr_ctl & (pc < TL) &
                              ~(pls & (pc + 1'b1 == TL))) |=> owr_oen);
  a_r_rel: assert property ((owr_cyc & lr & ~wr_ctl & pls & (pc + 1'b1 == TL))
                            |=> ~owr_oen);
  a_r_after: assert property ((owr_cyc & lr & ~wr_ctl & (pc >= TL)) |=> ~owr_oen);

  // Source: Datasheet Table 12 row "1 0 1 timed idle" / Sec 4.5.1: an idle
  // cycle does not drive the line. owr_oen is set only by a control write
  // with a non-idle cycle, so it stays low during the idle cycle.
  a_idle_rel: assert property ((owr_cyc & li) |-> ~owr_oen);

  // ------------------------------------------------------------------------
  // Data bit (dat) and divider
  // ------------------------------------------------------------------------

  // Source: Datasheet Table 11 bit 0 ("write: data transmit request").
  a_dat_wr1: assert property ((wr_st & bus_wdt[0]) |=> owr_dat);
  a_dat_wr0: assert property ((wr_st & ~bus_wdt[0]) |=> ~owr_dat);

  // Source: RTL: owr_dat changes only on a control write or at the end of a
  // cycle (the sampled bit is stored at the end). It holds during a cycle.
  a_dat_hold: assert property ((owr_cyc & ~wr_ctl & ~end_ev) |=> $stable(owr_dat));

  // Source: RTL clock divider logic: any bus write restarts the base-period
  // divider.
  a_div_restart: assert property (bus_wen |=> (div == 0));

endmodule

bind sockit_owm sockit_owm_sva #(
  .BDW(BDW), .BAW(BAW), .OWN(OWN),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_DAT0_N(T_DAT0_N),
  .T_DAT1_N(T_DAT1_N), .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_DAT0_O(T_DAT0_O),
  .T_DAT1_O(T_DAT1_O), .T_RCVR_O(T_RCVR_O)
) u_sockit_owm_sva (.*);
EOF
echo './sva/sockit_owm_sva.sv' > sockit_owm_sva.f
./check_syntax.sh 2>&1 | tail -80
```

#### result

```
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./sva/sockit_owm_sva.sv(105): expression size 32 truncated to fit in target size 9
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./sva/sockit_owm_sva.sv(106): expression size 32 truncated to fit in target size 9
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./sva/sockit_owm_sva.sv(107): expression size 32 truncated to fit in target size 9
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./sva/sockit_owm_sva.sv(63): expression size 32 truncated to fit in target size 9
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./sva/sockit_owm_sva.sv(64): expression size 32 truncated to fit in target size 9
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./sva/sockit_owm_sva.sv(65): expression size 32 truncated to fit in target size 9
[WARN (VERI-1763)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./sva/sockit_owm_sva.sv(120): SVA directive is not sensitive to any clock. The directive will be sampled on the posedge of the fastest clock.
[WARN (VERI-1763)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./sva/sockit_owm_sva.sv(126): SVA directive is not sensitive to any clock. The directive will be sampled on the posedge of the fastest clock.
[WARN (VERI-1763)] /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL/./sva/soc
... [6670 more chars]
```

### assistant

The syntax check passes, but the warnings show two problems in my file. I never added the `default clocking` and `default disable iff` declarations, so the assertions currently have no clock and no reset masking. The integer-to-9-bit truncations in my own code also need sized casts. Fixing both now.

### step 7: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL && python3 - <<'EOF'
import re
p='sva/sockit_owm_sva.sv'
s=open(p).read()
s=s.replace("""  localparam PW = 9;  // enough for the longest cycle (192 base periods)
""","""  localparam PW = 9;  // enough for the longest cycle (192 base periods)

  default clocking @(posedge clk);
  endclocking
  default disable iff (rst);
""",1)
s=s.replace("""      if (r && d)      cyc_len = o ? 9'd0 : T_IDLE_N;
      else if (r)      cyc_len = o ? (T_RSTL_O + T_RSTH_O) : (T_RSTL_N + T_RSTH_N);
      else             cyc_len = o ? (T_DAT0_O + T_RCVR_O) : (T_DAT0_N + T_RCVR_N);""",
"""      if (r && d)      cyc_len = o ? '0 : PW'(T_IDLE_N);
      else if (r)      cyc_len = o ? PW'(T_RSTL_O + T_RSTH_O) : PW'(T_RSTL_N + T_RSTH_N);
      else             cyc_len = o ? PW'(T_DAT0_O + T_RCVR_O) : PW'(T_DAT0_N + T_RCVR_N);""",1)
s=s.replace("""  wire [PW-1:0] T0 = movd ? T_DAT0_O : T_DAT0_N;  // write 0 low time
  wire [PW-1:0] T1 = movd ? T_DAT1_O : T_DAT1_N;  // write 1 low time
  wire [PW-1:0] TL = movd ? T_RSTL_O : T_RSTL_N;  // reset low time""",
"""  wire [PW-1:0] T0 = movd ? PW'(T_DAT0_O) : PW'(T_DAT0_N);  // write 0 low time
  wire [PW-1:0] T1 = movd ? PW'(T_DAT1_O) : PW'(T_DAT1_N);  // write 1 low time
  wire [PW-1:0] TL = movd ? PW'(T_RSTL_O) : PW'(T_RSTL_N);  // reset low time""",1)
open(p,'w').write(s)
EOF
grep -n "default\|PW'" sva/sockit_owm_sva.sv | head -20; ./check_syntax.sh 2>&1 | grep -v "sockit_owm.v(" 
```

#### result

```
1:// SVA checker for sockit_owm (1-wire master), default parameters.
48:  default clocking @(posedge clk);
50:  default disable iff (rst);
67:      if (r && d)      cyc_len = o ? '0 : PW'(T_IDLE_N);
68:      else if (r)      cyc_len = o ? PW'(T_RSTL_O + T_RSTH_O) : PW'(T_RSTL_N + T_RSTH_N);
69:      else             cyc_len = o ? PW'(T_DAT0_O + T_RCVR_O) : PW'(T_DAT0_N + T_RCVR_N);
109:  wire [PW-1:0] T0 = movd ? PW'(T_DAT0_O) : PW'(T_DAT0_N);  // write 0 low time
110:  wire [PW-1:0] T1 = movd ? PW'(T_DAT1_O) : PW'(T_DAT1_N);  // write 1 low time
111:  wire [PW-1:0] TL = movd ? PW'(T_RSTL_O) : PW'(T_RSTL_N);  // reset low time
116:  // is sampled high. The check is written as rst |=> ... with the default
117:  // disable iff turned off, because the default would disable it.
SYNTAX OK
```

### assistant

Syntax passes with no warnings from the checker file. The only remaining warnings are in the RTL: the undriven `owr_sel` for OWN=1. I also created a stray text file outside the workspace earlier, so I'm removing it and confirming the final file set.

### step 8: Bash

```
rm -f /tmp/brg8ve/sva_ws/owr_doc.txt; cd /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL && find . -newer TASK.md -type f; cat sockit_owm_sva.f; ./check_syntax.sh 2>&1 | grep -c "sva.sv" ; grep -c "^  a_" sva/sockit_owm_sva.sv
```

#### result

```
./sockit_owm_sva.f
./sva/sockit_owm_sva.sv
./sva/sockit_owm_sva.sv
0
35
```

### step 9: SubagentHandback

Checker written and syntax-clean. Deliverables are in /tmp/brg8ve/sva_ws/sockit_owm_2DIKwL:
- sva/sockit_owm_sva.sv: module sockit_owm_sva (35 labelled assert properties, no cover/assume, no initial/$display/#) plus `bind sockit_owm sockit_owm_sva #(...) u_sockit_owm_sva (.*);` passing the design's parameters.
- sockit_owm_sva.f: single line `./sva/sockit_owm_sva.sv`.

./check_syntax.sh prints SYNTAX OK. It produces no warnings pointing into the checker. The only warnings are in rtl/sockit_owm.v (see below). I did not run a formal tool, so the properties are verified by hand-tracing the RTL only, not proven.

What the checker specifies:
- Reset values (cdr_n/cdr_o = CDR_N/CDR_O; pwr, ovd, rst, cyc, ien, irq, oen = 0). Written as rst |=> with disable iff(1'b0), so the default reset mask does not hide them.
- Read-back: control write -> read returns ien/pwr/ovd/rst; address-1 write -> read returns the full 32-bit cdr value.
- Interrupt: set on the end of an owr_cyc cycle; enabled request appears on bus_irq; held until a control read or write; cleared by a control write; control read clears it when no pulse coincides.
- Power: owr_p follows the pwr bit on control writes and holds otherwise.
- Cycle control: cyc=1 starts a cycle; zero-time idle (ovd=rst=dat=1) does not start one; cyc=0 aborts; each cycle holds until its last base period, then ends. Lengths are 13/13/192/200 base periods in normal mode and 8/8/96 in overdrive, from datasheet Table 12/7 and the parameters.
- Line (owr_oen) per cycle type: write-0 low for T_DAT0 base periods, write-1 for T_DAT1, reset for T_RSTL, idle never drives. owr_e is only related to owr_oen (owr_e |-> owr_oen).
- dat bit: written by a control write, held during a cycle, changed only at end of cycle; any bus write restarts the divider.

Findings where the RTL and the datasheet disagree or the RTL is unconstrained. I did not write assertions that fail on the RTL:
1. Datasheet Table 11 says cyc=0 is "no action", but a control write with cyc=0 still sets owr_oen (ovd/rst/dat decide it). For example, writing 0x00 holds the 1-wire line pulled low until the next control write, since normal mode has no pulses while idle. No assertion covers the cyc=0 line behaviour, because it contradicts the datasheet and the RTL disagrees with it.
2. Overdrive with CDR_O=0 (the default) makes pls fire every clock even when idle. The 8-bit counter then wraps and can set irq_sts and overwrite owr_dat with no cycle in progress. Consequently no assertion ties irq or dat to "end of cycle" without an owr_cyc qualifier, and the irq-clear property excludes pls coincidences.
3. owr_sel is never driven when OWN=1 (the RTL's `initial` is ignored; warning at sockit_owm.v:148). The read path (owr_i -> owr_iln -> owr_smp -> owr_dat) and the owr_e pin level are therefore unconstrained. The checker does not assert anything about read data or the owr_e level, only owr_e |-> owr_oen.
4. Datasheet Table 2 gives CDR_N=15 and CDR_O=2 as defaults, but the RTL uses 4 and 0. I followed the parameter values and tied reset checks to the parameters, not literals.
5. Datasheet Table 10 says the dat bit reset is "x"; the RTL resets it to 0. I did not assert the dat reset value.

Items I did not cover: the clock-accurate divider period (base period = CDR+1 clocks) and the exact first-pulse timing, which need a clock-count model and were left out to keep the checker small. Cycle lengths are specified in base periods instead.

#### result

```
{"success":true,"message":"Report delivered to your caller."}
```
