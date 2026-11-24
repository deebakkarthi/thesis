# Generator trace

source: /tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tasks/ad618f8cbbab02fc0.output

note: 4 thinking block(s) were stored without text.

### step 1: Bash

```
cat /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/TASK.md; echo ---; ls -la /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/
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
... [9242 more chars]
```

### step 2: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z && cat sockit_owm.f sockit_owm.tcl check_syntax.sh; echo ---; ls -la rtl doc; wc -l rtl/* ; cat rtl/*
```

### step 3: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z && for f in doc/*; do echo "== $f"; case "$f" in *.pdf) pdftotext -layout "$f" - ;; *) cat "$f";; esac; done
```

#### result

```
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
---
doc:
total 364
drwxr-xr-x 2 brg8ve users     28 Nov 23 20:09 .
drwx------ 4 brg8ve users    108 Nov 23 20:09 ..
-rw-r--r-- 1 brg8ve users 372000 Nov 23 20:09 sockit_owr.pdf

rtl:
total 20
drwxr-xr-x 2 brg8ve users    26 Nov 23 20:09 .
drwx------ 4 brg8ve users   108 Nov 23 20:09 ..
-r--r--r-- 1 brg8ve users 17641 Nov 23 20:09 sockit_owm.v
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
//  along with this program.  If not, see <h
... [16095 more chars]
```

#### result

```
<persisted-output>
Output too large (63.1KB). Full output saved to: /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/boih97xqj.txt

Preview (first 2KB):
== doc/sockit_owr.pdf
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
cd /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z && S=/tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/scratchpad; mkdir -p $S && pdftotext -layout doc/sockit_owr.pdf $S/doc.txt && wc -l $S/doc.txt && sed -n 60,330p $S/doc.txt
```

#### result

```
1214 /tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/scratchpad/doc.txt
7 Demo hardware and software implementation...............................................................................23
   7.1 Demo hardware.......................................................................................................................23
      7.1.1 Demo hardware logic consumption................................................................................23
   7.2 Demo software........................................................................................................................24
      7.2.1 Demo software memory consumption............................................................................24


                                                                          2
8 Testing............................................................................................................................................25
  8.1 Verilog RTL simulation...........................................................................................................25
     8.1.1 1-wire slave model..........................................................................................................25
     8.1.2 Verilog testbench.............................................................................................................26
     8.1.3 Parameter tests................................................................................................................26
  8.2 C driver tests...........................................................................................................................27
  8.3 Testing TODO.........................................................................................................................27
9 License............................................................................................................................................28
10 References....................................................................................................................................29



Index of Tables
Table 1: File list....................................................................................................................................5
Table 2: List of sockit_owm module parameters..................................................................................6
Table 3: Base time period and base frequency options........................................................................7
Table 4: List of sockit_owm module ports...........................................................................................7
Table 5: Wishbone equivalents of Avalon MM signals........................................................................8
Table 6: 1-wire protocol standard timing restrictions................................................
... [13504 more chars]
```

### step 5: Bash

```
S=/tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/scratchpad; sed -n 330,640p $S/doc.txt
```

#### result

```
long 1-wire networks, but it is suggested to use weak drivers (slow slew rate) to minimize
transitional effects on the network. If the FPGA pin is to be used to provide power to an 1-wire
slave, the opposite, to use strong drivers is suggested. If both requirements are present the user must
choose the proper compromise based on specifications and testing.

2.3 Metastability evaluation
The 1-wire line is sampled at the presence detection point for reset cycles and at the data sample
point for read/write data cycles. The sampled value is first stored in a register and later at the end of
the 1-wire cycle copied into a register visible on CPU interface data bus. The shortest time between
sampling the 1-wire line and data being available on the CPU bus is 5μs, this is enough for all
metastability problems to level out.




                                                   9
3 Supported 1-wire functionality
The sockit_owm module provides timed cycles for 1-wire reset/presence and write/read bit for
both normal and overdrive mode. This section describes how the 1-wire link layer is implemented
by the sockit_owm module RTL.

3.1 RTL description
The core of the RTL is a state machine with a 7bit or 8bit counter. On each bus write the counter
and owr signals are set to appropriate values. The clock generator provides pulses every base time
period (depends on overdrive mode being used), on each pulse the counter is decremented and the
owr signals are changed as required. More details can be found in the RTL source.




           bus_wen
                                   power                                             owr_p
           bus_ren

           bus_adr                 select

           bus_wdt                             rst
                                                        state                        owr_e
           bus_rdt                             dat
                                   control             machine
                                      /
                                   status      cyc      7/8bit
           bus_irq                             irq     counter                       owr_i


                                        ovd           pls

                 clk                    clock generator


                                   cdr_n          cdr_o

Drawing 3: RTL block diagram


3.2 1-wire cycle timings
The timing for 1-wire cycles is defined as a set of minimum and maximum values for certain cycle
segments. In case the master is the data source (reset and write) the minimal values are optimal
since they provide the fastest transfer rate. In case the slave is the data source (presence and read)
the maximum values are optimal since they allow the signal to stabilize as much as possible.




                                                 10
Table 6: 1-wire protocol standard timing restrictions
timing     normal               overdrive
[μs]                                                 optimal desc
... [13904 more chars]
```

### step 6: Bash

```
S=/tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/scratchpad; sed -n 640,760p $S/doc.txt; echo ....; grep -n -i "testing\|8.1\|simulat\|parameter test" $S/doc.txt | head -40
```

#### result

```
used to identify the end of the cycle.
Two basic functions are provided one for reset pulse and the other for a combined write/read data
slot. Separate write and read data functions are based on the combined data slot function.

Reset and presence pulses
A '1' is written into the rst bit and a '0' is written into the dat bit. Bit ovd is used to select normal
or overdrive mode. The cycle will start after writing '1' into cyc. The software must wait in a loop
till the cycle ends (cyc=0), and than the presence status can be read from bit dat. The next function
returns the presence detect status.

bool owr_reset (bool overdrive)
{
  int reg;
  write (0x08 | (overdrive << 2) | 0x02);
  while (0x08 & (reg = read()));
  return (reg & 0x01);
}

Read/write data slots
A boolean value bit is written into the dat bit, this will cause a write bit cycle on the 1-wire bus.
Bit ovd is used to select normal or overdrive mode. The cycle will start after writing '1' into cyc.
The software must wait in a loop till the cycle ends ( cyc=0), and than the read bit can be read
from status register bit dat. The next function returns the read bit.

bool owr_slot      (bool overdrive, bool bit)
{
  int reg;
  write (0x08      | (overdrive << 2) | bit);
  while (0x08      & (reg = read()));
  return (reg      & 0x01);
}

Read data bit and write data bit functions are based on the slot function.
bool ovd_read (bool overdrive)      {return owr_slot (overdrive, 0x1);}
void ovd_write (bool overdrive, bool bit) {owr_slot (overdrive, bit);}


                                                   16
Delay of 0ms or 1ms
By writing '1' to rst and dat an idle cycle is produced. If ovd bit is set for normal mode the delay
is of 1ms, if it is set for overdrive mode the delay is of zero time. The 1ms delay is intended to be
used as a timed delay with power delivery, so the pseudo code provides the power option.
The next code generates a zero time delay.

void owr_delay_0 (bool power)
{
  write (0x08 | (power << 4) | 0x07);
  while (0x08 & read());
}

The next code generates an 1ms delay.

void owr_delay_1 (bool power)
{
  write (0x08 | (power << 4) | 0x03);
  while (0x08 & read());
}


4.5.2 Interrupt routines
The 1-wire protocol is slow compared to clock speeds of most embedded processors, even low
power micro-controllers. Because of the low speed a polling driver might spend many clock periods
(at leas 7 for bit read/write and 960 for the reset pulse) busy waiting for the 1-wire cycle to finish,
this time could be better spent performing useful tasks. To be able to use this idle time, a task
scheduler (usually provided by an operating system) is also required, so that there can be
alternative threads that can be executed while waiting for the interrupt (or waiting for temperature
conversion to finish).
Since the 1-wire bus can be accessed from more than one task, a locking mechanism is required, so
that higher level protocol sequences are not corrupted. Only locking of low level transfer
... [3496 more chars]
```

### assistant

Before writing the checker, here is my analysis of the design and the behaviours I plan to specify.

**Design facts (default parameters):** OVD_E=1, CDR_E=1, BDW=32, OWN=1, BAW=1, BTP_N="5.0", BTP_O="1.0". CDR_N=4 (5 clocks per normal base period), CDR_O=0 (1 clock per overdrive period). Cycle lengths in base periods: write-0/write-1/read 13 normal and 8 overdrive, reset 192 normal and 96 overdrive, timed idle 200 normal. Reset is active high.

**Traps I found:**
- `owr_sel` is only assigned in an `initial` block when OWN=1, so it is arbitrary. That makes `owr_e` (except when `owr_oen`=0), `owr_iln`, `owr_smp` and the data read-back of the presence/data sample arbitrary. I will not assert those values.
- The datasheet says an overdrive zero-time idle has 0 µs duration. The RTL runs a 96-pulse counter and sets `irq_sts` when CDR_O=0 (the counter keeps pulsing while idle). I will not assert the datasheet's zero-time idle interrupt behaviour.
- A control write with cyc=0 sets `owr_oen`=1 in the RTL, which drives the line with no cycle. The datasheet says cyc=0 means no action, so I will not assert that the line is quiet after such a write.
- Background pulses in overdrive mode can set `irq_sts` and change `owr_dat`/`owr_oen` while idle. Hold properties therefore exclude `pls`.
- Clock divider writes change the pulse period, so cycle-timing assertions need `cdr_n==CDR_N` / `cdr_o==CDR_O` in the antecedent and no bus writes in the window.

Now writing the checker.

### step 7: Bash

```
mkdir -p /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/sva && cat > /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/sva/sockit_owm_sva.sv << 'EOF'
// SVA checker for sockit_owm (1-wire master), specified for the default
// parameter set (OVD_E=1, CDR_E=1, BDW=32, OWN=1, BAW=1, BTP_N="5.0", BTP_O="1.0").
// Sources: datasheet sections 2.2, 4.1-4.5 (Tables 8-12), and RTL.
// Internal signals used:
//  - owr_sel is never assigned for OWN=1, so owr_e (when owr_oen=1), owr_iln and
//    owr_smp are arbitrary; no property asserts their values.
module sockit_owm_sva #(
  parameter OVD_E    = 1,
  parameter CDR_E    = 1,
  parameter BDW      = 32,
  parameter OWN      = 1,
  parameter BAW      = 1,
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
  parameter T_RCVR_O = 2,
  parameter T_IDLE_O = 96,
  parameter CDW = CDR_E ? ((BDW == 32) ? 16 : 8) : $clog2(CDR_N),
  parameter TDW = ((T_RSTH_O + T_RSTL_O) > (T_RSTH_N + T_RSTL_N)) ?
                  $clog2(T_RSTH_O + T_RSTL_O) : $clog2(T_RSTH_N + T_RSTL_N)
)(
  input logic              clk,
  input logic              rst,
  input logic              bus_ren,
  input logic              bus_wen,
  input logic [BAW-1:0]    bus_adr,
  input logic [BDW-1:0]    bus_wdt,
  input logic [BDW-1:0]    bus_rdt,
  input logic              bus_irq,
  input logic [OWN-1:0]    owr_e,
  input logic [OWN-1:0]    owr_p,
  input logic              pls,
  input logic [TDW-1:0]    cnt,
  input logic              owr_cyc,
  input logic              owr_ovd,
  input logic              owr_rst,
  input logic              owr_dat,
  input logic              owr_oen,
  input logic              irq_ena,
  input logic              irq_sts,
  input logic [CDW-1:0]    cdr_n,
  input logic [CDW-1:0]    cdr_o
);

  // ------------------------------------------------------------------------
  // Derived constants (datasheet Table 7 / RTL timing functions)
  // PN, PO: clocks per base period (divider ratio + 1).
  // LN_*, LO_*: base periods from a control write until cycle end.
  // MN_*, MO_*: base period (pulse) index at which the line is released.
  // ------------------------------------------------------------------------
  localparam int PN      = CDR_N + 1;
  localparam int PO      = CDR_O + 1;
  localparam int LN_BIT  = T_DAT0_N + T_RCVR_N;          // 13
  localparam int LN_RST  = T_RSTH_N + T_RSTL_N;          // 192
  localparam int LN_IDL  = T_IDLE_N;                     // 200
  localparam int LO_BIT  = T_DAT0_O + T_RCVR_O;          // 8
  localparam int LO_RST  = T_RSTH_O + T_RSTL_O;          // 96
  localparam int MN_W0   = LN_BIT - T_RCVR_N;            // 12 (release at t_dat0)
  localparam int MN_W1   = LN_BIT - (T_DAT0_N - T_DAT1_N + T_RCVR_N); // 1
  localparam int MN_RST  = LN_RST - T_RSTH_N;            // 96 (release at t_rsth)
  localparam int MO_W0   = LO_BIT - T_RCVR_O;            // 6
  localparam int MO_W1   = LO_BIT - (T_DAT0_O - T_DAT1_O + T_RCVR_O); // 1
  localparam int MO_RST  = LO_RST - T_RSTH_O;            // 48
  // clock-cycle counts used in sequences
  localparam int K_N_BIT = LN_BIT * PN;                  // 65
  localparam int K_N_RST = LN_RST * PN;                  // 960
  localparam int K_N_IDL = LN_IDL * PN;                  // 1000
  localparam int K_O_BIT = LO_BIT * PO;                  // 8
  localparam int K_O_RST = LO_RST * PO;                  // 96
  localparam int R_N_W0  = MN_W0 * PN;                   // 60
  localparam int R_N_W1  = MN_W1 * PN;                   // 5
  localparam int R_N_RST = MN_RST * PN;                  // 480
  localparam int R_O_W0  = MO_W0 * PO;                   // 6
  localparam int R_O_W1  = MO_W1 * PO;                   // 1
  localparam int R_O_RST = MO_RST * PO;                  // 48

  // ------------------------------------------------------------------------
  // Decodes
  // ------------------------------------------------------------------------
  wire ctl_wr  = bus_wen && !bus_adr[0];                 // control/status write
  wire cdr_wr  = bus_wen &&  bus_adr[0];                 // clock divider write
  wire ctl_rd  = bus_ren && !bus_adr[0];                 // control/status read
  wire cyc_end = pls && (cnt == '0);                     // end-of-cycle pulse (RTL t_zero)
  wire ok_n    = (cdr_n == CDR_N);                       // normal divider at default
  wire ok_o    = (cdr_o == CDR_O);                       // overdrive divider at default

  // cycle-start writes, selected by the written cyc/ovd/rst/dat bits [3:0]
  wire go_n_w0  = ctl_wr && (bus_wdt[3:0] == 4'b1000);   // normal write 0
  wire go_n_w1  = ctl_wr && (bus_wdt[3:0] == 4'b1001);   // normal write 1 / read
  wire go_n_rst = ctl_wr && (bus_wdt[3:0] == 4'b1010);   // normal reset/presence
  wire go_n_idl = ctl_wr && (bus_wdt[3:0] == 4'b1011);   // normal timed idle (1 ms)
  wire go_o_w0  = ctl_wr && (bus_wdt[3:0] == 4'b1100);   // overdrive write 0
  wire go_o_w1  = ctl_wr && (bus_wdt[3:0] == 4'b1101);   // overdrive write 1 / read
  wire go_o_rst = ctl_wr && (bus_wdt[3:0] == 4'b1110);   // overdrive reset/presence
  wire go_o_idl = ctl_wr && (bus_wdt[3:0] == 4'b1111);   // overdrive zero-time idle

  default clocking @(posedge clk); endclocking
  default disable iff (rst);

  // ------------------------------------------------------------------------
  // 1. Reset values. Source: datasheet Table 10 (reset column) and RTL reset.
  // ------------------------------------------------------------------------

  // Table 10: ien resets to 0.
  a_rst_irq_ena: assert property ($past(rst) |-> !irq_ena);
  // Table 10: irq resets to 0.
  a_rst_irq_sts: assert property ($past(rst) |-> !irq_sts);
  // Table 10: cyc resets to 0 (no cycle in progress).
  a_rst_cyc: assert property ($past(rst) |-> !owr_cyc);
  // Table 10: ovd resets to 0.
  a_rst_ovd: assert property ($past(rst) |-> !owr_ovd);
  // Table 10: rst resets to 0.
  a_rst_rst: assert property ($past(rst) |-> !owr_rst);
  // RTL reset branch of owr_dat (datasheet says x; RTL resets to 0).
  a_rst_dat: assert property ($past(rst) |-> !owr_dat);
  // Table 10: pwr resets to 0, so the power output is off.
  a_rst_pwr: assert property ($past(rst) |-> owr_p == '0);
  // RTL reset of owr_oen: line driver off, and owr_e = owr_oen << sel is 0 for any sel.
  a_rst_oen: assert property ($past(rst) |-> owr_e == '0);
  // RTL reset of the cycle counter.
  a_rst_cnt: assert property ($past(rst) |-> cnt == '0);
  // Section 4.2: divider registers reset to CDR_N / CDR_O.
  a_rst_cdr_n: assert property ($past(rst) |-> cdr_n == CDR_N);
  a_rst_cdr_o: assert property ($past(rst) |-> cdr_o == CDR_O);
  // Section 4.4: after reset the control/status register reads all zero.
  a_rst_rdt_ctl: assert property ($past(rst) && !bus_adr[0] |-> bus_rdt == '0);

  // ------------------------------------------------------------------------
  // 2. Register map and read-back. Sources: Table 8 (address map), Table 10/11.
  // ------------------------------------------------------------------------

  // Table 8: with OWN=1 the power/select fields are not implemented, so the
  // control/status read at address 0 returns zero in bits 31:8.
  a_map_ctl_hi0: assert property (!bus_adr[0] |-> bus_rdt[31:8] == '0);
  // Table 10: bit 5 of the control/status register is reserved and reads 0.
  a_map_ctl_rsv: assert property (!bus_adr[0] |-> !bus_rdt[5]);
  // Table 11 bit 7 (ien): a control write is read back in the next cycle.
  a_rb_ien: assert property (ctl_wr ##1 !bus_adr[0] |-> bus_rdt[7] == $past(bus_wdt[7]));
  // Table 11 bit 4 (pwr, OWN=1): a control write is read back in the next cycle.
  a_rb_pwr: assert property (ctl_wr ##1 !bus_adr[0] |-> bus_rdt[4] == $past(bus_wdt[4]));
  // Table 11 bit 2 (ovd): a control write is read back in the next cycle.
  a_rb_ovd: assert property (ctl_wr ##1 !bus_adr[0] |-> bus_rdt[2] == $past(bus_wdt[2]));
  // Table 11 bit 1 (rst): a control write is read back in the next cycle.
  a_rb_rst: assert property (ctl_wr ##1 !bus_adr[0] |-> bus_rdt[1] == $past(bus_wdt[1]));
  // Table 11 bit 0 (dat): read back the written bit. No cycle can end in the
  // cycle right after a control write, because the loaded counter is at least 7.
  a_rb_dat: assert property (ctl_wr ##1 !bus_adr[0] |-> bus_rdt[0] == $past(bus_wdt[0]));
  // Table 8/4.2: a divider write is read back at address 1 (cdr_o high, cdr_n low).
  a_rb_cdr: assert property (cdr_wr ##1 bus_adr[0] |-> bus_rdt == $past(bus_wdt));

  // ------------------------------------------------------------------------
  // 3. Hold / update events. Each register changes only on the events listed.
  // ------------------------------------------------------------------------

  // Section 4.2: divider registers change only on a divider write.
  h_cdr: assert property (!cdr_wr |=> ($stable(cdr_n) && $stable(cdr_o)));
  // ien changes only on a control write.
  h_ien: assert property (!ctl_wr |=> $stable(irq_ena));
  // pwr changes only on a control write.
  h_pwr: assert property (!ctl_wr |=> $stable(owr_p));
  // ovd changes only on a control write.
  h_ovd: assert property (!ctl_wr |=> $stable(owr_ovd));
  // rst changes only on a control write.
  h_rst: assert property (!ctl_wr |=> $stable(owr_rst));
  // cyc changes only on a control write or at the end-of-cycle pulse.
  h_cyc: assert property (!ctl_wr && !cyc_end |=> $stable(owr_cyc));
  // dat changes only on a control write or at the end-of-cycle pulse.
  h_dat: assert property (!ctl_wr && !cyc_end |=> $stable(owr_dat));
  // irq changes only on a control write, a control read, or the end-of-cycle pulse.
  h_irq: assert property (!ctl_wr && !ctl_rd && !cyc_end |=> $stable(irq_sts));
  // The cycle counter changes only on a control write or a pulse.
  h_cnt: assert property (!ctl_wr && !pls |=> $stable(cnt));
  // Line driver enable rises only on a control write (Section 4.4 / RTL).
  h_oen_up: assert property (!owr_oen && !ctl_wr |=> !owr_oen);
  // Line driver enable falls only on a pulse (RTL pulse-driven release).
  h_oen_dn: assert property (owr_oen && !ctl_wr && !pls |=> owr_oen);

  // ------------------------------------------------------------------------
  // 4. Outputs.
  // ------------------------------------------------------------------------

  // Section 2.2.2 / Table 4: the power output follows the written pwr bit (OWN=1).
  a_pwr_out: assert property (ctl_wr |=> owr_p[0] == $past(bus_wdt[4]));
  // Section 4.3 / Table 4: the line driver enable is off whenever owr_oen is off.
  a_e_gate: assert property (!owr_oen |-> owr_e == '0);
  // Section 4.4: an idle cycle (rst=1, dat=1) does not drive the line.
  a_idle_quiet: assert property ((ctl_wr && bus_wdt[1:0] == 2'b11) |=> owr_e == '0);

  // ------------------------------------------------------------------------
  // 5. Interrupt / cycle status flag.
  // Sources: Table 11 bits 6 and 3, Section 2.2.1 and 4.4.
  // ------------------------------------------------------------------------

  // Table 11 bit 6: any control write clears the interrupt status.
  a_irq_wr_clr: assert property (ctl_wr |=> !irq_sts);
  // Table 11 bit 6: a control read clears the interrupt status (unless the cycle ends now).
  a_irq_rd_clr: assert property ((ctl_rd && !ctl_wr && !cyc_end) |=> !irq_sts);
  // The interrupt output is low after the status is cleared by a read.
  a_irq_rd_bus: assert property ((ctl_rd && !ctl_wr && !cyc_end) |=> !bus_irq);

  // ------------------------------------------------------------------------
  // 6. Cycle start, duration, and line release. Each cycle type is checked
  // from a start write with the divider at its default value (no bus write
  // in the window, which keeps the divider and counter untouched).
  // Source: Table 12 (cycle types), Table 7 (timing), RTL counter/release logic.
  // ------------------------------------------------------------------------

  // ---- normal mode, write 0 (cyc=1, ovd=0, rst=0, dat=0) : 65 us = 13 base periods
  a_n_w0_start: assert property (go_n_w0 |=> (owr_cyc && !irq_sts && owr_oen));
  a_n_w0_busy:  assert property ((go_n_w0 && ok_n) ##1 (!bus_wen)[*K_N_BIT] |-> owr_cyc);
  a_n_w0_end:   assert property ((go_n_w0 && ok_n) ##1 (!bus_wen)[*K_N_BIT] |=> (!owr_cyc && irq_sts));
  // Table 7 tDAT0: line low for 12 base periods, then released.
  a_n_w0_low:   assert property ((go_n_w0 && ok_n) ##1 (!bus_wen)[*R_N_W0] |-> owr_oen);
  a_n_w0_rel:   assert property ((go_n_w0 && ok_n) ##1 (!bus_wen)[*R_N_W0] |=> !owr_oen);
  // Table 11 bit 7 / Section 2.2.1: an enabled cycle end raises the interrupt output.
  a_n_w0_irq_en:  assert property ((go_n_w0 && ok_n && bus_wdt[7]) ##1 (!bus_wen)[*K_N_BIT] |=> bus_irq);
  a_n_w0_irq_dis: assert property ((go_n_w0 && ok_n && !bus_wdt[7]) ##1 (!bus_wen)[*K_N_BIT] |=> !bus_irq);
  // Table 11 bit 6: the status is readable after the cycle end and shows the interrupt.
  a_n_w0_irq_rd:  assert property ((go_n_w0 && ok_n) ##1 (!bus_wen)[*K_N_BIT] ##1 ctl_rd |-> bus_rdt[6]);

  // ---- normal mode, write 1 / read (cyc=1, ovd=0, rst=0, dat=1) : 65 us
  a_n_w1_start: assert property (go_n_w1 |=> (owr_cyc && !irq_sts && owr_oen));
  a_n_w1_busy:  assert property ((go_n_w1 && ok_n) ##1 (!bus_wen)[*K_N_BIT] |-> owr_cyc);
  a_n_w1_end:   assert property ((go_n_w1 && ok_n) ##1 (!bus_wen)[*K_N_BIT] |=> (!owr_cyc && irq_sts));
  // Table 7 tDAT1: line low for 1 base period, then released.
  a_n_w1_low:   assert property ((go_n_w1 && ok_n) ##1 (!bus_wen)[*R_N_W1] |-> owr_oen);
  a_n_w1_rel:   assert property ((go_n_w1 && ok_n) ##1 (!bus_wen)[*R_N_W1] |=> !owr_oen);

  // ---- normal mode, reset/presence (cyc=1, ovd=0, rst=1, dat=0) : 960 us
  a_n_rst_start: assert property (go_n_rst |=> (owr_cyc && !irq_sts && owr_oen));
  a_n_rst_busy:  assert property ((go_n_rst && ok_n) ##1 (!bus_wen)[*K_N_RST] |-> owr_cyc);
  a_n_rst_end:   assert property ((go_n_rst && ok_n) ##1 (!bus_wen)[*K_N_RST] |=> (!owr_cyc && irq_sts));
  // Table 7 tRSTL: line low for 480 us (96 base periods), then released.
  a_n_rst_low:   assert property ((go_n_rst && ok_n) ##1 (!bus_wen)[*R_N_RST] |-> owr_oen);
  a_n_rst_rel:   assert property ((go_n_rst && ok_n) ##1 (!bus_wen)[*R_N_RST] |=> !owr_oen);

  // ---- normal mode, timed idle (cyc=1, ovd=0, rst=1, dat=1) : 1 ms, no line drive
  a_n_idl_start: assert property (go_n_idl |=> (owr_cyc && !irq_sts && !owr_oen));
  a_n_idl_busy:  assert property ((go_n_idl && ok_n) ##1 (!bus_wen)[*K_N_IDL] |-> owr_cyc);
  a_n_idl_end:   assert property ((go_n_idl && ok_n) ##1 (!bus_wen)[*K_N_IDL] |=> (!owr_cyc && irq_sts));

  // ---- overdrive, write 0 (cyc=1, ovd=1, rst=0, dat=0) : 8 us
  a_o_w0_start: assert property (go_o_w0 |=> (owr_cyc && !irq_sts && owr_oen));
  a_o_w0_busy:  assert property ((go_o_w0 && ok_o) ##1 (!bus_wen)[*K_O_BIT] |-> owr_cyc);
  a_o_w0_end:   assert property ((go_o_w0 && ok_o) ##1 (!bus_wen)[*K_O_BIT] |=> (!owr_cyc && irq_sts));
  // Table 7 overdrive tDAT0: line low for 6 us, then released.
  a_o_w0_low:   assert property ((go_o_w0 && ok_o) ##1 (!bus_wen)[*R_O_W0] |-> owr_oen);
  a_o_w0_rel:   assert property ((go_o_w0 && ok_o) ##1 (!bus_wen)[*R_O_W0] |=> !owr_oen);
  a_o_w0_irq_en:  assert property ((go_o_w0 && ok_o && bus_wdt[7]) ##1 (!bus_wen)[*K_O_BIT] |=> bus_irq);
  a_o_w0_irq_dis: assert property ((go_o_w0 && ok_o && !bus_wdt[7]) ##1 (!bus_wen)[*K_O_BIT] |=> !bus_irq);

  // ---- overdrive, write 1 / read (cyc=1, ovd=1, rst=0, dat=1) : 8 us
  a_o_w1_start: assert property (go_o_w1 |=> (owr_cyc && !irq_sts && owr_oen));
  a_o_w1_busy:  assert property ((go_o_w1 && ok_o) ##1 (!bus_wen)[*K_O_BIT] |-> owr_cyc);
  a_o_w1_end:   assert property ((go_o_w1 && ok_o) ##1 (!bus_wen)[*K_O_BIT] |=> (!owr_cyc && irq_sts));
  // Table 7 overdrive tDAT1: line low for 1 us, then released.
  a_o_w1_low:   assert property ((go_o_w1 && ok_o) ##1 (!bus_wen)[*R_O_W1] |-> owr_oen);
  a_o_w1_rel:   assert property ((go_o_w1 && ok_o) ##1 (!bus_wen)[*R_O_W1] |=> !owr_oen);

  // ---- overdrive, reset/presence (cyc=1, ovd=1, rst=1, dat=0) : 96 us
  a_o_rst_start: assert property (go_o_rst |=> (owr_cyc && !irq_sts && owr_oen));
  a_o_rst_busy:  assert property ((go_o_rst && ok_o) ##1 (!bus_wen)[*K_O_RST] |-> owr_cyc);
  a_o_rst_end:   assert property ((go_o_rst && ok_o) ##1 (!bus_wen)[*K_O_RST] |=> (!owr_cyc && irq_sts));
  // Table 7 overdrive tRSTL: line low for 48 us, then released.
  a_o_rst_low:   assert property ((go_o_rst && ok_o) ##1 (!bus_wen)[*R_O_RST] |-> owr_oen);
  a_o_rst_rel:   assert property ((go_o_rst && ok_o) ##1 (!bus_wen)[*R_O_RST] |=> !owr_oen);

  // ---- overdrive zero-time idle (cyc=1, ovd=1, rst=1, dat=1): no cycle in progress.
  // Table 12 / Table 10 cyc: the write does not start a cycle (cyc reads 0).
  a_o_idl_nocyc: assert property (go_o_idl |=> !owr_cyc);

  // ---- restart: a control write with cyc=1 starts a new cycle, whatever state it
  // was in (the start properties above have no prior-state precondition).

endmodule

bind sockit_owm sockit_owm_sva #(
  .OVD_E(OVD_E), .CDR_E(CDR_E), .BDW(BDW), .OWN(OWN), .BAW(BAW),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_DAT0_N(T_DAT0_N),
  .T_DAT1_N(T_DAT1_N), .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_DAT0_O(T_DAT0_O),
  .T_DAT1_O(T_DAT1_O), .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);
EOF
cd /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z && printf './sva/sockit_owm_sva.sv\n' > sockit_owm_sva.f && ./check_syntax.sh
```

#### result

```
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-9005)] /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/./rtl/sockit_owm.v(417): 2-bit index expression 'owr_sel' is larger than the required 1 bits. This might lead to an out-of-bound access
SYNTAX OK
```

### step 8: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z && ls -R . && cat sockit_owm_sva.f && grep -c "assert property" sva/sockit_owm_sva.sv && grep -n "cover\|assume\|initial" sva/sockit_owm_sva.sv; echo "exit=$?"
```

#### result

```
.:
check_syntax.sh
doc
rtl
sockit_owm.f
sockit_owm_sva.f
sockit_owm.tcl
sva
TASK.md

./doc:
sockit_owr.pdf

./rtl:
sockit_owm.v

./sva:
sockit_owm_sva.sv
./sva/sockit_owm_sva.sv
76
exit=1
```

### step 9: SubagentHandback

SVA checker for sockit_owm is written and `./check_syntax.sh` prints SYNTAX OK.

Deliverables (only these two were created):
- /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/sva/sockit_owm_sva.sv: checker module `sockit_owm_sva` with 76 labelled `assert property` statements, plus `bind sockit_owm ... u_sockit_owm_sva (.*)`. No cover, assume, initial, or delays.
- /tmp/brg8ve/sva_ws/sockit_owm_iTMh6z/sockit_owm_sva.f: single line `./sva/sockit_owm_sva.sv`

Warnings from the syntax run all point into rtl/sockit_owm.v (undriven owr_sel, ignored initial, width truncation). None point into the checker, and the checker uses no blackboxed logic.

What the checker specifies (default parameters, reset active-high, sampled on posedge clk, disabled during rst):
1. Reset values: irq_ena, irq_sts, cyc, ovd, rst, dat, pwr, line enable, counter, cdr_n=CDR_N, cdr_o=CDR_O, and ctl read = 0.
2. Register map and read-back: address 0 bits 31:8 and bit 5 read 0; ien, pwr, ovd, rst, dat read back the written value; a divider write reads back at address 1 as {cdr_o, cdr_n} = written word.
3. Hold/update events: cdr, ien, pwr, ovd, rst change only on their writes; cyc and dat change only on a control write or end-of-cycle pulse; irq changes only on write, read or cycle end; counter changes only on write or pulse; line enable rises only on a control write and falls only on a pulse.
4. Outputs: owr_p follows the written pwr bit; owr_e is 0 whenever owr_oen is 0; an idle write (rst=1, dat=1) does not drive the line.
5. Interrupt: any control write clears irq; a control read clears it (unless the cycle ends that cycle); an enabled cycle end raises bus_irq; a disabled one does not; the status reads 1 after the end.
6. Cycle types, each from a start write with the divider at its default value and no bus writes in the window: start behaviour, exact duration (normal write 0/1 = 65 clocks, normal reset = 960, normal idle = 1000, overdrive write = 8, overdrive reset = 96), and line release points (normal write 0 low 12 base periods, write 1 low 1, reset 96; overdrive write 0 low 6, write 1 low 1, reset 48). Zero-time overdrive idle does not start a cycle (cyc reads 0).

Deliberately omitted (the RTL contradicts the datasheet, or the value is arbitrary):
- owr_sel is never assigned when OWN=1, so the line driver output while enabled, the sampled line value, and the presence/data read-back are arbitrary. Nothing about them is asserted.
- Datasheet says overdrive zero-time idle takes 0 us and does not set the interrupt. The RTL runs a 96-pulse counter and sets irq_sts while idle when CDR_O=0. Those claims are not asserted.
- Datasheet says cyc=0 is "no action", but a control write with cyc=0 and dat=0 (or rst=0, dat=0) drives owr_oen=1 with no cycle in progress. The RTL does this, so no assertion says the line stays quiet after such a write.
- Overdrive mode with CDR_O=0 keeps pulsing while idle, so hold properties for irq, dat and line enable exclude the pulse.

I could not run a simulator or formal tool; the only check was the compile-only syntax check. The assertion-level reasoning was done by hand against the RTL, and the timing numbers were derived from the RTL counter logic and checked against datasheet Table 7 (for example 12 base periods of low for write 0 at 5.0 us, 1 for write 1, 96 for reset).

#### result

```
{"success":true,"message":"Report delivered to your caller."}
```
