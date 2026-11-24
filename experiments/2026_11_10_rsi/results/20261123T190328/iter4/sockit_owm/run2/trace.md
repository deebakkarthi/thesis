# Generator trace

source: /tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tasks/a01d5b9335b3ab1fb.output

note: 5 thinking block(s) were stored without text.

### step 1: Bash

```
cat /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/TASK.md
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
... [9337 more chars]
```

### step 2: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r && ls -la && find . -type f | head -100 && cat *.tcl *.f 2>/dev/null; cat check_syntax.sh
```

#### result

```
total 32
drwx------  4 brg8ve users   108 Nov 23 20:23 .
drwxr-xr-x 14 brg8ve users  4096 Nov 23 20:23 ..
-rwxr-xr-x  1 brg8ve users   846 Nov 23 20:23 check_syntax.sh
drwxr-xr-x  2 brg8ve users    28 Nov 23 20:23 doc
drwxr-xr-x  2 brg8ve users    26 Nov 23 20:23 rtl
-rw-r--r--  1 brg8ve users    19 Nov 23 20:23 sockit_owm.f
-rw-r--r--  1 brg8ve users   224 Nov 23 20:23 sockit_owm.tcl
-rw-r--r--  1 brg8ve users 12356 Nov 23 20:23 TASK.md
./sockit_owm.f
./sockit_owm.tcl
./check_syntax.sh
./TASK.md
./rtl/sockit_owm.v
./doc/sockit_owr.pdf
clear -all


analyze -v2k -f sockit_owm.f

if { [file exists sockit_owm_sva.f] == 1 } {
	analyze -sv -f sockit_owm_sva.f
}

# Blackbox missing modules instead of erroring out
elaborate -bbox 1
clock clk
reset rst==1'b1





./rtl/sockit_owm.v
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
cd /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r && wc -l rtl/sockit_owm.v && cat -n rtl/sockit_owm.v && pdftotext -layout doc/sockit_owr.pdf - | wc -l
```

#### result

```
419 rtl/sockit_owm.v
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
    37	// onewire timing. The default t
... [17599 more chars]
```

### step 4: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r && pdftotext -layout doc/sockit_owr.pdf - | sed -n 1,620p
```

#### result

```
<persisted-output>
Output too large (37KB). Full output saved to: /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/bhqs6755s.txt

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

### step 5: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r && pdftotext -layout doc/sockit_owr.pdf /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/scratchpad_doc.txt 2>/dev/null; pdftotext -layout doc/sockit_owr.pdf - | sed 's/[ \t]*$//' | cat -s | sed -n 60,420p
```

#### result

```
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
Table 6: 1-wire protocol standard timing restrictions.........................................................................11
Table 7: Timing options......................................................................................................................11
Table 8: 32bit interface address space................................................................................................13
Table 9: 8bit interface address space..................................................................................................13
Table 10: Control/status register structure..........................................................................................14
Table 11: Control/status register bits with descriptions......................................................................14
Table 12: List of supported cycles..................................................................................................
... [19941 more chars]
```

### step 6: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r && pdftotext -layout doc/sockit_owr.pdf - | sed 's/[ \t]*$//' | cat -s | sed -n 420,640p
```

#### result

```
                                       tDATT

                                       tSLOT                                     tREC

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
The sockit_own module is designed to be accessible by a 32bit CPU through a single 32bit register,
if between 1 and 16 (OWN parameter) 1-wire lines are required. If a single line is enough than all but
one power and all select bits have no function, and the interface can be compacted into an 8bit
control/status register.
If implemented (CDR_E=1), there are two 16bit clock divider ratio registers (cdr_n, cdr_o) one for
normal and one for overdrive mode.

Table 8: 32bit interface address space
  address           31..24                  23..16                 15..8                7..0
     0                         power                          unused   select    control/status
     1                         cdr_o                                        cdr_n

Since all the controls are in a single register and there is no byte select signal, on every write all
controls must have the correct value. In software this can be achieved by having a permanent
structure holding the interface current state.
Alternatively an 8bit interface is possible. The maximum number of 1-wire lines is reduced to 4 and
the clock divider ratio register size is reduced to 8bit.

Table 9: 8bit interface address space
  address                                                  7..0
     0                                          control/status
     1                         power                              unused              select
     2                                                    cdr_n
     3                                                    cdr_o

4.2 Clock dividers
If clock divider ratio registers cdr_n and cdr_o are implemented (CDR_E=1) than the reset value of

                                                     13
the registers will be as defined by CDR_N and CDR_O parameters, and the registers can be written to
with new divider ratios while there is no 1-wire cycle in progress. If the registers are not
implemented (CDR_E=0) than a read will provide values defined by parameters and writes will be
ignored.

4.3 1-wire 
... [9225 more chars]
```

### step 7: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r && pdftotext -layout doc/sockit_owr.pdf - | sed 's/[ \t]*$//' | cat -s | sed -n 640,760p
```

#### result

```
alternative threads that can be executed while waiting for the interrupt (or waiting for temperature
conversion to finish).
Since the 1-wire bus can be accessed from more than one task, a locking mechanism is required, so
that higher level protocol sequences are not corrupted. Only locking of low level transfers is
described here. Locking for higher protocol layers is provided by the "public domain kit".
The provided pseudo code is for a pseudo OS, to implement the driver for a real OS, many OS
specific details related to task and IO scheduling must be taken into account. The OS must provide
the next functions (and others for initialization):
   •   os_sem_lck (sem) - lock the resource (it becomes unavailable to other tasks)
   •   os_sem_rel (sem) - release the resource lock

   •   os_io_wait (flag) - return the CPU to the OS and wait for IO data for flag
   •   os_io_done (flag) - tell the OS IO data for flag is available, this will end the wait
The main detail to be careful about is interrupt status bits being cleared by a status register read.

Reset and presence pulses, read/write data slots
The functions for reset pulses and data slots are similar to the polling versions. The busy wait while
loop is replaced with the os_io_wait function that returns the CPU to the OS and waits for an IO
event (interrupt) when the CPU is returned to the 1-wire driver. The 1-wire cycle is also wrapped
into a semaphore based lock preventing a different task from disrupting the cycle.

                                                   17
bool owr_reset (bool overdrive)
{
  os_sem_lck (sem);
  write (0x80 | 0x08 | (overdrive << 2) | 0x02);
  os_flag_wait (flag);
  os_sem_rel (sem);
  reg = ;
  return (read() & 0x01);
}

bool owr_slot (bool overdrive, bool bit)
{
  os_sem_lck (sem);
  write (0x80 | 0x08 | (overdrive << 2) | bit);
  os_flag_wait (flag);
  os_sem_rel (sem);
  return (read() & 0x01);
}

OS initialization and interrupt service routine
The HAL or OS must declare and initialize the semaphore and flag and register the interrupt service
routine.

os_type_sem sem;
os_type_flag flag;

os_create_sem (sem);
os_create_flag (flag);

os_irq_register (irq_sockit_owm);

The interrupt service routine must clear the interrupt (by reading the status register) and using the
flag tell the OS that the wait for data has ended.

void irq_sockit_owm ()
{
  read();
  os_io_done (flag);
}

                                                 18
5 Software driver
A port of the Public Domain Kit (version 3.10r2) to Nios II HAL and μC/OS-II real time OS is
available with the sockit_owr component. This section describes this port, and how it can be
extended.

5.1 Port of Public Domain Kit components to Nios II HAL and μC/OS-II
The port is done based on instructions from Altera and Maxim.

5.1.1 Nios II HAL and μC/OS-II drivers
The integration into Nios II software development environment is done with a TCL script and C
source and header files. The integration is done based on i
... [2600 more chars]
```

### assistant

Read the task, the RTL and the datasheet text. Before writing the checker I'm noting the RTL facts that constrain it:

- `owr_sel` is only assigned in an `initial` block when `OWN==1`, so the line-select index and `owr_e`/`owr_iln` are unconstrained. I can only assert `owr_e -> owr_oen`, not values that depend on the select.
- With the default `CDR_O=0`, once an overdrive cycle has ended the divider free-runs (`pls` is true every clock). That makes `irq_sts` and `owr_dat` change while idle, so I can't assert quiet-time behaviour unconditionally in overdrive.
- Timing windows are counted in clocks since the last bus write (`qc`), and I use `kind` to record the type of the last cycle start. Windows exclude bus writes, since writes restart the divider.

Writing the checker now.

### step 8: Bash

```
mkdir -p /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/sva && cat > /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/sva/sockit_owm_sva.sv << 'EOF'
// SVA checker for sockit_owm (1-wire master), default parameters:
// OVD_E=1, CDR_E=1, BDW=32, OWN=1, BTP_N="5.0", BTP_O="1.0"
// => CDR_N=4, CDR_O=0, normal-mode tick = 5 clocks, overdrive tick = 1 clock.
// Sources: doc sections 2.2, 4.1-4.5 and Tables 8-12 (datasheet), rtl/sockit_owm.v.
//
// Timing reference used below: a control write with cyc=1 is sampled at edge E0.
// qc (auxiliary) equals k-1 at the sample of edge Ek when no bus write occurred
// in E1..E(k-1). Cycle length in clocks is (ticks) * (ratio+1):
//   normal write-0/write-1 : 13 ticks x 5 = 65 clocks (tDAT0+tREC)
//   normal reset           : 192 ticks x 5 = 960 clocks (tRSTL+tRSTH, 960us)
//   normal timed idle      : 200 ticks x 5 = 1000 clocks (tDLY, 1000us)
//   overdrive write-0/1    : 8 ticks x 1 = 8 clocks (8us)
//   overdrive reset        : 96 ticks x 1 = 96 clocks (96us)
module sockit_owm_sva #(
  parameter BDW   = 32,
  parameter BAW   = 1,
  parameter OWN   = 1,
  parameter OVD_E = 1,
  parameter CDW   = 16,
  parameter TDW   = 8,
  parameter CDR_N = 4,
  parameter CDR_O = 0
)(
  input                clk,
  input                rst,
  input                bus_ren,
  input                bus_wen,
  input  [BAW-1:0]     bus_adr,
  input  [BDW-1:0]     bus_wdt,
  input  [BDW-1:0]     bus_rdt,
  input                bus_irq,
  input  [OWN-1:0]     owr_p,
  input  [OWN-1:0]     owr_e,
  input  [OWN-1:0]     owr_pwr,
  input                owr_ovd,
  input                owr_rst,
  input                owr_dat,
  input                owr_cyc,
  input                owr_oen,
  input                irq_ena,
  input                irq_sts,
  input  [CDW-1:0]     div,
  input  [CDW-1:0]     cdr_n,
  input  [CDW-1:0]     cdr_o,
  input  [TDW-1:0]     cnt,
  input                pls
);

default clocking @(posedge clk); endclocking
default disable iff (rst);

//////////////////////////////////////////////////////////////////////////////
// auxiliary logic
//////////////////////////////////////////////////////////////////////////////

// control/status register write (address 0)
wire ctl_wr = bus_wen && (bus_adr == 0);

// clocks since the last bus write (saturating)
reg [10:0] qc;
// type of the last bus write if it started a 1-wire cycle with default ratios
// 0 none, 1 normal write0, 2 normal write1, 3 normal reset, 4 normal timed idle,
// 5 overdrive write0, 6 overdrive write1, 7 overdrive reset
reg [2:0]  kind;

wire dflt_n = (cdr_n == CDR_N);
wire dflt_o = (cdr_o == CDR_O);
wire [2:0] wc = bus_wdt[2:0];   // {ovd, rst, dat}
wire [2:0] k_of_wr =
    !(ctl_wr && bus_wdt[3])          ? 3'd0 :
    (wc == 3'd0 && dflt_n)           ? 3'd1 :
    (wc == 3'd1 && dflt_n)           ? 3'd2 :
    (wc == 3'd2 && dflt_n)           ? 3'd3 :
    (wc == 3'd3 && dflt_n)           ? 3'd4 :
    (wc == 3'd4 && dflt_o)           ? 3'd5 :
    (wc == 3'd5 && dflt_o)           ? 3'd6 :
    (wc == 3'd6 && dflt_o)           ? 3'd7 : 3'd0;   // 3'd7 = zero-time idle, no cycle

wire k_nb0 = (kind == 3'd1);
wire k_nb1 = (kind == 3'd2);
wire k_nb  = k_nb0 || k_nb1;
wire k_nr  = (kind == 3'd3);
wire k_ni  = (kind == 3'd4);
wire k_ob0 = (kind == 3'd5);
wire k_ob1 = (kind == 3'd6);
wire k_ob  = k_ob0 || k_ob1;
wire k_or  = (kind == 3'd7);

always @(posedge clk) begin
  if (rst) begin
    qc   <= 11'd0;
    kind <= 3'd0;
  end else begin
    qc <= bus_wen ? 11'd0 : ((qc == 11'h7ff) ? qc : qc + 11'd1);
    if (bus_wen) kind <= k_of_wr;
  end
end

//////////////////////////////////////////////////////////////////////////////
// reset values (datasheet Table 10 reset column, Table 8/4.2 for dividers)
//////////////////////////////////////////////////////////////////////////////

// Source: Table 10 (ien, irq, pwr, cyc, ovd, rst reset 0); RTL reset branches.
a_rst_ctl_regs: assert property (
  $past(rst) |-> (!irq_ena && !irq_sts && owr_pwr == 0 && !owr_cyc &&
                  !owr_ovd && !owr_rst && !owr_oen));

// Source: Section 4.2 - divider ratio registers reset to CDR_N / CDR_O.
a_rst_cdr: assert property ($past(rst) |-> (cdr_n == CDR_N && cdr_o == CDR_O));

// Source: RTL reset of divider/counter; reset state is idle.
a_rst_div_cnt: assert property ($past(rst) |-> (div == 0 && cnt == 0));

// Source: Section 2.2.2 / Table 10 - outputs are inactive after reset (owr_p=pwr=0,
// owr_e follows owr_oen which is 0, interrupt masked).
a_rst_outputs: assert property ($past(rst) |-> (owr_p == 0 && owr_e == 0 && bus_irq == 0));

//////////////////////////////////////////////////////////////////////////////
// control register writes (Table 11)
//////////////////////////////////////////////////////////////////////////////

// Source: Table 11 bit 7 (ien). Written value is stored.
a_wr_ien: assert property (ctl_wr |=> irq_ena == $past(bus_wdt[7]));

// Source: Table 11 bit 6 (irq is cleared by a write - write-clear has priority
// over the end-of-cycle set, so irq is 0 after any control write).
a_wr_irq_clr: assert property (ctl_wr |=> !irq_sts);

// Source: Table 11 bit 1 (rst select).
a_wr_rst: assert property (ctl_wr |=> owr_rst == $past(bus_wdt[1]));

// Source: Table 11 bit 2 (ovd); overdrive is only enabled when OVD_E.
a_wr_ovd: assert property (ctl_wr |=> owr_ovd == ($past(bus_wdt[2]) && OVD_E));

// Source: Table 11 bit 4 (pwr); for OWN=1 the write drives owr_p[0].
a_wr_pwr: assert property (ctl_wr |=> owr_p[0] == $past(bus_wdt[4]));

// Source: Table 11 bit 0 (dat write data).
a_wr_dat: assert property (ctl_wr |=> owr_dat == $past(bus_wdt[0]));

// Source: Table 11 bit 3 / Table 12 - writing cyc=1 with a non-zero-time
// cycle type starts (or restarts, breaking a running cycle) a 1-wire cycle.
a_wr_cyc_start: assert property (
  ctl_wr && bus_wdt[3] && (bus_wdt[2:0] != 3'b111) |=> owr_cyc);

// Source: Table 12 last row - overdrive ovd=rst=dat=1 is a 0us idle cycle: it
// does not start a cycle and does not drive the line.
a_wr_zero_time: assert property (
  ctl_wr && (bus_wdt[2:0] == 3'b111) |=> (!owr_cyc && !owr_oen));

//////////////////////////////////////////////////////////////////////////////
// read-back of control register and clock divider (end-to-end)
//////////////////////////////////////////////////////////////////////////////

// Source: Table 11. A control write followed by a control read returns the
// written ien, pwr, ovd, rst, dat bits; irq and the reserved bit read 0 (the write
// cleared irq). cyc (bit 3) is covered by a_wr_cyc_start / a_wr_zero_time.
a_rd_ctl_after_wr: assert property (
  ctl_wr ##1 (bus_ren && bus_adr == 0) |->
    (bus_rdt[7] == $past(bus_wdt[7]) && bus_rdt[6] == 1'b0 && bus_rdt[5] == 1'b0 &&
     bus_rdt[4] == $past(bus_wdt[4]) &&
     bus_rdt[2] == ($past(bus_wdt[2]) && OVD_E) &&
     bus_rdt[1] == $past(bus_wdt[1]) && bus_rdt[0] == $past(bus_wdt[0])));

// Source: Table 8 - bits 31..8 of the control/status address are not implemented
// for OWN=1 and read 0.
a_rd_ctl_unused: assert property (bus_ren && bus_adr == 0 |-> bus_rdt[31:8] == 0);

// Source: Section 4.2 / Table 8 - address 1 holds {cdr_o, cdr_n}; a write then a
// read returns the written word.
a_rd_cdr_after_wr: assert property (
  (bus_wen && bus_adr == 1) ##1 (bus_ren && bus_adr == 1) |-> (bus_rdt == $past(bus_wdt)));

//////////////////////////////////////////////////////////////////////////////
// hold behaviour
//////////////////////////////////////////////////////////////////////////////

// Source: Section 4.4 - ien, rst, ovd, pwr are only changed by a control write.
a_hold_cfg: assert property (
  !ctl_wr |=> ($stable(irq_ena) && $stable(owr_rst) && $stable(owr_ovd) && $stable(owr_pwr)));

// Source: Section 4.2 - divider ratios are only changed by a write to address 1.
a_hold_cdr: assert property (
  !(bus_wen && bus_adr == 1) |=> ($stable(cdr_n) && $stable(cdr_o)));

//////////////////////////////////////////////////////////////////////////////
// clock divider and cycle counter
//////////////////////////////////////////////////////////////////////////////

// Source: Section 4.2 / RTL divider - any bus write restarts the divider phase.
a_div_restart: assert property (bus_wen |=> div == 0);

// Source: RTL divider - a divider tick restarts the divider.
a_div_pls: assert property ((pls && !bus_wen) |=> div == 0);

// Source: RTL divider - the divider counts clocks only while a cycle is in progress.
a_div_count: assert property (
  (!bus_wen && !pls && owr_cyc) |=> (div == $past(div) + 1'b1));

// Source: RTL divider - the divider is frozen when idle (no cycle, no tick).
a_div_idle_hold: assert property (
  (!bus_wen && !pls && !owr_cyc) |=> $stable(div));

// Source: RTL cycle counter - it only changes on a control write or a divider tick.
a_cnt_hold: assert property ((!pls && !ctl_wr) |=> $stable(cnt));

// Source: RTL cycle counter - it counts down by one on each tick (wraps).
a_cnt_step: assert property ((pls && !ctl_wr) |=> (cnt == $past(cnt) - 1'b1));

//////////////////////////////////////////////////////////////////////////////
// interrupt
//////////////////////////////////////////////////////////////////////////////

// Source: Table 11 bit 7 - ien=0 masks the interrupt request.
a_irq_mask_off: assert property (!irq_ena |-> !bus_irq);

// Source: Section 2.2.1 - an enabled, pending status drives the interrupt request.
a_irq_mask_on: assert property ((irq_ena && irq_sts) |-> bus_irq);

// Source: Section 2.2.1 / Table 11 bit 6 - a read of the control register clears
// the status, unless a cycle ends in the same clock (end-of-cycle wins) or a
// control write happens (write wins).
a_irq_rd_clr: assert property (
  (bus_ren && bus_adr == 0 && !ctl_wr && !(pls && cnt == 0)) |=> !irq_sts);

// Source: Table 11 bit 6 - the status is set at the end of every 1-wire cycle
// (divider tick with cnt==0), unless a control write occurs in the same clock.
a_irq_tick_set: assert property (
  (!ctl_wr && pls && cnt == 0 && owr_cyc) |=> irq_sts);

// Source: Table 11 bit 6 - normal write0/write1 cycle (65 clocks) raises the status
// at its end.
a_irq_end_nb: assert property ((!bus_wen && k_nb && qc == 11'd65) |-> irq_sts);

// Source: Table 11 bit 6 - overdrive write0/write1 cycle (8 clocks) raises the status
// at its end.
a_irq_end_ob: assert property ((!bus_wen && k_ob && qc == 11'd8) |-> irq_sts);

// Source: Table 11 bit 6 - the status stays 0 during a normal bit cycle until it ends.
a_irq_quiet_nb: assert property ((!bus_wen && k_nb && qc <= 11'd64) |-> !irq_sts);

//////////////////////////////////////////////////////////////////////////////
// cycle duration (Table 7 / Table 12, in clocks)
//////////////////////////////////////////////////////////////////////////////

// Source: Table 12 normal write0/write1 65us, Table 7 tDAT0+tREC = 13 ticks.
// A cycle is busy from the write until 65 clocks have passed.
a_nb_busy: assert property ((!bus_wen && k_nb && qc <= 11'd64) |-> owr_cyc);
a_nb_end:  assert property ((!bus_wen && k_nb && qc == 11'd65) |-> !owr_cyc);

// Source: Table 12 normal reset 960us, Table 7 tRSTL+tRSTH = 192 ticks.
a_nr_busy: assert property ((!bus_wen && k_nr && qc <= 11'd959) |-> owr_cyc);
a_nr_end:  assert property ((!bus_wen && k_nr && qc == 11'd960) |-> !owr_cyc);

// Source: Table 12 normal timed idle 1000us, RTL t_idl = 200 ticks.
a_ni_busy: assert property ((!bus_wen && k_ni && qc <= 11'd999) |-> owr_cyc);
a_ni_end:  assert property ((!bus_wen && k_ni && qc == 11'd1000) |-> !owr_cyc);

// Source: Table 12 overdrive write0/write1 8us, 8 ticks of 1 clock each.
a_ob_busy: assert property ((!bus_wen && k_ob && qc <= 11'd7) |-> owr_cyc);
a_ob_end:  assert property ((!bus_wen && k_ob && qc == 11'd8) |-> !owr_cyc);

// Source: Table 12 overdrive reset 96us, 96 ticks of 1 clock each.
a_or_busy: assert property ((!bus_wen && k_or && qc <= 11'd95) |-> owr_cyc);
a_or_end:  assert property ((!bus_wen && k_or && qc == 11'd96) |-> !owr_cyc);

//////////////////////////////////////////////////////////////////////////////
// 1-wire line drive (owr_oen) timing (Table 7, RTL output-register chain)
//////////////////////////////////////////////////////////////////////////////

// Source: Table 7 tDAT0 = 60us = 12 ticks: write0 pulls the line low, released
// at the 12th tick (clock 60).
a_nb0_oen_hi:  assert property ((!bus_wen && k_nb0 && qc <= 11'd59) |-> owr_oen);
a_nb0_oen_rel: assert property ((!bus_wen && k_nb0 && qc == 11'd60) |-> !owr_oen);

// Source: Table 7 tDAT1 = 5us = 1 tick: write1 pulls the line low for one tick.
a_nb1_oen_hi:  assert property ((!bus_wen && k_nb1 && qc <= 11'd4) |-> owr_oen);
a_nb1_oen_rel: assert property ((!bus_wen && k_nb1 && qc == 11'd5) |-> !owr_oen);

// Source: Table 7 tRSTL = 480us = 96 ticks: reset pulls the line low, released at
// the 96th tick (clock 480).
a_nr_oen_hi:  assert property ((!bus_wen && k_nr && qc <= 11'd479) |-> owr_oen);
a_nr_oen_rel: assert property ((!bus_wen && k_nr && qc == 11'd480) |-> !owr_oen);

// Source: Section 4.4 / RTL - a timed idle cycle never drives the line.
a_ni_oen_lo: assert property ((!bus_wen && k_ni) |-> !owr_oen);

// Source: Table 7 overdrive tDAT0 = 6us = 6 ticks.
a_ob0_oen_hi:  assert property ((!bus_wen && k_ob0 && qc <= 11'd5) |-> owr_oen);
a_ob0_oen_rel: assert property ((!bus_wen && k_ob0 && qc == 11'd6) |-> !owr_oen);

// Source: Table 7 overdrive tDAT1 = 1us = 1 tick.
a_ob1_oen_hi:  assert property ((!bus_wen && k_ob1 && qc == 11'd0) |-> owr_oen);
a_ob1_oen_rel: assert property ((!bus_wen && k_ob1 && qc == 11'd1) |-> !owr_oen);

// Source: Table 7 overdrive tRSTL = 48us = 48 ticks.
a_or_oen_hi:  assert property ((!bus_wen && k_or && qc <= 11'd47) |-> owr_oen);
a_or_oen_rel: assert property ((!bus_wen && k_or && qc == 11'd48) |-> !owr_oen);

// Source: Section 4.3 / RTL - owr_e is owr_oen shifted by the (unassigned) select;
// a set owr_e bit implies the enable is set, for any select value.
a_e_implies_oen: assert property (owr_e |-> owr_oen);

//////////////////////////////////////////////////////////////////////////////
// data hold during a write cycle
//////////////////////////////////////////////////////////////////////////////

// Source: Section 4.5.1 / RTL - the data bit is only replaced at the end of the
// cycle, so a write0 keeps dat=0 until the cycle ends.
a_nb0_dat_hold: assert property ((!bus_wen && k_nb0 && qc <= 11'd64) |-> !owr_dat);

// Source: Section 4.5.1 / RTL - a write1 keeps dat=1 until the cycle ends.
a_nb1_dat_hold: assert property ((!bus_wen && k_nb1 && qc <= 11'd64) |-> owr_dat);

endmodule

// Bind to the design's top module. Parameters take the design's own values.
bind sockit_owm sockit_owm_sva #(
  .BDW(BDW), .BAW(BAW), .OWN(OWN), .OVD_E(OVD_E),
  .CDW(CDW), .TDW(TDW), .CDR_N(CDR_N), .CDR_O(CDR_O)
) u_sockit_owm_sva (.*);
EOF
cd /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r && printf './sva/sockit_owm_sva.sv\n' > sockit_owm_sva.f && ./check_syntax.sh
```

#### result

```
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-9005)] /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/./rtl/sockit_owm.v(417): 2-bit index expression 'owr_sel' is larger than the required 1 bits. This might lead to an out-of-bound access
SYNTAX OK
```

### step 9: SubagentHandback

SVA checker written in /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r. `./check_syntax.sh` prints SYNTAX OK. No warning points into the checker file; all warnings point into rtl/sockit_owm.v (see the findings below). I could not run a formal tool, so the assertions are checked by hand against the RTL and the datasheet, not by proof.

Deliverables (the only files I created; I also created the sva/ directory):
- /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/sva/sockit_owm_sva.sv: module sockit_owm_sva with about 60 labelled assertions, plus `bind sockit_owm sockit_owm_sva #(...) u_sockit_owm_sva (.*);`. Each assertion has a source comment. Binding passes the design's parameters (BDW, BAW, OWN, OVD_E, CDW, TDW, CDR_N, CDR_O).
- /tmp/brg8ve/sva_ws/sockit_owm_e3qn7r/sockit_owm_sva.f: `./sva/sockit_owm_sva.sv`

What it specifies (default parameters: OVD_E=1, BDW=32, OWN=1, BTP "5.0"/"1.0", CDR_N=4, CDR_O=0):
- Reset values of ien/irq/pwr/cyc/ovd/rst/oen, the divider and counter, cdr_n/cdr_o, and the outputs (owr_p, owr_e, bus_irq).
- Control writes: each field (ien, rst, ovd, pwr, dat) is stored; cyc=1 starts or restarts a cycle; 111 is a zero-time idle that starts nothing and does not drive the line; a write clears irq.
- Read-back: a control write followed by a read returns the written bits (irq and reserved bits read 0); a cdr write followed by a read returns the word; bits 31:8 of the control address read 0.
- Holds: ien/rst/ovd/pwr change only on control writes; cdr changes only on address-1 writes; cnt and div behave as the RTL counter and divider do.
- Interrupt: mask behaviour; read clears the status unless a tick or write wins; set at every cycle end; no set mid-cycle for a normal bit.
- Cycle durations in clocks, with no bus write inside the window: normal bit 65, normal reset 960, normal idle 1000, overdrive bit 8, overdrive reset 96, each checked for busy-then-end.
- owr_oen release points, per Table 7: write0 at 60 clocks, write1 at 5, normal reset at 480, overdrive write0 at 6, overdrive write1 at 1, overdrive reset at 48. Idle never drives the line. owr_e implies owr_oen.
- Data hold: dat is 0 (write0) or 1 (write1) until the cycle ends.

Findings in the RTL (these shaped what I asserted):
1. owr_sel is only assigned in an `initial` block when OWN==1 (the tool reports it undriven), so owr_iln and the shift in owr_e are unconstrained. I did not assert the sampled line input or any value derived from the select. Input-to-output data paths are therefore not specified.
2. With the default CDR_O=0, after an overdrive cycle the divider runs every clock while idle. cnt then wraps and sets irq_sts (about every 256 clocks) and changes owr_dat, with no cycle in progress. Quiet-time properties in overdrive are guarded or left out. The same happens in normal mode if cdr_n is written to 0.
3. The datasheet says cyc=0 is "no action", but the RTL clears owr_cyc on any control write, which aborts a running cycle. I did not assert the mid-cycle cyc=0 case.
4. The timing assertions assume no bus write during the cycle, because any write restarts the divider. A write during a cycle is legal, so these only hold in the windows I specified. They are not general.

Assertions I considered but dropped: any quiet-time claim about irq/dat/oen in overdrive with cdr_o=0, and any sampled-input value check (finding 1).

#### result

```
{"success":true,"message":"Report delivered to your caller."}
```
