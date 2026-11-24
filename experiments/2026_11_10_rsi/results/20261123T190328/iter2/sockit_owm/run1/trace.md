# Generator trace

source: /tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tasks/ad814ce420275c4c1.output

note: 5 thinking block(s) were stored without text.

### step 1: Bash

```
cat /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/TASK.md
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
... [7815 more chars]
```

### step 2: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx && find . -type f | head -100 && echo --- && cat *.tcl && echo --- && cat *.f && echo --- && cat check_syntax.sh
```

#### result

```
./sockit_owm.f
./sockit_owm.tcl
./check_syntax.sh
./TASK.md
./rtl/sockit_owm.v
./doc/sockit_owr.pdf
---
clear -all


analyze -v2k -f sockit_owm.f

if { [file exists sockit_owm_sva.f] == 1 } {
	analyze -sv -f sockit_owm_sva.f
}

# Blackbox missing modules instead of erroring out
elaborate -bbox 1
clock clk
reset rst==1'b1





---
./rtl/sockit_owm.v
---
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
```

### step 3: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx && cat -n rtl/sockit_owm.v && cat sockit_owm.f && echo --- && pdftotext -layout doc/sockit_owr.pdf - | wc -l
```

#### result

```
     1	//////////////////////////////////////////////////////////////////////////////
     2	//                                                                          //
     3	//  Minimalistic 1-wire (onewire) master with Avalon MM bus interface       //
     4	//                                                                          //
     5	//  Copyright (C) 2010  Iztok Jeras                                         //
     6	//                                                                          //
     7	//////////////////////////////////////////////////////////////////////////////
     8	//                                                                          //
     9	//  This RTL is free hardware: you can redistribute it and/or modify        //
    10	//  it under the terms of the GNU Lesser General Public License             //
    11	//  as published by the Free Software Foundation, either                    //
    12	//  version 3 of the License, or (at your option) any later version.        //
    13	//                                                                          //
    14	//  This RTL is distributed in the hope that it will be useful,             //
    15	//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
    16	//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           //
    17	//  GNU General Public License for more details.                            //
    18	//                                                                          //
    19	//  You should have received a copy of the GNU General Public License       //
    20	//  along with this program.  If not, see <http://www.gnu.org/licenses/>.   //
    21	//                                                                          //
    22	//////////////////////////////////////////////////////////////////////////////
    23	
    24	
    25	//////////////////////////////////////////////////////////////////////////////
    26	//                                                                          //
    27	// The clock divider parameter is computed with the next formula:           //
    28	//                                                                          //
    29	// CDR_N = f_CLK * BTP_N - 1  (example: CDR_N = 1MHz * 5.0us - 1 = 5-1)     //
    30	// CDR_O = f_CLK * BTP_O - 1  (example: CDR_O = 1MHz * 1.0us - 1 = 1-1)     //
    31	//                                                                          //
    32	// If the dividing factor is not a round integer, than the timing of the    //
    33	// controller will be slightly off, and would support only a subset of      //
    34	// 1-wire devices with timing closer to the typical 30us slot.              //
    35	//                                                                          //
    36	// Base time periods BTP_N = "5.0" and BTP_O = "1.0" are optimized for      //
    37	// onewire timing. The default timing restricts the r
... [17601 more chars]
```

### step 4: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx && pdftotext -layout doc/sockit_owr.pdf - | sed -n '1,600p'
```

### step 5: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx && pdftotext -layout doc/sockit_owr.pdf - | sed -n '601,1214p'
```

#### result

```
<persisted-output>
Output too large (35.9KB). Full output saved to: /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/bsjp8q117.txt

Preview (first 2KB):
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
...
</persisted-output>
```

#### result

```
Table 12: List of supported cycles
 ovd   rst    dat timing     description
  0      0     0    65μs     write '0' cycle
  0      0     1    65μs     write '1' cycle or read cycle
  0      1     0    960μs    reset and presence detect cycle
  0      1     1    1000μs timed idle cycle, can be used to generate timed delays
  1      0     0    8μs      overdrive write '0' cycle
  1      0     1    8μs      overdrive write '1' cycle or read cycle
  1      1     0    96μs     overdrive reset and presence detect cycle
  1      1     1    0μs      zero time idle cycle


Bit pwr has a different meaning for write than for read. The write functionality is only implemented
if only a single 1-wire line is implemented ( OWN=1), then the write value directly controls the status
of the owr_p[0] signal. Read of pwr provides state of the selected line power (power[select] or
pwr).
Read only bit irq describes the current interrupt request status and is set at the end of each 1-wire
cycle. Interrupt status is cleared by a register read, so care must be taken to check its value on every
read. Bit ien (interrupt enable) specifies if irq will trigger an interrupt or not.

4.5 Driver access sequences
The 1-wire master can be used to perform most actions defined in the iButton specification as the
physical layer. It is possible to use polling or interrupts, both options will be described.
The reference implementation for Nios II HAL and μC/OS-II is available as source code.


                                                    15
The description uses the next pseudo functions:
   •   write (data)         - 32bit (or 8bit) write to the configuration/status register
   •   data = read () - 32bit (or 8bit) read from the configuration/status register
If clock divider ratio registers are implemented (CDR_E=1) they must be written with proper divider
ratios prior to issuing any 1-wire cycles.
Note that the provided pseudo code does not implement power delivery and is designed for a single
1-wire lane (select is not used). For a proper implementation of this functionality see the ported
public domain kit code (owlnk.c).

4.5.1 Polling routines
Polling is not an optimal implementation, but it might be useful for debugging purposes. Since
interrupts are not used '0' should be written into interrupt enable register and cycle status bit cyc is
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
  
... [24674 more chars]
```

### step 6: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx && pdftotext -layout doc/sockit_owr.pdf /tmp/brg8ve/owr_doc.txt 2>/dev/null; grep -n "" /tmp/brg8ve/owr_doc.txt | sed -n '60,260p'
```

#### result

```
60:7 Demo hardware and software implementation...............................................................................23
61:   7.1 Demo hardware.......................................................................................................................23
62:      7.1.1 Demo hardware logic consumption................................................................................23
63:   7.2 Demo software........................................................................................................................24
64:      7.2.1 Demo software memory consumption............................................................................24
65:
66:
67:                                                                          2
68:8 Testing............................................................................................................................................25
69:  8.1 Verilog RTL simulation...........................................................................................................25
70:     8.1.1 1-wire slave model..........................................................................................................25
71:     8.1.2 Verilog testbench.............................................................................................................26
72:     8.1.3 Parameter tests................................................................................................................26
73:  8.2 C driver tests...........................................................................................................................27
74:  8.3 Testing TODO.........................................................................................................................27
75:9 License............................................................................................................................................28
76:10 References....................................................................................................................................29
77:
78:
79:
80:Index of Tables
81:Table 1: File list....................................................................................................................................5
82:Table 2: List of sockit_owm module parameters..................................................................................6
83:Table 3: Base time period and base frequency options........................................................................7
84:Table 4: List of sockit_owm module ports...........................................................................................7
85:Table 5: Wishbone equivalents of Avalon MM signals........................................................................8
86:Table 6: 1-wire protocol standard timing restrictions.........................................................................11
87:Table 7: Timing options..............................................
... [11409 more chars]
```

### step 7: Bash

```
grep -n "" /tmp/brg8ve/owr_doc.txt | sed -n '261,470p'
```

#### result

```
261:owr_i        OWN     input      1-wire bus status
262:owr_e        OWN     output     1-wire open collector driver enable
263:owr_p        OWN      output  1-wire power enable (strong pull-up)
264:* for a 32 bit interface BAW=1, for an 8bit interface BAW=2
265:
266:
267:
268:
269:                                                       7
270:2.2.1 CPU bus interface
271:The default bus interface is 32bit Avalon MM compatible. It is trivial to connect it to Wishbone
272:(wishbone2bus module) and it should be easy to connect to AMBA APB. The module can be also
273:connected to an 8bit bus (a micro-controller for example).
274:
275:Table 5: Wishbone equivalents of Avalon MM signals
276:bus signal          Avalon MM signal        Wishbone signal
277:bus_wen             avalon_write            cyc & stb &       we
278:bus_ren             avalon_read             cyc & stb & ~we
279:bus_adr             avalon_address          adr
280:bus_wdt             avalon_writedata        dat_w
281:bus_rdt             avalon_readdata         dat_r
282:bus_irq             avalon_interrupt        irq
283:
284:
285:All CPU related signals are active high. Both read and write cycles are a single clock period long,
286:the omitted Avalon MM signal bus_waitrequest would be a constant '0'. Read data is valid only
287:the first cycle of bus_ren being active, it might change in the next cycle due to the interrupt status
288:being cleared.
289:The interrupt signal indicates, that a reset (with presence detection) or a read/write bit 1-wire cycle
290:has finished. After reading the control/status register the interrupt is cleared.
291:
292: clk
293: bus_wen
294: bus_ren
295: bus_adr
296: bus_wdt
297: bus_rdt
298: bus_irq
299:Drawing 1: Bus timing (read/write cycle and interrupt status)
300:
301:
302:2.2.2 1-wire interface
303:The 1-wire module requires an external open drain driver to be able to drive a bidirectional pin. The
304:owr_p signal can be used to supply extra power to the 1-wire line (for temperature conversion, ...),
305:if the signal is not used, 0 should be applied instead. The next scheme shows the driver for the i-th
306:line.
307:
308:
309:
310:
311:                                                  8
312:          owr_p[i] | owr_e[i]
313:
314:                            owr_p[i]                                       owr[i]
315:
316:                            owr_i[i]
317:Drawing 2: 1-wire line driver schematic
318:
319:The next Verilog code should be used for the i-th line on the top level of the SoC.
320:assign owr [i] = (owr_p[i] | owr_e[i]) ? owr_p[i] : 1'bz;
321:assign owr_i[i] = owr;
322:
323:
324:And if the power signal is ignored.
325:assign owr [i] = owr_e[i] ? 1'b0 : 1'bz;
326:assign owr_i[i] = owr;
327:
328:
329:On some FPGA it is possible to set driver strength at compile time. There are no extra features for
330:long 1-wire networks, but it is suggested to use weak drivers (slow slew rate) to minimize
331:transitional effects on the network. I
... [7840 more chars]
```

### step 8: Bash

```
grep -n "" /tmp/brg8ve/owr_doc.txt | sed -n '470,600p'
```

#### result

```
470:
471:
472:
473:
474:                                       tDATT
475:
476:                                       tSLOT                                     tREC
477:
478:                                       tLOW1
479:
480:                                       tDATS
481:
482:Drawing 7:
483:        6: Write 11,or
484:                     read
485:                       read
486:                          timing
487:                            timing
488:                                 diagram
489:                                   diagram
490:
491:
492:
493:                                                    12
494:4 Processor interface
495:The processor interface is described in three steps:
496:   1. address space
497:   2. clock dividers
498:   3. 1-wire line multiplexing and power enable functionality
499:   4. control/status register description
500:   5. driver access sequences (polling and interrupts)
501:The document is focused on describing the 32bit CPU interface. Some aspects of a 8bit interface are
502:mentioned, but many details are omitted.
503:
504:4.1 Address space
505:The sockit_own module is designed to be accessible by a 32bit CPU through a single 32bit register,
506:if between 1 and 16 (OWN parameter) 1-wire lines are required. If a single line is enough than all but
507:one power and all select bits have no function, and the interface can be compacted into an 8bit
508:control/status register.
509:If implemented (CDR_E=1), there are two 16bit clock divider ratio registers (cdr_n, cdr_o) one for
510:normal and one for overdrive mode.
511:
512:Table 8: 32bit interface address space
513:  address           31..24                  23..16                 15..8                7..0
514:     0                         power                          unused   select    control/status
515:     1                         cdr_o                                        cdr_n
516:
517:
518:Since all the controls are in a single register and there is no byte select signal, on every write all
519:controls must have the correct value. In software this can be achieved by having a permanent
520:structure holding the interface current state.
521:Alternatively an 8bit interface is possible. The maximum number of 1-wire lines is reduced to 4 and
522:the clock divider ratio register size is reduced to 8bit.
523:
524:Table 9: 8bit interface address space
525:  address                                                  7..0
526:     0                                          control/status
527:     1                         power                              unused              select
528:     2                                                    cdr_n
529:     3                                                    cdr_o
530:
531:
532:
533:4.2 Clock dividers
534:If clock divider ratio registers cdr_n and cdr_o are implemented (CDR_E=1) than the reset value of
535:
536:                                                     13
537:the registers will be as def
... [4624 more chars]
```

### assistant

I have the RTL and the full datasheet. Before writing the checker, I'm recording the behaviour list and the RTL facts that constrain it, since several of them rule out tempting assertions.

### step 9: Bash

```
mkdir -p /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/sva && cat > /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/sva/sockit_owm_sva.sv << 'EOF'
// ============================================================================
// SVA checker for sockit_owm (1-wire master, Avalon-style 32-bit bus).
// Specified configuration: default parameters (BDW=32, OWN=1, CDR_E=1,
// OVD_E=1, BTP_N="5.0", BTP_O="1.0"). Reset is active high (rst).
//
// Cycle durations are counted in divider pulses ("base periods"), so they
// hold for any clock-divider ratio. Properties that depend on the actual
// base period in clocks are restricted to the reset value of cdr_n.
//
// Items deliberately NOT specified (see report):
//  - bus_rdt bit 0 after a cycle, owr_smp / owr_iln / owr_e and the value
//    loaded into owr_dat at end of cycle: OWN=1 leaves owr_sel undriven, so
//    the line select and everything sampled through it is unconstrained.
//  - owr_e as an output: it is owr_oen shifted by the undriven owr_sel.
// ============================================================================
module sockit_owm_sva #(
  parameter BAW      = 1,
  parameter BDW      = 32,
  parameter OWN      = 1,
  parameter CDW      = 16,
  parameter TDW      = 8,
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
  input                  clk,
  input                  rst,
  input                  bus_wen,
  input                  bus_ren,
  input  [BAW-1:0]       bus_adr,
  input  [BDW-1:0]       bus_wdt,
  input  [BDW-1:0]       bus_rdt,
  input                  bus_irq,
  input  [OWN-1:0]       owr_p,
  input  [CDW-1:0]       div,
  input  [CDW-1:0]       cdr_n,
  input  [CDW-1:0]       cdr_o,
  input                  pls,
  input  [TDW-1:0]      cnt,
  input                  owr_cyc,
  input  [OWN-1:0]       owr_pwr,
  input                  owr_ovd,
  input                  owr_rst,
  input                  owr_dat,
  input                  owr_smp,
  input                  owr_oen,
  input                  irq_ena,
  input                  irq_sts
);

// ----------------------------------------------------------------------------
// Derived constants (base periods per cycle, from the datasheet Table 12 and
// the RTL cycle-length logic: cycle = DAT0+RCVR, RSTL+RSTH, IDLE, ...).
// ----------------------------------------------------------------------------
localparam integer LW_N   = T_DAT0_N + T_RCVR_N;   // normal write 0/1 cycle  (65us)
localparam integer LR_N   = T_RSTL_N + T_RSTH_N;   // normal reset cycle      (960us)
localparam integer LI_N   = T_IDLE_N;              // normal timed idle       (1000us)
localparam integer LW_O   = T_DAT0_O + T_RCVR_O;   // overdrive write cycle   (8us)
localparam integer LR_O   = T_RSTL_O + T_RSTH_O;   // overdrive reset cycle   (96us)
// base periods for which the line is pulled down (owr_oen high)
localparam integer LO_W0_N = T_DAT0_N;             // write 0: low for tDAT0
localparam integer LO_W1_N = T_DAT1_N;             // write 1/read: low for tDAT1
localparam integer LO_R_N  = T_RSTL_N;             // reset: low for tRSTL
localparam integer LO_W0_O = T_DAT0_O;
localparam integer LO_W1_O = T_DAT1_O;
localparam integer LO_R_O  = T_RSTL_O;

// ----------------------------------------------------------------------------
// Event helpers (interface events, not RTL conditions)
// ----------------------------------------------------------------------------
wire e_wctl = bus_wen && !bus_adr[0];     // write of control/status register
wire e_rctl = bus_ren && !bus_adr[0];     // read of control/status register
wire e_wcdr = bus_wen && bus_adr[0];      // write of clock divider register
wire e_rcdr = bus_ren && bus_adr[0];      // read of clock divider register
wire e_end  = pls && (cnt == 0);          // pulse at which a counted cycle ends

default clocking @(posedge clk); endclocking
default disable iff (rst);

// ============================================================================
// 1. Reset values (datasheet Table 10 and section 4.2/4.3)
//    Evaluated in the first cycle after reset is released.
// ============================================================================

// Table 10: all control/status bits reset to 0 (dat/bit5 are "x" in the table).
// The read-back of address 0 is therefore all zero (bits 31..8 are the unused
// power/select field, which reads 0 for OWN=1).
// Source: datasheet Table 10 / Table 8; RTL reset branches of irq_ena, irq_sts,
// owr_pwr, owr_cyc, owr_ovd, owr_rst, owr_dat.
a_rst_ctl: assert property (
  ((!rst && $past(rst)) && !bus_adr[0]) |-> (bus_rdt == 32'h0));

// Section 4.2: after reset the clock divider ratios equal CDR_N / CDR_O.
// Source: datasheet 4.2; RTL reset branch of cdr_n / cdr_o.
a_rst_cdr: assert property (
  ((!rst && $past(rst)) && bus_adr[0]) |-> (bus_rdt == {16'(CDR_O), 16'(CDR_N)}));

// Section 4.3: after reset all power bits are zero, so every line is only
// weakly pulled up (owr_p is the power enable).
// Source: datasheet 4.3; RTL reset of owr_pwr.
a_rst_pwr: assert property (
  (!rst && $past(rst)) |-> (owr_p == '0));

// Output enable and counters reset to idle. Source: RTL reset branches of
// owr_oen, div and cnt (no cycle in progress after reset).
a_rst_idle: assert property (
  (!rst && $past(rst)) |-> (!owr_oen && div == 0 && cnt == 0));

// ============================================================================
// 2. Bus read-back of written values (end-to-end)
// ============================================================================

// Table 10/11: a write to the control/status register is visible on the next
// read. Bits 7 (ien), 4 (pwr), 2 (ovd), 1 (rst), 0 (dat) are the written bits;
// bit 3 (cyc) reads back the new cycle request, and bit 6 (irq) is cleared by
// any control write. Write of 111 in bits 2..0 is a zero-time idle, which
// does not start a cycle (see section 3).
// Source: datasheet Table 10/11 and the write-priority of the control bits.
property p_wr_ctl_rb;
  logic [BDW-1:0] v;
  (e_wctl, v = bus_wdt) ##1 e_rctl |->
    (bus_rdt == {24'h0, v[7], 1'b0, 1'b0, v[4], v[3] & ~(&v[2:0]), v[2], v[1], v[0]});
endproperty
a_wr_ctl_rb: assert property (p_wr_ctl_rb);

// Section 4.2: the clock divider register written at address 1 reads back the
// same 32-bit word (cdr_o is bits 31..16, cdr_n is bits 15..0).
// Source: datasheet 4.2 and Table 8; RTL cdr_n / cdr_o write.
property p_wr_cdr_rb;
  logic [BDW-1:0] v;
  (e_wcdr, v = bus_wdt) ##1 e_rcdr |-> (bus_rdt == v);
endproperty
a_wr_cdr_rb: assert property (p_wr_cdr_rb);

// ============================================================================
// 3. Hold / stability (state changes only on interface events)
// ============================================================================

// Table 10 control bits and the power register are only written by a write to
// the control/status register.
// Source: datasheet 4.4 (bits are stored); RTL enables of irq_ena, owr_ovd,
// owr_rst and owr_pwr.
a_ctl_hold: assert property (
  !e_wctl |=> ($stable(irq_ena) && $stable(owr_ovd) && $stable(owr_rst) && $stable(owr_pwr)));

// Section 4.2: the clock divider ratios are only changed by a write to address 1.
// Source: datasheet 4.2; RTL enables bus_wen_cdr_n / bus_wen_cdr_o.
a_cdr_hold: assert property (
  !e_wcdr |=> ($stable(cdr_n) && $stable(cdr_o)));

// Data bit: changes only by a control write or by the end of a counted cycle
// (the value loaded is the sampled line state).
// Source: datasheet Table 11 (dat is the write data, then the read result at
// the end of the slot); RTL owr_dat enables.
a_dat_hold: assert property (
  (!e_wctl && !e_end) |=> $stable(owr_dat));

// The cycle status bit only changes by a control write or by the end of a
// counted cycle. Source: datasheet Table 11 (cyc); RTL owr_cyc enables.
a_cyc_hold: assert property (
  (!e_wctl && !e_end) |=> $stable(owr_cyc));

// Output enable only changes by a control write or by a base period pulse.
// Source: RTL owr_oen enables (state machine advances only on pulses).
a_oen_hold: assert property (
  (!e_wctl && !pls) |=> $stable(owr_oen));

// Counter: holds between pulses, loads on control write, decrements on pulse.
// Source: datasheet 3.1 (counter steps on each base period); RTL cnt block.
a_cnt_hold: assert property ((!e_wctl && !pls) |=> $stable(cnt));
a_cnt_step: assert property ((!e_wctl && pls) |=> ((cnt + 1'b1) == $past(cnt)));

// Sample register is only updated on a base period pulse.
// Source: datasheet 2.3 (the line is sampled at the sampling point, i.e. on a
// base period); RTL owr_smp enable.
a_smp_hold: assert property (!pls |=> $stable(owr_smp));

// ============================================================================
// 4. Clock divider (datasheet 3.1 / 4.2)
// ============================================================================

// A bus write restarts the divider.
// Source: RTL div block (bus_wen clears div).
a_div_wr: assert property (bus_wen |=> (div == 0));

// A base period pulse restarts the divider.
// Source: datasheet 3.1 (clock generator produces a pulse every base period).
a_div_pls: assert property ((!bus_wen && pls) |=> (div == 0));

// While a cycle is in progress, the divider counts one step per clock.
// Source: datasheet 3.1; RTL div increment on owr_cyc.
a_div_cnt: assert property ((!bus_wen && !pls && owr_cyc) |=> (div == ($past(div) + 1'b1)));

// Idle: the divider holds (no cycle, no pulse, no write).
// Source: datasheet 3.1; RTL div hold when owr_cyc is low.
a_div_idle: assert property ((!bus_wen && !pls && !owr_cyc) |=> $stable(div));

// Normal mode base period: with the reset ratio CDR_N (base period 5 us for
// a 1 MHz divided clock, datasheet Table 7), a normal-mode cycle's first pulse
// comes CDR_N+1 clocks after the start write and pulses repeat every CDR_N+1
// clocks. Restricted to cdr_n == CDR_N because the ratio is programmable.
// Source: datasheet 2.1.3 / Table 7; RTL pls = (div == cdr_n).
a_div_first_n: assert property (
  (e_wctl && bus_wdt[3] && !bus_wdt[2] && (cdr_n == CDR_N)) |=>
    ((!bus_wen && !pls)[*CDR_N]) ##1 pls);

a_div_next_n: assert property (
  (pls && owr_cyc && !owr_ovd && (cnt != 0) && !bus_wen && (cdr_n == CDR_N)) |=>
    ((!bus_wen && !pls)[*CDR_N]) ##1 pls);

// ============================================================================
// 5. Cycle timing (datasheet Table 12 and section 3.2). A cycle lasts exactly
//    the number of base periods given in Table 12: the pulse that completes the
//    count clears owr_cyc, and no bus write may interrupt it.
//    Durations: write0 normal 13 (65us), write1/read normal 13 (65us),
//    reset normal 192 (960us), timed idle normal 200 (1000us);
//    write0 overdrive 8 (8us), write1/read overdrive 8 (8us),
//    reset overdrive 96 (96us). Overdrive zero-time idle starts no cycle.
// ============================================================================

// Source: datasheet Table 12 row ovd=0 rst=0 dat=0 (65 us write 0 cycle).
a_cyc_w0_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1000)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LW_N]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=0 rst=0 dat=1 (65 us write 1/read cycle).
a_cyc_w1_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1001)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LW_N]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=0 rst=1 dat=0 (960 us reset cycle).
a_cyc_rst_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1010)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LR_N]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=0 rst=1 dat=1 (1000 us timed idle).
a_cyc_idl_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1011)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LI_N]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=1 rst=0 dat=0 (8 us overdrive write 0).
a_cyc_w0_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1100)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LW_O]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=1 rst=0 dat=1 (8 us overdrive write 1/read).
a_cyc_w1_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1101)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LW_O]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=1 rst=1 dat=0 (96 us overdrive reset).
a_cyc_rst_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1110)) |=>
    (((owr_cyc && !bus_wen) throughout pls[->LR_O]) ##1 !owr_cyc));

// Source: datasheet Table 12 row ovd=1 rst=1 dat=1 (0 us zero-time idle):
// writing cyc with this pattern starts no cycle.
a_cyc_zero: assert property (
  (e_wctl && (&bus_wdt[2:0])) |=> !owr_cyc);

// Source: datasheet 3.1 / Table 10 (cyc=0 on write means no cycle is started).
// RTL owr_cyc <= wdt[3] & ~&wdt[2:0].
a_cyc_nostart: assert property ((e_wctl && !bus_wdt[3]) |=> !owr_cyc);

// ============================================================================
// 6. Line drive (owr_oen) within each cycle (datasheet Table 12, 3.2).
//    Pulled down for the Table 7 low time, then released at the next cycle.
// ============================================================================

// Source: datasheet 3.2 / Table 7 (tDAT0 low for write 0).
a_drv_w0_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1000)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_W0_N]) ##1 !owr_oen));

// Source: datasheet 3.2 / Table 7 (tDAT1 low for write 1).
a_drv_w1_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1001)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_W1_N]) ##1 !owr_oen));

// Source: datasheet 3.2 / Table 7 (tRSTL low for reset).
a_drv_rst_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1010)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_R_N]) ##1 !owr_oen));

// Source: datasheet 3.2 (timed idle drives nothing).
a_drv_idl_n: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1011)) |=>
    ((!owr_oen && !bus_wen) throughout pls[->LI_N]));

// Source: datasheet 3.2 / Table 7 overdrive low times.
a_drv_w0_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1100)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_W0_O]) ##1 !owr_oen));

a_drv_w1_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1101)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_W1_O]) ##1 !owr_oen));

a_drv_rst_o: assert property (
  (e_wctl && (bus_wdt[3:0] == 4'b1110)) |=>
    (((owr_oen && !bus_wen) throughout pls[->LO_R_O]) ##1 !owr_oen));

// Source: datasheet Table 12 (zero-time idle drives nothing); RTL owr_oen <= ~&wdt[1:0].
a_drv_zero: assert property ((e_wctl && (&bus_wdt[2:0])) |=> !owr_oen);

// ============================================================================
// 7. Interrupt / status flag (datasheet Table 11 bit 6, 4.5.2)
// ============================================================================

// Source: datasheet Table 11 bit 6: status is set at the end of each 1-wire
// cycle; a control write takes priority over the set (RTL irq_sts).
a_irq_set: assert property ((owr_cyc && e_end && !e_wctl) |=> irq_sts);

// Source: datasheet Table 11 bit 6: "cleared by bus read" of the
// control/status register. A read clears unless a cycle ends in the same clock.
a_irq_rd_clr: assert property ((e_rctl && !e_end) |=> !irq_sts);

// Source: RTL irq_sts block: a control write clears the status.
a_irq_wr_clr: assert property (e_wctl |=> !irq_sts);

// Source: datasheet Table 11 bit 7 (ien: 0 disables the interrupt).
a_irq_en_lo: assert property (!irq_ena |-> !bus_irq);

// Source: datasheet Table 11 bit 6/7: a set, enabled status is an interrupt.
a_irq_en_hi: assert property ((irq_ena && irq_sts) |-> bus_irq);

// Source: datasheet 4.5.1 (polling uses cyc to detect end of cycle, and the
// status bit is visible after it). Next read after the end shows irq=1, cyc=0.
a_irq_poll: assert property (
  (owr_cyc && e_end && !e_wctl) ##1 e_rctl |-> (bus_rdt[6] && !bus_rdt[3]));

// Source: datasheet Table 11 bit 3 / 4.5.1: the end of a cycle clears cyc.
a_cyc_end: assert property ((owr_cyc && e_end && !e_wctl) |=> !owr_cyc);

// ============================================================================
// 8. Power output (datasheet 2.2.2 / 4.3, OWN=1)
// ============================================================================

// Source: datasheet 4.3 (power bit 4 drives owr_p; for OWN=1 the write value of
// pwr directly controls owr_p[0]).
a_pwr_hi: assert property ((e_wctl && bus_wdt[4]) |=> owr_p[0]);
a_pwr_lo: assert property ((e_wctl && !bus_wdt[4]) |=> !owr_p[0]);

endmodule

bind sockit_owm sockit_owm_sva #(
  .BAW(BAW), .BDW(BDW), .OWN(OWN), .CDW(CDW), .TDW(TDW),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_DAT0_N(T_DAT0_N), .T_DAT1_N(T_DAT1_N),
  .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_DAT0_O(T_DAT0_O), .T_DAT1_O(T_DAT1_O),
  .T_RCVR_O(T_RCVR_O)
) u_sockit_owm_sva (.*);
EOF
cd /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx && printf './sva/sockit_owm_sva.sv\n' > sockit_owm_sva.f && ./check_syntax.sh 2>&1 | tail -60
```

#### result

```
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-9005)] /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/./rtl/sockit_owm.v(417): 2-bit index expression 'owr_sel' is larger than the required 1 bits. This might lead to an out-of-bound access
SYNTAX OK
```

### assistant

Syntax check passes and no warning points into the checker. Next I'm removing my scratch copy of the datasheet text, which I had written outside the workspace, and confirming the workspace contains only the two deliverables.

### step 10: Bash

```
rm -f /tmp/brg8ve/owr_doc.txt; cd /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx && find . -newer TASK.md -type f | sort && cat sockit_owm_sva.f && ./check_syntax.sh | tail -1
```

#### result

```
./sockit_owm_sva.f
./sva/sockit_owm_sva.sv
./sva/sockit_owm_sva.sv
SYNTAX OK
```

### step 11: SubagentHandback

SVA checker for sockit_owm is written and `./check_syntax.sh` prints SYNTAX OK. No warning points into the checker file.

Deliverables (workspace /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx):
- /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/sva/sockit_owm_sva.sv: module `sockit_owm_sva` plus `bind sockit_owm ... u_sockit_owm_sva (.*)`, passing the design's parameters (BAW, BDW, OWN, CDW, TDW, CDR_N/O, T_* values).
- /tmp/brg8ve/sva_ws/sockit_owm_Qxa6qx/sockit_owm_sva.f: one line `./sva/sockit_owm_sva.sv`

Nothing in rtl/ or doc/ was modified. Only the syntax check was run, so the properties are hand-verified against the RTL and datasheet, not proven by a formal run.

What the checker specifies (default config, reset active high, `disable iff (rst)`):
- Reset values: ctl/status reads 0 at address 0; cdr reads {CDR_O, CDR_N} at address 1; owr_p = 0; owr_oen, div, cnt = 0.
- Write/read-back: a ctl write reads back ien, pwr, cyc (wdt[3] & ~&wdt[2:0]), ovd, rst, dat, with irq cleared; a cdr write reads back the full word.
- Holds: ctl bits and pwr change only on ctl writes; cdr only on writes to address 1; dat, cyc, owr_oen, cnt, owr_smp only on their documented events.
- Divider: cleared by writes and pulses, counts while a cycle runs, holds when idle; normal-mode first pulse and period (restricted to cdr_n == CDR_N, since the ratio is programmable).
- Cycle length per Table 12, counted in base-period pulses (so valid for any ratio): normal write0/write1 13, reset 192, timed idle 200; overdrive write 8, reset 96; cyc drops after the last pulse and no bus write may interrupt. Zero-time idle and cyc=0 writes start no cycle.
- Line drive (owr_oen) low for DAT0/DAT1/RSTL base periods per Table 7 for each type; idle drives nothing; zero-time idle drives nothing.
- Interrupt: set at cycle end (unless a ctl write), cleared by a ctl read (unless a cycle ends that clock), cleared by ctl write, bus_irq = ien & irq, and a poll after the end sees irq=1 and cyc=0. Cycle end clears cyc.
- Power: a pwr write drives owr_p[0] the next cycle.

Not specified, and why:
- owr_e, owr_i, owr_smp values, presence sampling, and the value loaded into owr_dat at cycle end: owr_sel is never assigned when OWN=1 (the RTL's own warning says it has no driver), so the line select and everything sampled through it are unconstrained. owr_e is not asserted at all for this reason.
- Overdrive timing properties are pulse-count based only. With CDR_O=0 the first pulse lands one clock after the start, which the pulse-count form handles.

RTL/datasheet discrepancies I found (not asserted, since the RTL does not satisfy them):
1. Spurious interrupts while idle in overdrive. With owr_ovd=1 and cdr_o=0, pls = (div == cdr_o) is high every clock even with no cycle, so cnt wraps. Every 256 clocks `pls & cnt==0` sets irq_sts, loads owr_dat, and can change owr_oen. This happens after any overdrive cycle, and after a zero-time idle write. The checker avoids claiming that irq_sts only sets at cycle end.
2. A ctl write with cyc=0 and rst=dat=0 sets owr_oen=1 (the RTL ignores cyc in `owr_oen <= ~&wdt[1:0]`), so the line is pulled low with no cycle. In normal mode nothing clears it, so it stays low. The datasheet says cyc=0 means "no action".
3. A ctl write with cyc=0 also clears an in-progress cycle (owr_cyc <= 0). The datasheet's "no action" wording suggests the cycle should continue. The checker asserts only the RTL behaviour (cyc reads 0 after such a write).

Items 1 and 2 are the more consequential findings for the design.

#### result

```
{"success":true,"message":"Report delivered to your caller."}
```
