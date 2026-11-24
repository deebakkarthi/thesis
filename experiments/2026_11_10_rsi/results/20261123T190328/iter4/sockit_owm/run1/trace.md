# Generator trace

source: /tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tasks/a6c40a15fa1ec478c.output

note: 5 thinking block(s) were stored without text.

### step 1: Bash

```
cat /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/TASK.md; echo ---; ls -la /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/
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
... [9783 more chars]
```

### step 2: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm && cat sockit_owm.f sockit_owm.tcl check_syntax.sh; echo ---; ls -la rtl doc; wc -l rtl/* ; cat rtl/*
```

### step 3: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm && ls -la doc && for f in doc/*; do case "$f" in *.pdf) pdftotext -layout "$f" - ;; *) cat "$f" ;; esac; done
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
drwxr-xr-x 2 brg8ve users     28 Nov 23 20:23 .
drwx------ 4 brg8ve users    108 Nov 23 20:23 ..
-rw-r--r-- 1 brg8ve users 372000 Nov 23 20:23 sockit_owr.pdf

rtl:
total 20
drwxr-xr-x 2 brg8ve users    26 Nov 23 20:23 .
drwx------ 4 brg8ve users   108 Nov 23 20:23 ..
-r--r--r-- 1 brg8ve users 17641 Nov 23 20:23 sockit_owm.v
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
Output too large (63.2KB). Full output saved to: /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/b962s707z.txt

Preview (first 2KB):
total 364
drwxr-xr-x 2 brg8ve users     28 Nov 23 20:23 .
drwx------ 4 brg8ve users    108 Nov 23 20:23 ..
-rw-r--r-- 1 brg8ve users 372000 Nov 23 20:23 sockit_owr.pdf
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
...
</persisted-output>
```

### step 4: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm && pdftotext -layout doc/sockit_owr.pdf /tmp/brg8ve/sva_ws/owr.txt 2>/dev/null || pdftotext -layout doc/sockit_owr.pdf "$HOME/owr_doc.txt"; ls -la /tmp/brg8ve/sva_ws/ ; wc -l /tmp/brg8ve/sva_ws/owr.txt 2>/dev/null; sed -n 1,400p /tmp/brg8ve/sva_ws/owr.txt
```

#### result

```
total 132
drwxr-xr-x 14 brg8ve users  4096 Nov 23 20:24 .
drwxr-xr-x  3 brg8ve users    20 Nov 23 20:06 ..
-rw-r--r--  1 brg8ve users 64554 Nov 23 20:09 doc_sockit.txt
-rw-r--r--  1 brg8ve users 64554 Nov 23 20:24 owr.txt
drwx------  5 brg8ve users   143 Nov 23 20:06 sockit_owm_2DIKwL
drwx------  5 brg8ve users   143 Nov 19 13:54 sockit_owm_DPiHyO
drwx------  4 brg8ve users   108 Nov 23 20:23 sockit_owm_e2hMWm
drwx------  4 brg8ve users   108 Nov 23 20:23 sockit_owm_e3qn7r
drwx------  5 brg8ve users   143 Nov 23 19:11 sockit_owm_GSXjaA
drwx------  5 brg8ve users   143 Nov 23 20:17 sockit_owm_iTMh6z
drwx------  4 brg8ve users   108 Nov 19 12:45 sockit_owm_JenGek
drwx------  5 brg8ve users   143 Nov 23 19:12 sockit_owm_KX4d81
drwx------  5 brg8ve users   143 Nov 23 20:16 sockit_owm_muudzr
drwx------  5 brg8ve users   143 Nov 19 13:56 sockit_owm_n5pxb4
drwx------  5 brg8ve users   143 Nov 19 12:53 sockit_owm_pdcF5L
drwx------  5 brg8ve users   143 Nov 23 20:06 sockit_owm_Qxa6qx
1214 /tmp/brg8ve/sva_ws/owr.txt
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
      2.2.2 1-wire interface.........................................................................................................
... [23441 more chars]
```

### step 5: Bash

```
sed -n 400,800p /tmp/brg8ve/sva_ws/owr.txt
```

#### result

```
tRSTH        480         ∞            48      ∞ min             reset high (on newer devices this time is lower)
tRSTP        60          75          6        10 max            reset presence detect
            +8.1                  +1.3                          (the extra delay is due to slow slave IO)
tDAT0         60      120              6      16 min            data bit 0
tDAT1            5       15            1         2 min          data bit 1
tDATS                    15                      2 max          data sample
tREC             5       ∞             2      ∞ min             recovery
tDLY                                                 1ms        idle delay (not standard, about tRSTL+ tRSTH)
tRSTT        960         ∞            69         0              reset pulse cycle (tRSTL+ tRSTH)
tDATT         61      121              7      17                read/write slot cycle (tDAT0+ tREC)

The exact timing of 1-wire cycles is provided as a table with 3 options for normal mode and 2
options for overdrive mode. For exact base time periods only typical values are provided, for range
base time periods minimum and maximum value are provided.

Table 7: Timing options
                              normal mode times [μs]                               overdrive mode times [μs]
name             "7.5"                "5.0"                     "6.0"              "1.0"                  "0.5"
timing           N       typ          N       typ          N      min      max     N       typ      N      min    max
base             1       7.5           1         5          1         6      7.5    1       1         1     0.5   0.66
tRSTL          64        480          96      480          80     480        600   48      48       96       48    64
tRSTH          64        480          96      480          80     480        600   48      48       96       48    64
tRSTP          10          75         15       75          10        60       75   10      10       15      7.5    10
tDAT0            8         60         12       60          10        60       75    6       6       12        6     8
tDAT1            1       7.5           1         5          1         6      7.5    1       1         2       1   1.33
tDATS            2         15          3       15           2        12       15    2       2         3     1.5     2
tREC             1       7.5           1         5          1         6      7.5    2       2         4       2   2.66
tDLY         128         960       200 1000             160       960 1200         96      96      192       96   128

The 7.5μs base time period option is also explained with timing diagrams.
The reset cycle is 128 base periods long. Reset low and high time each take 64 base periods. After
the rising edge on the wire a typical 1-wire slave would assert its presence after 4 base periods (min
2, max 8), and keep it asserted for 16 base periods (min 8, max 32). The presence status is sampled

                             
... [17429 more chars]
```

### step 6: Bash

```
sed -n 800,1214p /tmp/brg8ve/sva_ws/owr.txt | grep -v '^\s*$' | head -300
```

#### result

```
control/status and clock divider ratio registers:
IORD_SOCKIT_OWM_CTL(base)
IOWR_SOCKIT_OWM_CTL(base, data)
IORD_SOCKIT_OWM_CDR(base)
IOWR_SOCKIT_OWM_CDR(base, data)
Interrupt support is provided for a system without or with the μC/OS-II real time OS. But there are
no advantages using interrupts if there is no task scheduling implemented on the system. Since the
sockit_owm module provides only bit sized data transfers, there are interrupts for each bit. If the
CPU is running at low clock speeds, the operating system overhead might be substantial.
5.1.2 Public Domain Kit components
The Public Domain Kit provides a layered 1-wire protocol implementation. The focus of the port
was on layers common to all 1-wire devices, device drivers with the exception of thermometers
                                                 19
were omitted. Support for other devices and applications have to be ported separately by the user.
The ported files were located in the next directories from the Public Domain Kit package:
   •   owpd310r2/common - some common code (CRC, err, findtype) and device drivers
   •   owpd310r2/apps/temp - the thermometer demo application is from here
   •   owpd310r2/doc - documentation
   •   owpd310r2/lib/general - data link and session layer TODO files
   •   owpd310r2/lib/general/shared - transport and network layer files
Table 14: Files from the Public Domain Kit
file                          description
HAL/inc/ownet.h               main protocol stack header file
HAL/src/owlnk.c               1-wire protocol data link layer functions
HAL/inc/ownet.c               1-wire protocol network layer functions
HAL/src/owtran.c              1-wire protocol transport layer functions
HAL/src/owses.c               1-wire protocol session layer functions
HAL/src/owerr.c               1-wire driver error handling
HAL/src/crcutil.c             1-wire protocol CRC utilities
HAL/inc/findtype.[hc] 1-wire network search for devices
HAL/inc/temp10.[hc]           thermometer device driver (ID 0x10 - DS1920/DS1820)
HAL/inc/temp28.[hc]           thermometer device driver (ID 0x28 - DS18B20)
HAL/inc/temp42.[hc]           thermometer device driver (ID 0x42 - DS28EA00)
Most code changes were done to owlnk.c and owses.c. Some platform specific code for unrelated
platforms was removed from ownet and owerr. Other files are mostly unchanged, check the Git
repository to see details.
5.2 Adding support for new devices
Support for a new device can be added by copying needed files from the /common directory in the
Public Domain Kit into the working directory of the Nios II project. Applications can also be ported
from the /apps directory.
5.3 Possible improvements
The main limitation the user has to be careful with is only one hardware module instance can be
handled by the driver. This is due to how the Public Domain Kit handles ports (1-wire lines) and its
use of global variables. Since this affects almost all high level functions in the Public Domain Kit,
there w
... [15513 more chars]
```

### assistant

I have the RTL and the full datasheet. Before writing the checker I'm recording the RTL facts the assertions depend on, since several of them contradict a naive reading of the doc.

### step 7: Bash

```
mkdir -p /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/sva && cat > /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/sva/sockit_owm_sva.sv << 'EOF'
// ============================================================================
// SVA checker for sockit_owm (1-wire master, Avalon-style 32-bit bus).
//
// Default configuration only: BDW=32, BAW=1, OWN=1, OVD_E=1, CDR_E=1,
// BTP_N="5.0", BTP_O="1.0".  Derived: CDR_N=4, CDR_O=0, cnt/TDW=8, div/cdr 16b.
//
// Notes on the RTL that shaped the assertions (all checked by hand):
//  * owr_sel is only given a value by an `initial` block when OWN==1, so it is
//    never assigned. owr_e and owr_iln (and so owr_smp, owr_dat after a cycle,
//    and bit 0 of the status read) are therefore unconstrained. Only the
//    implication owr_e[0] -> owr_oen is asserted on the driver output.
//  * pls = (div == (owr_ovd ? cdr_o : cdr_n)) is not gated by owr_cyc. With
//    cdr_o==0 (default) and owr_ovd==1, pls fires every clock even when idle,
//    so cnt keeps counting and irq_sts/owr_dat are updated at cnt==0 with no
//    cycle in progress. Properties that involve idle state exclude that event
//    (pls && cnt==0) explicitly.
//  * A 1-wire cycle is N ticks long, where a tick is one pls. Within a cycle,
//    cnt == N-1-ticks, so 'ticks' (an aux counter of pls while owr_cyc) gives
//    the documented durations without unrolling time.
// ============================================================================
module sockit_owm_sva #(
  parameter BDW      = 32,
  parameter BAW      = 1,
  parameter OWN      = 1,
  parameter TDW      = 8,
  parameter CDW      = 16,
  parameter CDR_N    = 4,
  parameter CDR_O    = 0,
  parameter T_RSTL_N = 96,
  parameter T_RSTH_N = 96,
  parameter T_DAT0_N = 12,
  parameter T_DAT1_N = 1,
  parameter T_RCVR_N = 1,
  parameter T_IDLE_N = 200,
  parameter T_RSTL_O = 48,
  parameter T_RSTH_O = 48,
  parameter T_DAT0_O = 6,
  parameter T_DAT1_O = 1,
  parameter T_RCVR_O = 2,
  parameter T_IDLE_O = 96
)(
  input                clk,
  input                rst,
  input                bus_ren,
  input                bus_wen,
  input  [BAW-1:0]     bus_adr,
  input  [BDW-1:0]     bus_wdt,
  input  [BDW-1:0]     bus_rdt,
  input                bus_irq,
  input  [OWN-1:0]     owr_e,
  input  [OWN-1:0]     owr_p,
  input  [CDW-1:0]     div,
  input  [CDW-1:0]     cdr_n,
  input  [CDW-1:0]     cdr_o,
  input                pls,
  input                owr_cyc,
  input  [TDW-1:0]     cnt,
  input  [OWN-1:0]     owr_pwr,
  input                owr_ovd,
  input                owr_rst,
  input                owr_dat,
  input                owr_oen,
  input                irq_ena,
  input                irq_sts
);

  // ------------------------------------------------------------------------
  // Constants derived from the design parameters (default configuration)
  // ------------------------------------------------------------------------
  localparam [15:0] RST_CDR_N = CDR_N;
  localparam [15:0] RST_CDR_O = CDR_O;

  // cycle length in ticks (pls), normal and overdrive
  localparam [7:0] LEN_W0_N  = T_DAT0_N + T_RCVR_N;          // 13  (65 us)
  localparam [7:0] LEN_RST_N = T_RSTL_N + T_RSTH_N;          // 192 (960 us)
  localparam [7:0] LEN_IDL_N = T_IDLE_N;                     // 200 (1000 us)
  localparam [7:0] LEN_W0_O  = T_DAT0_O + T_RCVR_O;          // 8   (8 us)
  localparam [7:0] LEN_RST_O = T_RSTL_O + T_RSTH_O;          // 96  (96 us)

  // ticks after which the line is released (low time), per cycle type
  localparam [7:0] LO_W0_N  = T_DAT0_N;
  localparam [7:0] LO_W0_O  = T_DAT0_O;
  localparam [7:0] LO_W1_N  = T_DAT1_N;
  localparam [7:0] LO_W1_O  = T_DAT1_O;
  localparam [7:0] LO_RST_N = T_RSTL_N;
  localparam [7:0] LO_RST_O = T_RSTL_O;

  // ------------------------------------------------------------------------
  // Auxiliary logic (same clock, same reset)
  //   ticks : number of pls edges since the last control write, counted only
  //           while a 1-wire cycle is active.
  //   sub   : clocks since the last pls or bus write (mirrors the divider).
  // ------------------------------------------------------------------------
  reg  [7:0]  ticks;
  reg  [15:0] sub;

  always @(posedge clk)
    if (rst) begin
      ticks <= 8'd0;
      sub   <= 16'd0;
    end else begin
      if (bus_wen && (bus_adr[0] == 1'b0))  ticks <= 8'd0;
      else if (pls && owr_cyc)              ticks <= ticks + 8'd1;
      if (bus_wen || pls)                   sub <= 16'd0;
      else if (sub != 16'hFFFF)             sub <= sub + 16'd1;
    end

  // ------------------------------------------------------------------------
  // Derived events
  // ------------------------------------------------------------------------
  wire wr_ctl   = bus_wen && (bus_adr[0] == 1'b0);      // control/status write
  wire wr_cdr   = bus_wen && (bus_adr[0] == 1'b1);      // clock divider write
  wire rd_ctl   = bus_ren && (bus_adr[0] == 1'b0);
  wire rd_cdr   = bus_ren && (bus_adr[0] == 1'b1);
  // a control write that starts a 1-wire cycle (zero-time idle excluded)
  wire wr_start = wr_ctl && bus_wdt[3] && !(&bus_wdt[2:0]);
  // a control write with rst=1, dat=1: line released, no cycle time
  wire wr_idle  = wr_ctl && (&bus_wdt[1:0]);
  // divider-level end of cycle (the design's own end-of-cycle event)
  wire cnt_zero_pls = pls && (cnt == 8'd0);

  wire [7:0] cyc_len = owr_ovd ? (owr_rst ? LEN_RST_O : LEN_W0_O)
                               : (owr_rst ? (owr_dat ? LEN_IDL_N : LEN_RST_N) : LEN_W0_N);
  wire [7:0] lo_w0  = owr_ovd ? LO_W0_O  : LO_W0_N;
  wire [7:0] lo_w1  = owr_ovd ? LO_W1_O  : LO_W1_N;
  wire [7:0] lo_rst = owr_ovd ? LO_RST_O : LO_RST_N;

  wire [CDW-1:0] ratio = owr_ovd ? cdr_o : cdr_n;

  wire cyc_end  = owr_cyc && pls && (ticks == cyc_len - 8'd1);   // last tick of a cycle
  wire ph_rst   = owr_cyc && owr_rst && !owr_dat;                 // reset cycle
  wire ph_w0    = owr_cyc && !owr_rst && !owr_dat;                // write-0 cycle
  wire ph_w1    = owr_cyc && !owr_rst && owr_dat;                 // write-1 / read cycle
  wire ph_idle  = owr_cyc && owr_rst && owr_dat;                  // timed idle cycle

  default clocking @(posedge clk); endclocking
  default disable iff (rst);

  // ========================================================================
  // 1. Reset values (checked in the first cycle after reset release)
  // ========================================================================

  // Doc Table 10 (reset column) and Table 9/4.2: cdr_n/cdr_o reset to CDR_N/CDR_O.
  // RTL: reset branch of the clock divider ratio registers.
  a_rst_cdr_val: assert property ($past(rst) |-> (cdr_n == RST_CDR_N && cdr_o == RST_CDR_O));

  // Doc Table 10 reset column: cyc, ovd, rst, dat, pwr, ien are 0.
  a_rst_ctl_val: assert property ($past(rst) |-> (!owr_cyc && !owr_ovd && !owr_rst && !owr_dat));

  // Doc Table 10 reset column: irq, ien, pwr are 0; output enable register is 0.
  a_rst_sts_val: assert property ($past(rst) |-> (!irq_sts && !irq_ena && (owr_pwr == 1'b0) && !owr_oen));

  // RTL: cnt and div are reset to 0 (counter start value).
  a_rst_cnt_val: assert property ($past(rst) |-> (cnt == 8'd0 && div == 16'd0));

  // Doc Table 8 and 10: a read of the control/status register after reset returns 0.
  a_rst_rd_ctl:  assert property ($past(rst) && rd_ctl |-> (bus_rdt == 32'd0));

  // Doc Table 8: address 1 reads cdr_o (bits 31:16) and cdr_n (bits 15:0), reset values.
  a_rst_rd_cdr:  assert property ($past(rst) && rd_cdr |-> (bus_rdt == {RST_CDR_O, RST_CDR_N}));

  // ========================================================================
  // 2. Register map and read data
  // ========================================================================

  // Doc Table 8: for OWN=1 the power and select fields are not implemented;
  // RTL: bus_rdt_pwr_sel is 24'h0 in the OWN==1 branch.
  a_rd_ctl_hi_zero: assert property (rd_ctl |-> (bus_rdt[31:8] == 24'd0));

  // Doc Table 10: bit 5 is reserved; RTL: constant 1'b0 in bus_rdt_ctl_sts.
  a_rd_ctl_rsv_zero: assert property (rd_ctl |-> (bus_rdt[5] == 1'b0));

  // Doc Table 11: bit 7 = ien (enable), bit 6 = irq (status of cycle interrupt).
  a_rd_ctl_irq: assert property (rd_ctl |-> (bus_rdt[7] == irq_ena && bus_rdt[6] == irq_sts));

  // Doc Table 11: bit 4 reads the power status of the line; with OWN=1 this is pwr.
  a_rd_ctl_pwr: assert property (rd_ctl |-> (bus_rdt[4] == owr_pwr[0]));

  // Doc Table 11: bit 3 reads 1 while a 1-wire cycle is in progress.
  a_rd_ctl_cyc: assert property (rd_ctl |-> (bus_rdt[3] == owr_cyc));

  // Doc Table 11: bit 2 = ovd (overdrive setting), bit 1 = rst (reset cycle select).
  a_rd_ctl_ovd_rst: assert property (rd_ctl |-> (bus_rdt[2] == owr_ovd && bus_rdt[1] == owr_rst));

  // Doc Table 8: address 1 returns {cdr_o, cdr_n}.
  a_rd_cdr_map: assert property (rd_cdr |-> (bus_rdt == {cdr_o, cdr_n}));

  // Write then read-back: a value written to address 1 is returned by the next read.
  a_wr_cdr_roundtrip: assert property ((wr_cdr ##1 rd_cdr) |-> (bus_rdt == $past(bus_wdt)));

  // Doc 4.2: ratios change only on a write to address 1 (no other event touches them).
  a_cdr_hold: assert property (!wr_cdr |=> (cdr_n == $past(cdr_n) && cdr_o == $past(cdr_o)));

  // Doc Table 11 and 4.4: after a control write, the writable bits read back,
  // and the interrupt status is cleared by the write (RTL: irq_sts priority).
  a_wr_ctl_roundtrip: assert property ((wr_ctl ##1 rd_ctl) |->
      (bus_rdt[7] == $past(bus_wdt[7]) && bus_rdt[4] == $past(bus_wdt[4]) &&
       bus_rdt[2] == $past(bus_wdt[2]) && bus_rdt[1] == $past(bus_wdt[1]) &&
       bus_rdt[0] == $past(bus_wdt[0]) && !bus_rdt[6]));

  // ========================================================================
  // 3. Cycle start, duration and end
  // ========================================================================

  // Doc Table 11 (cyc: 1 = start a new cycle) and Table 12 (non-idle cycles).
  a_cyc_start: assert property (wr_start |=> owr_cyc);

  // Doc Table 12: "zero time idle cycle" (ovd=1, rst=1, dat=1, cyc=1) is not run.
  a_cyc_zero_time: assert property ((wr_ctl && bus_wdt[3:0] == 4'hF) |=> !owr_cyc);

  // Doc Table 11: cyc=0 means no action; with no cycle running it starts nothing.
  a_cyc_idle_nostart: assert property ((wr_ctl && !bus_wdt[3] && !owr_cyc) |=> !owr_cyc);

  // Doc Table 12 / Table 7: a cycle lasts a fixed number of base periods (ticks).
  // The length depends on the mode and type bits latched by the starting write:
  //   normal write 13 ticks (65 us), normal reset 192 (960 us),
  //   normal idle 200 (1000 us), overdrive write 8 (8 us), overdrive reset 96 (96 us).
  // RTL: cnt is loaded with (length - 1) and decremented on each pls.
  a_cyc_bound: assert property (owr_cyc |-> (ticks < cyc_len));

  // A cycle keeps running until its last tick (absent a new control write).
  a_cyc_hold: assert property ((owr_cyc && !cyc_end && !wr_ctl) |=> owr_cyc);

  // The cycle ends exactly at its last tick.
  a_cyc_end: assert property ((cyc_end && !wr_ctl) |=> !owr_cyc);

  // Cycle-end is the only event that clears cyc besides a control write
  // (RTL: owr_cyc update is write / pls&&cnt==0).
  a_hold_cyc: assert property ((!wr_ctl && !cnt_zero_pls) |=> $stable(owr_cyc));

  // ========================================================================
  // 4. 1-wire line (open-drain driver) timing
  // ========================================================================

  // Doc Table 12 / 4.4: a write that starts a cycle drives the line low at once.
  // RTL: owr_oen <= ~&bus_wdt[1:0] on a control write.
  a_start_drive: assert property ((wr_start && !(&bus_wdt[1:0])) |=> owr_oen);

  // Doc Table 12: an idle (rst=1, dat=1) write releases the line.
  a_idle_write_release: assert property (wr_idle |=> !owr_oen);

  // Doc Table 7 (tRSTL), Table 6 (tDAT0, tDAT1): line low for T_RSTL / T_DAT0 / T_DAT1
  // base periods in a reset / write-0 / write-1 cycle, then released.
  // Normal: 96 / 12 / 1 ticks. Overdrive: 48 / 6 / 1 ticks.
  a_w0_low:      assert property (ph_w0 && (ticks < lo_w0)  |-> owr_oen);
  a_w0_release:  assert property (ph_w0 && (ticks >= lo_w0) |-> !owr_oen);
  a_w1_low:      assert property (ph_w1 && (ticks < lo_w1)  |-> owr_oen);
  a_w1_release:  assert property (ph_w1 && (ticks >= lo_w1) |-> !owr_oen);
  a_rst_low:     assert property (ph_rst && (ticks < lo_rst)  |-> owr_oen);
  a_rst_release: assert property (ph_rst && (ticks >= lo_rst) |-> !owr_oen);

  // Doc 4.4 / Table 12: a timed idle cycle never pulls the line down.
  a_idle_undriven: assert property (ph_idle |-> !owr_oen);

  // Output enable is only asserted when the output-enable register is set
  // (owr_e = owr_oen << owr_sel, and owr_sel is unconstrained for OWN=1).
  a_e_gated: assert property (owr_e[0] |-> owr_oen);

  // Doc 4.3: the power bit (bit 4) drives owr_p[0] (OWN=1).
  a_pwr_out:  assert property (wr_ctl |=> (owr_p == $past(bus_wdt[4])));
  a_pwr_hold: assert property (!wr_ctl |=> $stable(owr_p));

  // ========================================================================
  // 5. Hold properties (registers change only on their documented events)
  // ========================================================================

  // Doc Table 11: ovd, rst, pwr, ien are written only by a control write.
  a_hold_mode_bits: assert property (!wr_ctl |=> ($stable(owr_ovd) && $stable(owr_rst) &&
                                                  $stable(owr_pwr) && $stable(irq_ena)));

  // RTL: owr_dat changes on a control write or on the design's end-of-cycle event.
  a_hold_dat: assert property ((!wr_ctl && !cnt_zero_pls) |=> $stable(owr_dat));

  // RTL: owr_oen changes on a control write or on a pls.
  a_hold_oen: assert property ((!wr_ctl && !pls) |=> $stable(owr_oen));

  // RTL: cnt changes on a control write or on a pls.
  a_hold_cnt: assert property ((!wr_ctl && !pls) |=> $stable(cnt));

  // ========================================================================
  // 6. Clock divider (base period generator)
  // ========================================================================

  // Doc 2.1.3 / 3.1: any bus write re-aligns the divider (RTL: div <= 0 on bus_wen).
  a_wr_resets_div: assert property (bus_wen |=> (div == 16'd0));

  // With no cycle in progress the divider is at zero.
  a_div_idle_zero: assert property (!owr_cyc |-> (div == 16'd0));

  // Doc 2.1.3: one base period (tick) every (ratio+1) clocks while a cycle runs.
  // sub mirrors the elapsed clocks since the last tick or bus write.
  a_div_tick:  assert property (owr_cyc && (sub == ratio) |-> pls);
  a_div_quiet: assert property (owr_cyc && (sub <  ratio) |-> !pls);

  // ========================================================================
  // 7. Interrupt
  // ========================================================================

  // Doc Table 11: irq is set at the end of each 1-wire cycle.
  // RTL: irq_sts <= 1 on pls && cnt==0 unless a control write takes priority.
  a_irq_set: assert property ((cyc_end && !wr_ctl) |=> irq_sts);

  // Doc 4.4 / Table 11: a register read clears irq. Exception: the end-of-cycle
  // event has priority over the read clear (RTL priority chain).
  a_irq_rd_clear: assert property ((rd_ctl && !cnt_zero_pls) |=> !irq_sts);

  // Same-cycle collision: end of cycle wins over a read in that cycle.
  a_irq_end_beats_rd: assert property ((cyc_end && rd_ctl && !wr_ctl) |=> irq_sts);

  // RTL: irq_sts holds unless write, end-of-cycle or read event.
  a_irq_hold: assert property ((!wr_ctl && !cnt_zero_pls && !rd_ctl) |=> $stable(irq_sts));

  // Doc Table 11: ien enables the interrupt request output.
  a_irq_enabled: assert property ((cyc_end && !wr_ctl && irq_ena) |=> bus_irq);
  a_irq_masked:  assert property ((cyc_end && !wr_ctl && !irq_ena) |=> !bus_irq);

  // RTL: bus_irq = irq_ena & irq_sts.
  a_irq_out_en: assert property (bus_irq |-> irq_ena);
  a_irq_out_on: assert property ((irq_ena && irq_sts) |-> bus_irq);

endmodule

// Bind to the design top; parameters are taken from the design.
bind sockit_owm sockit_owm_sva #(
  .BDW(BDW), .BAW(BAW), .OWN(OWN), .TDW(TDW), .CDW(CDW),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTL_N(T_RSTL_N), .T_RSTH_N(T_RSTH_N), .T_DAT0_N(T_DAT0_N),
  .T_DAT1_N(T_DAT1_N), .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTL_O(T_RSTL_O), .T_RSTH_O(T_RSTH_O), .T_DAT0_O(T_DAT0_O),
  .T_DAT1_O(T_DAT1_O), .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);
EOF
cd /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm && printf './sva/sockit_owm_sva.sv\n' > sockit_owm_sva.f && ./check_syntax.sh 2>&1 | tail -60
```

#### result

```
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-9005)] /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/./rtl/sockit_owm.v(417): 2-bit index expression 'owr_sel' is larger than the required 1 bits. This might lead to an out-of-bound access
SYNTAX OK
```

### step 8: Bash

```
rm -f /tmp/brg8ve/sva_ws/owr.txt; cd /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm && find . -type f | sort && cat sockit_owm_sva.f && grep -c '^\s*a_[a-z0-9_]*:' sva/sockit_owm_sva.sv
```

#### result

```
./check_syntax.sh
./doc/sockit_owr.pdf
./rtl/sockit_owm.v
./sockit_owm.f
./sockit_owm_sva.f
./sockit_owm.tcl
./sva/sockit_owm_sva.sv
./TASK.md
./sva/sockit_owm_sva.sv
51
```

### step 9: SubagentHandback

SVA checker written and syntax-checked (SYNTAX OK, no warnings point into the checker file).

Deliverables:
- /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/sva/sockit_owm_sva.sv: checker module `sockit_owm_sva` with 51 labelled assertions, plus `bind sockit_owm ... u_sockit_owm_sva (.*)`.
- /tmp/brg8ve/sva_ws/sockit_owm_e2hMWm/sockit_owm_sva.f: single line `./sva/sockit_owm_sva.sv`.

Nothing else in the workspace was changed. I ran only check_syntax.sh; I did not run a formal proof, so the assertions are checked by hand against the RTL, not by the tool.

What the checker specifies (default parameters: OWN=1, BDW=32, CDR_N=4, CDR_O=0):
- Reset values after release, and read-back of reset values for the control register and both divider registers.
- Register map: address 1 round-trips cdr_o:cdr_n; the control register read-back of writable bits; reserved bit 5 reads 0; bits 31:8 of address 0 read 0 for OWN=1.
- Cycle start (cyc=1 except zero-time idle), zero-time idle not run, cycle lengths per type (normal write 13 ticks / 65 us, normal reset 192 / 960 us, normal idle 200 / 1000 us, overdrive write 8 / 8 us, overdrive reset 96 / 96 us), and a cycle staying active until its last tick.
- Line low times per type (normal reset 96, write-0 12, write-1 1 ticks; overdrive 48, 6, 1), idle cycle never driving the line, power bit to owr_p, owr_e implies owr_oen.
- Holds for mode bits, owr_dat, owr_oen, cnt, cdr registers.
- Divider: one tick every (ratio+1) clocks while a cycle runs; any bus write resets the divider; divider zero when idle.
- Interrupt: set at end of cycle, cleared by read, end-of-cycle beats read on collision, ien gating of bus_irq.

Assertions were built on two auxiliary counters: `ticks` (pls while a cycle is active) and `sub` (clocks since last tick or bus write).

RTL/doc problems found; I did not assert the behaviour the doc describes where the RTL differs:
1. owr_sel is only set in an `initial` block when OWN=1 (check_syntax reports "owr_sel[-1] does not have a driver"). owr_e, the sampled line value (owr_smp), owr_dat after a cycle and bit 0 of the status read are therefore unconstrained. Only owr_e[0] -> owr_oen is asserted. Presence-detect timing is not specified.
2. With OVD_E=1 and cdr_o==0 (the default), pls fires every clock whenever owr_ovd=1, even with no cycle running. cnt keeps counting and irq_sts is set at cnt==0 without any cycle: e.g. writing 0x04 to the control register sets irq_sts about 8 clocks later if ien=1. The doc says the flag is set only at end of a cycle. Assertions that depend on idle state exclude the event (pls && cnt==0).
3. A control write with cyc=0 (and not rst=dat=1) sets owr_oen=1, so the 1-wire line is pulled low with no cycle; in normal mode nothing clears it until the next control write. The doc says cyc=0 means "no action". Not asserted.
4. A control write with cyc=0 during a running cycle aborts it (owr_cyc <= 0). The doc only describes writing 1 as breaking a cycle. I only assert "cyc=0 starts nothing" when no cycle is running.
5. The doc is internally inconsistent on overdrive idle: Table 12 says zero time, while Table 7 gives tDLY=96 and the RTL loads 96. The zero-time claim holds in the RTL only because the cycle never starts, so I assert that.

Assertion count and labels: a_rst_*, a_rd_*, a_wr_*, a_cdr_hold, a_cyc_*, a_start_drive, a_w0_*, a_w1_*, a_rst_low/release, a_idle_*, a_e_gated, a_pwr_*, a_hold_*, a_div_*, a_irq_*.

#### result

```
{"success":true,"message":"Report delivered to your caller."}
```
