# Generator trace

source: /tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/2a0eb51f-5654-4253-af46-67d46e4659a3/tasks/adff484a0c1280f69.output

note: 9 thinking block(s) were stored without text.

### step 1: Bash

```
cat /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/TASK.md
```

#### result

```
# Task: write a SystemVerilog Assertion checker for the RTL design in this workspace

You are a verification engineer. Write a set of SystemVerilog Assertions
(SVA) that specify the behaviour of the design in this workspace, as a
checker module bound to the design's top module.

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
edit, and fix every error until it prints `SYNTAX OK`.

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

**Do not transcribe the RTL.** An assertion that copies an RTL statement
only restates the code and says nothing new. For example, for
`assign y = a & b;` do not write `y == (a & b)`, and for
`if (c) r <= e;` do not write `c |=> r == $past(e)` with the same
expression structure. A low-level property must say something the RTL text
does not already say literally. Good forms are:

- **End-to-end behaviour**: a bus write followed by a read returns the
  written field; a started operation finishes after the documented number
  of time steps and raises its s
... [6693 more chars]
```

### step 2: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && ls -laR | head -100 && cat *.tcl *.f check_syntax.sh
```

#### result

```
.:
total 24
drwx------ 4 brg8ve users  108 Nov 23 19:04 .
drwxr-xr-x 8 brg8ve users  156 Nov 23 19:04 ..
-rwxr-xr-x 1 brg8ve users  846 Nov 23 19:04 check_syntax.sh
drwxr-xr-x 2 brg8ve users   28 Nov 23 19:04 doc
drwxr-xr-x 2 brg8ve users   26 Nov 23 19:04 rtl
-rw-r--r-- 1 brg8ve users   19 Nov 23 19:04 sockit_owm.f
-rw-r--r-- 1 brg8ve users  349 Nov 23 19:04 sockit_owm.tcl
-rw-r--r-- 1 brg8ve users 9712 Nov 23 19:04 TASK.md

./doc:
total 364
drwxr-xr-x 2 brg8ve users     28 Nov 23 19:04 .
drwx------ 4 brg8ve users    108 Nov 23 19:04 ..
-rw-r--r-- 1 brg8ve users 372000 Nov 23 19:04 sockit_owr.pdf

./rtl:
total 20
drwxr-xr-x 2 brg8ve users    26 Nov 23 19:04 .
drwx------ 4 brg8ve users   108 Nov 23 19:04 ..
-r--r--r-- 1 brg8ve users 17641 Nov 23 19:04 sockit_owm.v
clear -all


analyze -v2k -f sockit_owm.f

if { [file exists sockit_owm_sva.f] == 1 } {
	analyze -sv -f sockit_owm_sva.f
}

# Blackbox missing modules instead of erroring out
elaborate -bbox 1
clock clk
reset rst==1'b1


       	-per_property_time_limit_factor 0\
       	-prove_time_limit 5m

	-per_property_time_limit_factor 0 \
	-time_limit 5m


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
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && cat -n rtl/sockit_owm.v
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
... [17573 more chars]
```

### step 4: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && pdftotext -layout doc/sockit_owr.pdf - | cat
```

#### result

```
<persisted-output>
Output too large (63KB). Full output saved to: /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/2a0eb51f-5654-4253-af46-67d46e4659a3/tool-results/bvv6a6ya3.txt

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
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && pdftotext -layout doc/sockit_owr.pdf /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/2a0eb51f-5654-4253-af46-67d46e4659a3/scratchpad/doc.txt; wc -l /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/2a0eb51f-5654-4253-af46-67d46e4659a3/scratchpad/doc.txt; sed -n 1,400p /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/2a0eb51f-5654-4253-af46-67d46e4659a3/scratchpad/doc.txt | sed -n 60,400p
```

#### result

```
I/O Error: Couldn't open text file '/var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/2a0eb51f-5654-4253-af46-67d46e4659a3/scratchpad/doc.txt'
wc: /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/2a0eb51f-5654-4253-af46-67d46e4659a3/scratchpad/doc.txt: No such file or directory
sed: can't read /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/2a0eb51f-5654-4253-af46-67d46e4659a3/scratchpad/doc.txt: No such file or directory
```

### step 6: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && pdftotext -layout doc/sockit_owr.pdf - | sed -n 60,330p
```

#### result

```
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
Table 6: 1-wire protocol standard timing restrictions.........................................................................11
Table 7: Timing options......................................................................................................................11
Table 8: 
... [13323 more chars]
```

### step 7: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && pdftotext -layout doc/sockit_owr.pdf - | sed -n 330,600p
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
... [11512 more chars]
```

### step 8: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && pdftotext -layout doc/sockit_owr.pdf - | sed -n 600,760p
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
  
... [4388 more chars]
```

### step 9: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && pdftotext -layout doc/sockit_owr.pdf - | sed -n 760,1000p | grep -v '^\s*$' | head -150
```

#### result

```
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
source and header files. The integration is done based on instructions from Altera.
Table 13: Files for Nios II HAL and μC/OS-II integration
file                          description
sockit_owm_hw.tcl             TCL script for integration into SOPC Builder
sockit_owm_sw.tcl             TCL script for integration into Nios II EDS
inc/sockit_owm_regs.h specification of hardware registers and low level access macros
HAL/inc/sockit_owm.h          initialization and interrupt handling code
HAL/src/sockit_owm.c
The hardware TCL script provides the software with macros defining the hardware configuration.
The software TCL script provides integration into the Nios II EDS, by defining:
   •   driver version and compatibility
   •   list of C sources and headers
   •   list of driver configuration options
The register definitions are mostly used for initialization and interrupts related code and for the 1-
wire protocol link layer. The next IO macros are provided for reading from and writing into the
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
   •   owpd310r2/lib/general/shared - transport and network layer fil
... [6919 more chars]
```

### assistant

I have the RTL, the datasheet, and the setup script. Before writing the checker, here is the behaviour list I'm working from, derived from the RTL with default parameters (BDW=32, OWN=1, OVD_E=1, CDR_E=1, BTP "5.0"/"1.0", active-high async reset).

- **Register read-back**: ctl bits (ien, pwr, ovd, rst, dat, cyc) after a write; cdr_o/cdr_n read-back; cdr hold.
- **Interrupt**: set at end of cycle, cleared by write or read, end event wins over a same-cycle read, ien masks the output, set only at end of an active cycle.
- **Reset values**: control bits, div, oen, outputs, cdr defaults.
- **Output drive**: owr_oen per cycle type, release points (reset 96, write-1 1, write-0 12 base periods in normal mode), idle cycle never drives, cyc=0 write must not drive.
- **Cycle length**: start/restart, exact length of tlen × (cdr+1) clocks, zero-time idle.
- **Hold**: cnt, owr_dat, owr_p when no cycle or no end event.

I'll write the checker now.

### step 10: Bash

```
mkdir -p /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/sva && cat > /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/sva/sockit_owm_sva.sv << 'EOF'
// -----------------------------------------------------------------------------
// SVA checker for sockit_owm (1-wire master), specified against
// doc/sockit_owr.pdf (sections 2.2, 4.1-4.5, Tables 8-12) plus designer intent
// visible in rtl/sockit_owm.v.
//
// Configuration: default parameters (BDW=32, BAW=1, OWN=1, OVD_E=1, CDR_E=1,
// BTP_N="5.0", BTP_O="1.0"). Reset rst is active high and asynchronous.
//
// Notes on the cycle model used below:
//  - tlen   : cycle length in base periods, as loaded into cnt by the write
//             (cnt = tlen-1 at start, decremented on each pulse).
//  - ccnt   : clock cycles since the last bus write (0 in the cycle after it).
//  - A base period lasts (cdr+1) clocks, so a cycle lasts tlen*(cdr+1) clocks.
//  - Release point of the line: pulse number rel_k = tlen - rel_cnt, where
//    rel_cnt is the cnt value at which owr_oen is cleared.
// -----------------------------------------------------------------------------
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
  parameter T_RSTP_N = 15,
  parameter T_DAT0_N = 12,
  parameter T_DAT1_N = 1,
  parameter T_BITS_N = 3,
  parameter T_RCVR_N = 1,
  parameter T_IDLE_N = 200,
  parameter T_RSTH_O = 48,
  parameter T_RSTL_O = 48,
  parameter T_RSTP_O = 10,
  parameter T_DAT0_O = 6,
  parameter T_DAT1_O = 1,
  parameter T_BITS_O = 2,
  parameter T_RCVR_O = 2,
  parameter T_IDLE_O = 96
) (
  clk, rst, bus_ren, bus_wen, bus_adr, bus_wdt, bus_rdt, bus_irq,
  owr_p, owr_e, owr_i,
  div, cdr_n, cdr_o, cnt, owr_cyc, owr_pwr, owr_ovd, owr_rst, owr_dat,
  owr_smp, owr_oen, irq_ena, irq_sts
);

localparam CDW = CDR_E ? ((BDW == 32) ? 16 : 8) : $clog2(CDR_N);
localparam TDW = ((T_RSTH_O + T_RSTL_O) > (T_RSTH_N + T_RSTL_N))
               ? $clog2(T_RSTH_O + T_RSTL_O) : $clog2(T_RSTH_N + T_RSTL_N);

input                 clk;
input                 rst;
input                 bus_ren;
input                 bus_wen;
input  [BAW-1:0]      bus_adr;
input  [BDW-1:0]      bus_wdt;
input  [BDW-1:0]      bus_rdt;
input                 bus_irq;
input  [OWN-1:0]      owr_p;
input  [OWN-1:0]      owr_e;
input  [OWN-1:0]      owr_i;
input  [CDW-1:0]      div;
input  [CDW-1:0]      cdr_n;
input  [CDW-1:0]      cdr_o;
input  [TDW-1:0]      cnt;
input                 owr_cyc;
input  [OWN-1:0]      owr_pwr;
input                 owr_ovd;
input                 owr_rst;
input                 owr_dat;
input                 owr_smp;
input                 owr_oen;
input                 irq_ena;
input                 irq_sts;

//////////////////////////////////////////////////////////////////////////////
// helper signals (all derived from ports / design signals)
//////////////////////////////////////////////////////////////////////////////

// bus transaction decode (BAW=1: adr 0 = control/status, adr 1 = clock dividers)
wire ctl_wr = bus_wen & ~bus_adr[0];
wire ctl_rd = bus_ren & ~bus_adr[0];
wire cdr_wr = bus_wen &  bus_adr[0];
wire cdr_rd = bus_ren &  bus_adr[0];

// base period pulse and end-of-cycle event (as generated by the RTL)
wire pls     = (div == (owr_ovd ? cdr_o : cdr_n));
wire end_ev  = pls & (cnt == {TDW{1'b0}});

// per-cycle timing points, cnt value at which each event happens
wire [TDW-1:0] t_rsth = owr_ovd ? T_RSTH_O : T_RSTH_N;
wire [TDW-1:0] t_rstp = owr_ovd ? (T_RSTH_O - T_RSTP_O) : (T_RSTH_N - T_RSTP_N);
wire [TDW-1:0] t_dat0 = owr_ovd ? (T_DAT0_O - T_DAT0_O + T_RCVR_O)
                                : (T_DAT0_N - T_DAT0_N + T_RCVR_N);
wire [TDW-1:0] t_dat1 = owr_ovd ? (T_DAT0_O - T_DAT1_O + T_RCVR_O)
                                : (T_DAT0_N - T_DAT1_N + T_RCVR_N);
wire [TDW-1:0] t_bits = owr_ovd ? (T_DAT0_O - T_BITS_O + T_RCVR_O)
                                : (T_DAT0_N - T_BITS_N + T_RCVR_N);

// cycle length (base periods) that a write of bus_wdt would load:
// idle (rst=1,dat=1), reset (rst=1,dat=0), write/read slot (rst=0)
wire       ovd_w = OVD_E & bus_wdt[2];
wire [8:0] tlen_w = ovd_w
  ? (&bus_wdt[1:0] ? T_IDLE_O : bus_wdt[1] ? (T_RSTL_O + T_RSTH_O) : (T_DAT0_O + T_RCVR_O))
  : (&bus_wdt[1:0] ? T_IDLE_N : bus_wdt[1] ? (T_RSTL_N + T_RSTH_N) : (T_DAT0_N + T_RCVR_N));

// clock divider currently in use
wire [CDW-1:0] cdr_cur = owr_ovd ? cdr_o : cdr_n;
wire [16:0]    cdr_p1  = {1'b0, cdr_cur} + 17'd1;   // clocks per base period

// modelling state: cycle length and clock count since last bus write
reg  [8:0]  tlen;
reg  [25:0] ccnt;

always @(posedge clk or posedge rst)
if (rst) begin
  tlen <= 9'd0;
  ccnt <= 26'd0;
end else begin
  if (bus_wen) begin
    ccnt <= 26'd0;
    if (ctl_wr) tlen <= tlen_w;
  end else begin
    ccnt <= ccnt + 26'd1;
  end
end

wire [25:0] cyc_len = tlen * cdr_p1;                       // clocks of a full cycle

wire [TDW-1:0] rel_cnt = owr_rst ? t_rsth : (owr_dat ? t_dat1 : t_dat0);
wire [8:0]     rel_k   = tlen - rel_cnt;                    // pulse where line is released
wire [25:0]    rel_clk = rel_k * cdr_p1;                    // clocks until release

// =========================================================================
// A. Control/status register read-back and interrupt (doc 4.4, Table 10/11)
// =========================================================================

// doc Table 11 bit 7: ien is r/w. A write followed by a read returns the written value.
a_rd_ien: assert property (ctl_wr ##1 ctl_rd |-> bus_rdt[7] == $past(bus_wdt[7]));

// doc Table 11 bit 4: pwr is r/w (OWN=1: the pwr bit drives owr_p[0]).
a_rd_pwr: assert property (ctl_wr ##1 ctl_rd |-> bus_rdt[4] == $past(bus_wdt[4]));

// doc Table 11 bit 2: ovd is r/w.
a_rd_ovd: assert property (ctl_wr ##1 ctl_rd |-> bus_rdt[2] == $past(bus_wdt[2]));

// doc Table 11 bit 1: rst is r/w.
a_rd_rst: assert property (ctl_wr ##1 ctl_rd |-> bus_rdt[1] == $past(bus_wdt[1]));

// doc 4.4 bit 0: dat holds the written transmit data until the cycle ends.
// RTL: a write has priority over the cycle-end update, and a cycle cannot end
// in the cycle right after the write (cycle length >= 8 clocks).
a_rd_dat: assert property (ctl_wr ##1 ctl_rd |-> bus_rdt[0] == $past(bus_wdt[0]));

// doc Table 11 bit 3: reading cyc gives the cycle status. A write with cyc=1
// starts a cycle, except the zero-time idle (ovd=1, rst=1, dat=1) of Table 12.
a_rd_cyc: assert property (ctl_wr ##1 ctl_rd |->
  bus_rdt[3] == ($past(bus_wdt[3]) && !(&$past(bus_wdt[2:0]))));

// doc 4.4 bit 6: irq is cleared by a bus read. A read in a cycle with no end
// event clears it.
a_irq_rd_clr: assert property (ctl_rd && !ctl_wr && !end_ev |=> !irq_sts);

// RTL priority: the end-of-cycle set wins over the read clear in the same cycle.
// Doc 4.4 does not state this; the RTL update order decides it.
a_irq_end_wins_rd: assert property (ctl_rd && !ctl_wr && end_ev && owr_cyc |=> irq_sts);

// RTL: a control write clears the interrupt status (write has priority).
a_irq_wr_clr: assert property (ctl_wr |=> !irq_sts);

// doc 2.2.1 and 4.4: interrupt is raised at end of a 1-wire cycle when ien=1.
a_irq_set_end: assert property (end_ev && owr_cyc && irq_ena && !ctl_wr |=> bus_irq);

// doc 4.4 bit 7: ien=0 disables the interrupt request.
a_irq_masked: assert property (end_ev && owr_cyc && !irq_ena && !ctl_wr |=> !bus_irq);

// doc 4.4 bit 6: irq is set on end of a 1-wire cycle only. The RTL sets irq_sts
// on pls & cnt==0 without checking owr_cyc, so this fails if the counter runs
// while the master is idle (see H1).
a_irq_only_end: assert property ($rose(irq_sts) |-> $past(owr_cyc));

// =========================================================================
// B. Reset values (doc Table 10 reset column, 4.2, 4.3).
// Reset is asynchronous, so the registers already hold their reset values in
// every cycle where rst is high. These checks therefore do not use the default
// disable iff, which would hide them.
// =========================================================================

// doc Table 10: ien, irq, pwr, cyc, ovd, rst reset to 0. RTL: owr_oen and div reset to 0.
a_rst_regs: assert property (@(posedge clk) disable iff (1'b0)
  rst |-> (!irq_ena && !irq_sts && !owr_pwr[0] && !owr_cyc && !owr_ovd && !owr_rst
           && !owr_oen && div == {CDW{1'b0}}));

// doc 4.3: all power outputs are off after reset. doc 2.2.1: bus_irq is low after reset.
a_rst_outs: assert property (@(posedge clk) disable iff (1'b0)
  rst |-> (owr_p == {OWN{1'b0}} && !bus_irq));

// doc 4.2: clock divider registers reset to CDR_N and CDR_O.
a_rst_cdr: assert property (@(posedge clk) disable iff (1'b0)
  rst |-> (cdr_n == CDR_N[CDW-1:0] && cdr_o == CDR_O[CDW-1:0]));

// =========================================================================
// C. Clock divider registers (doc 4.2, Table 8)
// =========================================================================

// doc 4.2 / Table 8: cdr_n (bits 15..0) and cdr_o (bits 31..16) read back what was written.
a_cdr_rd_back: assert property (cdr_wr ##1 cdr_rd |->
  (bus_rdt[15:0] == $past(bus_wdt[15:0]) && bus_rdt[31:16] == $past(bus_wdt[31:16])));

// doc 4.2: the ratios are only changed by a write to the divider register, so
// they hold in every other cycle (including control writes).
a_cdr_hold: assert property (!cdr_wr |=> ($stable(cdr_n) && $stable(cdr_o)));

// doc 4.2 states the rule for changing ratios: "the registers can be written to
// with new divider ratios while there is no 1-wire cycle in progress". This
// environment restriction is needed for the cycle-length checks in E.
asm_cdr_idle: assume property (cdr_wr |-> !owr_cyc);

// =========================================================================
// D. Line outputs and power (doc 2.2.2, 4.3, 4.4, Table 12)
// =========================================================================

// doc 4.3 with OWN=1: the pwr bit drives owr_p[0] immediately after the write.
a_pwr_out: assert property (ctl_wr |=> owr_p[0] == $past(bus_wdt[4]));

// doc 4.3: power is only changed by a control write.
a_pwr_hold: assert property (!ctl_wr |=> $stable(owr_p));

// doc 4.4 bit 3: cyc=0 means "no action", so a write with cyc=0 while no cycle
// is in progress must not drive the line. The RTL updates owr_oen on every
// control write, regardless of cyc.
a_no_drive_cyc0: assert property (ctl_wr && !bus_wdt[3] && !owr_cyc |=> !owr_oen);

// doc Table 12, zero-time and timed idle cycles (rst=1, dat=1): no line activity.
a_idle_no_drive: assert property (ctl_wr && (&bus_wdt[1:0]) |=> !owr_oen);

// doc 2.2.2: the line enable is driven by owr_oen. With OWN=1 the select register
// is ignored (doc 2.1.2, 4.3), so owr_e[0] must equal owr_oen.
// NOTE: on the current RTL this depends on owr_sel, which is never written when
// OWN=1 (no reset, only an initial block), so this is expected to fail.
a_e_mirror_oen: assert property (owr_e[0] == owr_oen);

// doc 2.3 and 4.5: the line is sampled at the data sample point of a slot.
a_sample_slot: assert property (owr_cyc && pls && !owr_rst && cnt == t_bits
  |=> owr_smp == $past(owr_i[0]));

// doc 4.4 bit 0 (presence detect): the line is sampled at the presence point of a reset.
a_sample_presence: assert property (owr_cyc && pls && owr_rst && cnt == t_rstp
  |=> owr_smp == $past(owr_i[0]));

// =========================================================================
// E. Cycle timing (doc Table 12, 4.4, 4.5)
// =========================================================================

// doc Table 12: zero-time idle (ovd=1, rst=1, dat=1) starts no cycle.
a_zero_idle_nocyc: assert property (ctl_wr && bus_wdt[3] && (&bus_wdt[2:0]) |=> !owr_cyc);

// doc 4.4: writing cyc=1 starts a cycle (any non-zero-time cycle).
a_cyc_start: assert property (ctl_wr && bus_wdt[3] && !(&bus_wdt[2:0]) |=> owr_cyc);

// doc Table 12 / 4.4: a started cycle stays busy for its full length. Length in
// clocks = tlen * (cdr+1). Checked as: busy until ccnt reaches the length...
a_cyc_hold: assert property (owr_cyc && !bus_wen && (ccnt < cyc_len - 26'd1) |=> owr_cyc);

// ...and ends exactly when ccnt reaches the length (doc Table 12 durations:
// 65us / 960us / 1000us normal, 8us / 96us overdrive, 0us zero-time idle).
a_cyc_end: assert property (owr_cyc && !bus_wen && (ccnt == cyc_len - 26'd1) |=> !owr_cyc);

// doc 4.4: the line stays driven until the release point, for write-0 (12 base
// periods), write-1/read (1 base period), reset (96 base periods). Doc Table 12
// and 4.5 give the same values. Idle cycles never drive, so they are excluded.
a_oen_hold: assert property (owr_cyc && !bus_wen && !(owr_rst && owr_dat) && (ccnt < rel_clk)
  |-> owr_oen);

// doc 4.4: the line is released at the release point (see a_oen_hold).
a_oen_release: assert property (owr_cyc && !bus_wen && owr_oen && (ccnt == rel_clk - 26'd1)
  |=> !owr_oen);

// =========================================================================
// H. Hold / idle behaviour (designer intent from RTL)
// =========================================================================

// RTL intent: the counter only moves while a 1-wire cycle is in progress. The
// RTL decrements cnt on pls without checking owr_cyc, so with overdrive
// (CDR_O=0, so pls is high every clock) the counter keeps running after the
// cycle ends. This is expected to fail (see the report).
a_cnt_idle_hold: assert property (!owr_cyc && !bus_wen |=> $stable(cnt));

// doc 4.4: the data status bit only changes when a cycle ends or a write happens.
a_dat_hold_idle: assert property (!owr_cyc && !bus_wen |=> $stable(owr_dat));
a_dat_hold_cyc:  assert property (owr_cyc && !bus_wen && !end_ev |=> $stable(owr_dat));

endmodule

// Bind to the design top. Parameters are passed from the design so that all
// widths and timing constants match the default configuration.
bind sockit_owm sockit_owm_sva #(
  .OVD_E(OVD_E), .CDR_E(CDR_E), .BDW(BDW), .OWN(OWN), .BAW(BAW),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_RSTP_N(T_RSTP_N),
  .T_DAT0_N(T_DAT0_N), .T_DAT1_N(T_DAT1_N), .T_BITS_N(T_BITS_N),
  .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_RSTP_O(T_RSTP_O),
  .T_DAT0_O(T_DAT0_O), .T_DAT1_O(T_DAT1_O), .T_BITS_O(T_BITS_O),
  .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);
EOF
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && printf './sva/sockit_owm_sva.sv\n' > sockit_owm_sva.f && ./check_syntax.sh
```

#### result

```
WARNING (WNL018): /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(129): multiplication operator mult_9u_17u (size 26) automatically blackboxed.
WARNING (WNL018): /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(133): multiplication operator mult_9u_17u (size 26) automatically blackboxed.
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(103): expression size 32 truncated to fit in target size 1
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(104): expression size 32 truncated to fit in target size 9
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(92): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(93): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(94): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(96): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(98): expression size 32 truncated to fit in target size 8
[WARN (VER
... [6329 more chars]
```

### assistant

Syntax passes, but the warnings show two problems I need to fix. The `default clocking` and `default disable iff` lines are missing, so the unlabelled assertions are not clocked or reset-disabled. The multiplier is also being blackboxed, which would leave the cycle-length terms unconstrained in formal. I'll add the defaults and replace the multiplies with a shift-and-add function.

### step 11: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && python3 - << 'EOF'
import re
p='/tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/sva/sockit_owm_sva.sv'
s=open(p).read()
s=s.replace("""input                 irq_sts;

//////""","""input                 irq_sts;

default clocking @(posedge clk); endclocking
default disable iff (rst);

//////""",1)
s=s.replace("""// modelling state: cycle length""","""// shift-and-add multiplier (synthesizable, avoids a blackboxed * operator)
function automatic [25:0] mul9x17 (input [8:0] a, input [16:0] b);
  integer i;
  reg [25:0] acc;
  begin
    acc = 26'd0;
    for (i = 0; i < 9; i = i + 1)
      if (a[i]) acc = acc + ({9'd0, b} << i);
    mul9x17 = acc;
  end
endfunction

// modelling state: cycle length""",1)
s=s.replace("wire [25:0] cyc_len = tlen * cdr_p1;","wire [25:0] cyc_len = mul9x17(tlen, cdr_p1);")
s=s.replace("wire [25:0]    rel_clk = rel_k * cdr_p1;","wire [25:0]    rel_clk = mul9x17(rel_k, cdr_p1);")
open(p,'w').write(s)
EOF
grep -n "default clocking\|mul9x17" sva/sockit_owm_sva.sv; ./check_syntax.sh
```

#### result

```
77:default clocking @(posedge clk); endclocking
116:function automatic [25:0] mul9x17 (input [8:0] a, input [16:0] b);
123:    mul9x17 = acc;
144:wire [25:0] cyc_len = mul9x17(tlen, cdr_p1);                       // clocks of a full cycle
148:wire [25:0]    rel_clk = mul9x17(rel_k, cdr_p1);                    // clocks until release
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(101): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(106): expression size 32 truncated to fit in target size 1
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(107): expression size 32 truncated to fit in target size 9
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(95): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(96): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(97): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/./sva/sockit_owm_sva.sv(99): expression size 32 truncated to fit in ta
... [213 more chars]
```

### assistant

Syntax passes. The remaining warnings are integer-to-narrow truncations in the checker and DUT, plus the known `owr_sel` issue. I'll confirm the final workspace contents.

### step 12: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA && find . -newer TASK.md -type f | sort && cat sockit_owm_sva.f && grep -c "assert property" sva/sockit_owm_sva.sv && grep -c "assume property" sva/sockit_owm_sva.sv && grep -c "cover" sva/sockit_owm_sva.sv
```

#### result

```
./sockit_owm_sva.f
./sva/sockit_owm_sva.sv
./sva/sockit_owm_sva.sv
33
1
0
```

### step 13: SubagentHandback

SVA checker written for sockit_owm and syntax-checked. `./check_syntax.sh` prints SYNTAX OK.

Deliverables (only these two files, plus the checker's own sva/ directory):
- /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/sva/sockit_owm_sva.sv: module sockit_owm_sva, 33 `assert property` labelled a_*, one `assume property` (asm_cdr_idle), no cover, no initial/$display/delays. Bound with `bind sockit_owm sockit_owm_sva #(...) u_sockit_owm_sva (.*);`, passing the design's parameters.
- /tmp/brg8ve/sva_ws/sockit_owm_GSXjaA/sockit_owm_sva.f: `./sva/sockit_owm_sva.sv`

Coverage, default configuration (BDW=32, OWN=1, OVD_E=1, CDR_E=1, BTP "5.0"/"1.0"):
- Read-back of each ctl field after a write (ien, pwr, ovd, rst, dat, cyc), cdr_o/cdr_n read-back and hold, reset values, and reset-time readback of the cdr registers.
- Interrupt: set at end of cycle when ien=1, masked by ien=0, cleared by write and by read, end event wins over same-cycle read, set only at end of an active cycle.
- Line drive: owr_oen behaviour per cycle type (write-0 low 12 base periods, write-1/read low 1, reset low 96), idle never drives, cyc=0 write must not drive, presence and data sampling points.
- Cycle length: start, hold, exact end at tlen*(cdr+1) clocks, zero-time idle starts no cycle. Restarts are handled by ccnt reset on bus writes.
- Hold: cnt and owr_dat when idle or when no end event, owr_p when no ctl write.

Assumption (quoted from doc 4.2: "the registers can be written to with new divider ratios while there is no 1-wire cycle in progress"): `asm_cdr_idle: assume property (cdr_wr |-> !owr_cyc)`. The cycle-length checks need it.

Expected to FAIL on the current RTL (hand analysis, not formally run; these are the bugs the checker is meant to catch):
1. a_cnt_idle_hold, a_irq_only_end, a_dat_hold_idle: pls = (div == cdr) is not gated by owr_cyc. With overdrive and CDR_O=0 (the default), pls is high every clock while idle, so cnt keeps counting down after every overdrive cycle. It wraps to 0 about 256 clocks later, which sets irq_sts spuriously (bus_irq if ien=1) and changes owr_dat. The same happens after a zero-time idle write in overdrive mode, which loads cnt=95 without any cycle. Normal mode with CDR_N=0 has the same problem.
2. a_no_drive_cyc0: owr_oen is loaded on every control write regardless of bit 3. A write with cyc=0 and dat=0 (or rst=1 with dat=0) drives the line low. In normal mode no pulse ever clears it, so the bus stays pulled low until the next write. Doc 4.4 says cyc=0 means "no action".
3. a_e_mirror_oen, a_sample_slot, a_sample_presence: with OWN=1, owr_sel (declared [-1:0], never written, only an initial block that tools ignore) is used in owr_e = owr_oen << owr_sel and owr_iln = owr_i[owr_sel]. Doc 2.1.2/4.3 says select is ignored when OWN=1. Verilog-lint also flags this (WNL/VDB-1002, VDB-9005).

Limitations: only the syntax check was available, so no formal run. The timing checks depend on a small modelling counter (ccnt) and a shift-and-add function instead of `*`, which avoids a blackboxed multiplier. Parameters are assumed to be the defaults. A BDW=8 or CDR_E=0 configuration is not covered.

#### result

```
{"success":true,"message":"Report delivered to your caller."}
```
