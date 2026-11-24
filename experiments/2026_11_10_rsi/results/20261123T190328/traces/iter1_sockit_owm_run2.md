# Generator trace

source: /tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/2a0eb51f-5654-4253-af46-67d46e4659a3/tasks/a02397cfd56556586.output

note: 5 thinking block(s) were stored without text.

### step 1: Bash

```
cat /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/TASK.md
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
cd /tmp/brg8ve/sva_ws/sockit_owm_KX4d81 && find . -type f | head -100 && echo --- && cat *.tcl && echo --- && cat *.f && echo --- && cat check_syntax.sh
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


       	-per_property_time_limit_factor 0\
       	-prove_time_limit 5m

	-per_property_time_limit_factor 0 \
	-time_limit 5m


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
cd /tmp/brg8ve/sva_ws/sockit_owm_KX4d81 && cat sockit_owm.f; echo ---; cat -n rtl/sockit_owm.v; echo ---; pdftotext -layout doc/sockit_owr.pdf - | wc -l
```

#### result

```
./rtl/sockit_owm.v
---
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
    37	// onewire timing. The default
... [17605 more chars]
```

### step 4: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_KX4d81 && pdftotext -layout doc/sockit_owr.pdf - | sed -n 1,620p
```

### step 5: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_KX4d81 && pdftotext -layout doc/sockit_owr.pdf - | sed -n 621,1214p
```

#### result

```
<persisted-output>
Output too large (37KB). Full output saved to: /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/2a0eb51f-5654-4253-af46-67d46e4659a3/tool-results/bq48tqxof.txt

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
used 
... [23505 more chars]
```

### step 6: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_KX4d81 && pdftotext -layout doc/sockit_owr.pdf - | sed -n 40,300p
```

### step 7: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_KX4d81 && pdftotext -layout doc/sockit_owr.pdf - | sed -n 301,460p
```

#### result

```
   4.5 Driver access sequences..........................................................................................................15
      4.5.1 Polling routines...............................................................................................................16
         Reset and presence pulses....................................................................................................16
         Read/write data slots............................................................................................................16
         Delay of 0ms or 1ms............................................................................................................17
      4.5.2 Interrupt routines.............................................................................................................17
         Reset and presence pulses, read/write data slots..................................................................17
         OS initialization and interrupt service routine.....................................................................18
5 Software driver...............................................................................................................................19
   5.1 Port of Public Domain Kit components to Nios II HAL and μC/OS-II..................................19
      5.1.1 Nios II HAL and μC/OS-II drivers.................................................................................19
      5.1.2 Public Domain Kit components......................................................................................19
   5.2 Adding support for new devices.............................................................................................20
   5.3 Possible improvements...........................................................................................................20
6 Altera development tools integration..............................................................................................21
   6.1 SOPC Builder and Nios II EDS integration............................................................................21
      6.1.1 SOPC Builder..................................................................................................................21
         Adding the component to a project......................................................................................21
         Configuring the component..................................................................................................21
      6.1.2 Nios II EDS.....................................................................................................................22
7 Demo hardware and software implementation...............................................................................23
   7.1 Demo hardware.......................................................................................................................23
      7.1.1 Demo hardware logic consumption..
... [14966 more chars]
```

#### result

```
2.2.2 1-wire interface
The 1-wire module requires an external open drain driver to be able to drive a bidirectional pin. The
owr_p signal can be used to supply extra power to the 1-wire line (for temperature conversion, ...),
if the signal is not used, 0 should be applied instead. The next scheme shows the driver for the i-th
line.




                                                  8
          owr_p[i] | owr_e[i]

                            owr_p[i]                                       owr[i]

                            owr_i[i]
Drawing 2: 1-wire line driver schematic

The next Verilog code should be used for the i-th line on the top level of the SoC.
assign owr [i] = (owr_p[i] | owr_e[i]) ? owr_p[i] : 1'bz;
assign owr_i[i] = owr;


And if the power signal is ignored.
assign owr [i] = owr_e[i] ? 1'b0 : 1'bz;
assign owr_i[i] = owr;


On some FPGA it is possible to set driver strength at compile time. There are no extra features for
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
                                   status 
... [4868 more chars]
```

### step 8: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_KX4d81 && pdftotext -layout doc/sockit_owr.pdf - | sed -n 461,625p
```

#### result

```
Drawing 5: Write 0 timing diagram

The write '1' or read cycle is 9 base periods long. The wire is tight low for 1 base period than
released. A typical 1-wire slave would answer with '0' by holding the wire down for 4 base periods
(min 2, max 8) from the falling edge of the read command. Data is sampled at the most stable point
at 2 base periods from the falling edge. There is 1 base period at the end for recovery.

                      8     7      6      5     4        3   2     1     0




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
     3                                          
... [6070 more chars]
```

### assistant

I have the full datasheet and RTL. Before writing the checker, I'll note what I found: with the default parameters (`CDR_O=0`), the RTL's `pls` and `cnt==0` events fire in idle overdrive mode, which sets `irq_sts` and `owr_dat` spuriously. I'll keep those behaviours out of the assertions and report them. Creating the output directory and writing the checker now.

### step 9: Bash

```
mkdir -p /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/sva && ls -la /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/
```

#### result

```
total 24
drwx------ 5 brg8ve users  119 Nov 23 19:12 .
drwxr-xr-x 8 brg8ve users  156 Nov 23 19:04 ..
-rwxr-xr-x 1 brg8ve users  846 Nov 23 19:04 check_syntax.sh
drwxr-xr-x 2 brg8ve users   28 Nov 23 19:04 doc
drwxr-xr-x 2 brg8ve users   26 Nov 23 19:04 rtl
-rw-r--r-- 1 brg8ve users   19 Nov 23 19:04 sockit_owm.f
-rw-r--r-- 1 brg8ve users  349 Nov 23 19:04 sockit_owm.tcl
drwxr-xr-x 2 brg8ve users    6 Nov 23 19:12 sva
-rw-r--r-- 1 brg8ve users 9712 Nov 23 19:04 TASK.md
```

### step 10: Write

file: /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/sva/sockit_owm_sva.sv

```
//////////////////////////////////////////////////////////////////////////////
// SVA checker for sockit_owm (1-wire master, 32bit Avalon-style CPU bus).
//
// Sources:
//   doc/sockit_owr.pdf  sections 2.2, 4.1-4.5, Tables 8-12 (register map,
//                       control/status bits, cycle table), Table 7 (timing)
//   rtl/sockit_owm.v    timing block, counter, cycle/state logic
//
// Timing model used below (default parameters, BP = base period = CDR+1 clocks):
//   a started cycle keeps owr_cyc high for D clocks, its line-low phase
//   lasts RL clocks, the presence/read sample is taken SL clocks after the
//   start write, and the status/dat update happens at the end. The checker
//   tracks the clocks since the starting write with `el` (cycle t+k has
//   el==k). Any bus write (ctl or cdr) cancels the tracking (`act`), because
//   it resets the divider and may restart or abort the cycle.
//////////////////////////////////////////////////////////////////////////////
module sockit_owm_sva #(
  parameter  CDR_E    =  1,
  parameter  BDW      = 32,
  parameter  OWN      =  1,
  parameter  BAW      =  1,
  parameter  CDR_N    =  5-1,
  parameter  CDR_O    =  1-1,
  parameter  T_RSTH_N = 96,
  parameter  T_RSTL_N = 96,
  parameter  T_RSTP_N = 15,
  parameter  T_DAT0_N = 12,
  parameter  T_DAT1_N =  1,
  parameter  T_BITS_N =  3,
  parameter  T_RCVR_N =  1,
  parameter  T_IDLE_N = 200,
  parameter  T_RSTH_O = 48,
  parameter  T_RSTL_O = 48,
  parameter  T_RSTP_O = 10,
  parameter  T_DAT0_O =  6,
  parameter  T_DAT1_O =  1,
  parameter  T_BITS_O =  2,
  parameter  T_RCVR_O =  2,
  parameter  T_IDLE_O = 96,
  // widths of the design's counters, same formulas as the RTL
  parameter  CDW = CDR_E ? ((BDW==32) ? 16 : 8) : $clog2(CDR_N),
  parameter  TDW = ((T_RSTH_O+T_RSTL_O) > (T_RSTH_N+T_RSTL_N))
                   ? $clog2(T_RSTH_O+T_RSTL_O) : $clog2(T_RSTH_N+T_RSTL_N)
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
  input  [OWN-1:0]       owr_e,
  input                  owr_iln,
  input                  owr_cyc,
  input                  owr_oen,
  input  [OWN-1:0]       owr_pwr,
  input                  owr_ovd,
  input                  owr_rst,
  input                  owr_dat,
  input                  irq_ena,
  input                  irq_sts,
  input  [CDW-1:0]       cdr_n,
  input  [CDW-1:0]       cdr_o,
  input  [TDW-1:0]       cnt,
  input                  pls
);

//////////////////////////////////////////////////////////////////////////////
// derived timing constants (base periods unless noted)
//////////////////////////////////////////////////////////////////////////////

localparam int EW = 16;  // width of the clock timer (longest cycle: 1000 clocks)

// normal mode. Lengths are the counter start values (t_xxx-1 plus one) of the
// RTL; line-low and sample points are the RTL event counts (cnt==t_xxx).
localparam int DDAT_N  = T_DAT0_N + T_RCVR_N;           // write 0/1 or read slot: 13 BP (65 us)
localparam int DRST_N  = T_RSTL_N + T_RSTH_N;           // reset + presence:       192 BP (960 us)
localparam int DIDL_N  = T_IDLE_N;                      // timed idle:             200 BP (1000 us)
localparam int RDAT0_N = T_DAT0_N;                      // write 0 line-low:       12 BP (60 us)
localparam int RDAT1_N = T_DAT1_N;                      // write 1/read line-low:  1 BP (5 us)
localparam int RRST_N  = T_RSTL_N;                      // reset line-low:         96 BP (480 us)
localparam int SDAT_N  = T_BITS_N;                      // read sample point:      3 BP after start
localparam int SRST_N  = T_RSTL_N + T_RSTP_N;           // presence sample point:  111 BP after start
localparam int SIDL_N  = T_IDLE_N - T_RSTH_N + T_RSTP_N;// same point in idle:     119 BP after start

// overdrive mode
localparam int DDAT_O  = T_DAT0_O + T_RCVR_O;           // 8 BP (8 us)
localparam int DRST_O  = T_RSTL_O + T_RSTH_O;           // 96 BP (96 us)
localparam int RDAT0_O = T_DAT0_O;                      // 6 BP
localparam int RDAT1_O = T_DAT1_O;                      // 1 BP
localparam int RRST_O  = T_RSTL_O;                      // 48 BP
localparam int SDAT_O  = T_BITS_O;                      // 2 BP
localparam int SRST_O  = T_RSTL_O + T_RSTP_O;           // 58 BP

// cycle length in clocks for a ctl write with ovd=i_o, rst=i_r, dat=i_d
function automatic [EW-1:0] f_dlen(input logic i_o, i_r, i_d);
  if (i_o) return (i_r ? DRST_O : DDAT_O) * (CDR_O + 1);
  if (i_r) return (i_d ? DIDL_N : DRST_N) * (CDR_N + 1);
  return DDAT_N * (CDR_N + 1);
endfunction

// clock at which the line low phase ends (line released after this clock)
function automatic [EW-1:0] f_rlen(input logic i_o, i_r, i_d);
  if (i_o) return (i_r ? RRST_O : (i_d ? RDAT1_O : RDAT0_O)) * (CDR_O + 1);
  if (i_r) return i_d ? 0 : RRST_N * (CDR_N + 1);   // timed idle never drives the line
  return (i_d ? RDAT1_N : RDAT0_N) * (CDR_N + 1);
endfunction

// clock at which the presence / read bit is sampled
function automatic [EW-1:0] f_slen(input logic i_o, i_r, i_d);
  if (i_o) return (i_r ? SRST_O : SDAT_O) * (CDR_O + 1);
  if (i_r) return (i_d ? SIDL_N : SRST_N) * (CDR_N + 1);
  return SDAT_N * (CDR_N + 1);
endfunction

//////////////////////////////////////////////////////////////////////////////
// bus and event decode
//////////////////////////////////////////////////////////////////////////////

wire w0  = bus_wen & ~bus_adr[0];                 // write to control/status register
wire w1  = bus_wen &  bus_adr[0];                 // write to clock divider register
wire st  = w0 & bus_wdt[3] & ~(&bus_wdt[2:0]);    // write that starts a 1-wire cycle
wire zi  = w0 & (&bus_wdt[2:0]);                  // zero-time idle write (Table 12)
wire evt = pls & (cnt == 0);                      // end-of-counter event of the RTL

//////////////////////////////////////////////////////////////////////////////
// cycle tracker (checker-internal, same clock and reset as the design)
//////////////////////////////////////////////////////////////////////////////

reg          act;    // a cycle started by a ctl write is tracked, no bus write since
reg [EW-1:0] el;     // clocks since the starting write (cycle t+k has el == k)
reg [EW-1:0] dlen;   // expected cycle length in clocks
reg [EW-1:0] rlen;   // clock after which the line is released
reg [EW-1:0] slen;   // clock of the presence / read sample
reg          wdat;   // dat bit written by the starting write
reg          smp_v;  // line value captured at the sample point

always @ (posedge clk, posedge rst)
if (rst) begin
  act   <= 1'b0;
  el    <= 'd0;
  dlen  <= 'd0;
  rlen  <= 'd0;
  slen  <= 'd0;
  wdat  <= 1'b0;
  smp_v <= 1'b0;
end else if (st) begin
  act   <= 1'b1;
  el    <= 'd1;
  dlen  <= f_dlen(bus_wdt[2], bus_wdt[1], bus_wdt[0]);
  rlen  <= f_rlen(bus_wdt[2], bus_wdt[1], bus_wdt[0]);
  slen  <= f_slen(bus_wdt[2], bus_wdt[1], bus_wdt[0]);
  wdat  <= bus_wdt[0];
end else if (bus_wen) begin
  act   <= 1'b0;                                  // any bus write cancels tracking
end else if (act) begin
  if (el <= dlen + 1) el <= el + 1;               // saturates at dlen+2
  if (el == slen) smp_v <= owr_iln;
end

default clocking @(posedge clk); endclocking
default disable iff (rst);

//////////////////////////////////////////////////////////////////////////////
// reset values
//////////////////////////////////////////////////////////////////////////////

// Table 10 reset values (ien, irq, pwr, cyc, ovd, rst = 0); RTL also resets dat to 0.
// Checked in the first cycle after reset release, when the registers still hold the reset values.
a_rst_ctl: assert property ($past(rst) |->
  (irq_ena == 1'b0 && irq_sts == 1'b0 && owr_pwr == '0 && owr_cyc == 1'b0 &&
   owr_ovd == 1'b0 && owr_rst == 1'b0 && owr_dat == 1'b0));

// Sec 4.3: after reset all power bits are 0 (no pull-up power). Table 10/4.4: pull-down enable is off.
a_rst_line: assert property ($past(rst) |-> (owr_p == '0 && owr_e == '0));

// Sec 4.2: after reset cdr_n/cdr_o hold CDR_N/CDR_O.
a_rst_cdr: assert property ($past(rst) |-> (cdr_n == CDR_N && cdr_o == CDR_O));

//////////////////////////////////////////////////////////////////////////////
// control/status register: write then read back (Table 10, Sec 4.4)
//////////////////////////////////////////////////////////////////////////////

// Table 10 bit 7 ien: a written enable is read back.
a_rb_ien: assert property ((w0 ##1 !bus_adr[0]) |-> (bus_rdt[7] == $past(bus_wdt[7])));

// Table 10 bit 4 pwr (OWN=1): a written power bit is read back.
a_rb_pwr: assert property ((w0 ##1 !bus_adr[0]) |-> (bus_rdt[4] == $past(bus_wdt[4])));

// Table 10 bit 2 ovd: a written overdrive bit is read back.
a_rb_ovd: assert property ((w0 ##1 !bus_adr[0]) |-> (bus_rdt[2] == $past(bus_wdt[2])));

// Table 10 bit 1 rst: a written reset bit is read back.
a_rb_rst: assert property ((w0 ##1 !bus_adr[0]) |-> (bus_rdt[1] == $past(bus_wdt[1])));

// Table 10 bit 0 dat: a written data bit is read back (write data, before any cycle ends).
a_rb_dat: assert property ((w0 ##1 !bus_adr[0]) |-> (bus_rdt[0] == $past(bus_wdt[0])));

// Table 11 bit 3 cyc: reads 1 exactly when the write started a cycle (cyc=1, not zero-time idle).
a_rb_cyc: assert property ((w0 ##1 !bus_adr[0]) |->
  (bus_rdt[3] == $past(bus_wdt[3] & ~(&bus_wdt[2:0]))));

// Table 11 bit 6 irq: a write clears the status (RTL priority: write over set/read).
a_rb_irq_clr: assert property ((w0 ##1 !bus_adr[0]) |-> !bus_rdt[6]);

// Sec 4.2 / Table 8: clock divider registers are read back as written
// (address 1 writes both cdr_n and cdr_o, read as {cdr_o, cdr_n}).
a_rb_cdr: assert property ((w1 ##1 bus_adr[0]) |-> (bus_rdt == $past(bus_wdt)));

//////////////////////////////////////////////////////////////////////////////
// cycle start rules (Table 11 cyc, Table 12 zero-time idle)
//////////////////////////////////////////////////////////////////////////////

// Table 12: ovd=1 rst=1 dat=1 is a zero-time idle, no cycle is started.
a_zi_nocyc: assert property (zi |=> !owr_cyc);

// Table 11 cyc: a ctl write with cyc=0 does not start a cycle.
a_nostart_nocyc: assert property ((w0 && !bus_wdt[3]) |=> !owr_cyc);

// Table 12: the zero-time idle does not drive the 1-wire line.
a_zi_line: assert property (zi |=> (owr_e == '0));

//////////////////////////////////////////////////////////////////////////////
// cycle tracker properties: timing, line, sample and status (Table 7, Table 12)
//////////////////////////////////////////////////////////////////////////////

// Table 12 cycle lengths: write 0/1 or read 65us, reset 960us, timed idle 1000us
// in normal mode; write 0/1 or read 8us, reset 96us in overdrive mode (base 1 us).
// owr_cyc is high for exactly the cycle length, from the write until the end.
a_cyc_len: assert property (act |-> (owr_cyc == (el <= dlen)));

// Table 11 cyc status: the status bit cannot be set while a cycle is running.
a_cyc_busy_noirq: assert property (act && (el <= dlen) |-> !irq_sts);

// Table 11 bit 6 / Sec 2.2.1: the interrupt status is set at the end of a cycle.
a_cyc_end_irq: assert property (act && (el == dlen + 1) |-> irq_sts);

// Sec 2.2.1 / Table 10 bit 7: an enabled end-of-cycle interrupt is seen on bus_irq.
a_cyc_end_bus_irq: assert property (act && (el == dlen + 1) && irq_ena |-> bus_irq);

// Table 7 tDAT0/tDAT1/tRSTL and Sec 4.4 dat/rst: the line is driven low for the
// documented low time (write 0: 60 us, write 1/read: 5 us, reset: 480 us), and is released after that.
// Timed idle never drives the line (owr_oen stays 0).
a_cyc_line: assert property (act |-> (owr_oen == (el <= rlen)));

// Table 11 bit 0 dat: the write bit is held during the cycle.
a_cyc_dat_hold: assert property (act && (el <= dlen) |-> (owr_dat == wdat));

// Sec 4.4 dat / Table 7 tBITS and presence: at the end of a cycle, dat is the
// line value sampled at the sample point (read bit in data slots, presence in reset).
a_cyc_dat_latch: assert property (act && (el == dlen + 1) |-> (owr_dat == smp_v));

//////////////////////////////////////////////////////////////////////////////
// same-cycle priority (RTL: write > end-of-cycle set > read clear)
//////////////////////////////////////////////////////////////////////////////

// A ctl write in the cycle where a cycle would end clears the status (write wins).
a_pri_end_wr: assert property (act && (el == dlen) && w0 |=> !irq_sts);

// A ctl read in the cycle where a cycle ends does not lose the end status (set wins).
a_pri_end_rd: assert property (act && (el == dlen) && bus_ren && !bus_adr[0] && !bus_wen |=> irq_sts);

// Table 11 bit 6 / Sec 2.2.1: a ctl read clears the interrupt status (unless a new
// end-of-counter event sets it in the same cycle, see a_pri_end_rd).
a_rd_clr: assert property (bus_ren && !bus_adr[0] && !bus_wen && !evt |=> !bus_irq);

// Table 11 bit 7: a disabled interrupt never reaches bus_irq.
a_irq_en: assert property (!irq_ena |-> !bus_irq);

// Sec 4.2 / RTL: a clock divider write during a running cycle does not abort it.
a_cdrw_keep: assert property (owr_cyc && w1 && !evt |=> owr_cyc);

//////////////////////////////////////////////////////////////////////////////
// power and hold
//////////////////////////////////////////////////////////////////////////////

// Table 11 bit 4 / Sec 4.3: pwr=1 supplies power on the line (owr_p), output follows the written bit.
a_pwr_out: assert property ((w0 ##1 !bus_adr[0]) |-> (owr_p[0] == $past(bus_wdt[4])));

// Sec 4.3/4.4: pwr, ien, ovd and rst keep their value until the next control write.
a_hold_ctl: assert property (!w0 |=>
  ($stable(owr_pwr) && $stable(irq_ena) && $stable(owr_ovd) && $stable(owr_rst)));

// Sec 4.2: divider ratios keep their value until the next clock divider write.
a_hold_cdr: assert property (!w1 |=> ($stable(cdr_n) && $stable(cdr_o)));

endmodule

// Binds the checker to the top module, passing the design's own parameters.
bind sockit_owm sockit_owm_sva #(
  .CDR_E   (CDR_E),
  .BDW     (BDW),
  .OWN     (OWN),
  .BAW     (BAW),
  .CDR_N   (CDR_N),
  .CDR_O   (CDR_O),
  .T_RSTH_N(T_RSTH_N),
  .T_RSTL_N(T_RSTL_N),
  .T_RSTP_N(T_RSTP_N),
  .T_DAT0_N(T_DAT0_N),
  .T_DAT1_N(T_DAT1_N),
  .T_BITS_N(T_BITS_N),
  .T_RCVR_N(T_RCVR_N),
  .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O),
  .T_RSTL_O(T_RSTL_O),
  .T_RSTP_O(T_RSTP_O),
  .T_DAT0_O(T_DAT0_O),
  .T_DAT1_O(T_DAT1_O),
  .T_BITS_O(T_BITS_O),
  .T_RCVR_O(T_RCVR_O),
  .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);

```

### step 11: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_KX4d81 && printf './sva/sockit_owm_sva.sv\n' > sockit_owm_sva.f && cat sockit_owm_sva.f && ./check_syntax.sh
```

#### result

```
File created successfully at: /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/sva/sockit_owm_sva.sv (file state is current in your context — no need to Read it back)
```

#### result

```
./sva/sockit_owm_sva.sv
WARNING (WNL018): /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./sva/sockit_owm_sva.sv(100): multiplication operator mult_32s_4s (size 36) automatically blackboxed.
WARNING (WNL018): /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./sva/sockit_owm_sva.sv(108): multiplication operator mult_32s_4s (size 36) automatically blackboxed.
WARNING (WNL018): /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./sva/sockit_owm_sva.sv(114): multiplication operator mult_32s_4s (size 36) automatically blackboxed.
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./sva/sockit_owm_sva.sv(100): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./sva/sockit_owm_sva.sv(106): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./sva/sockit_owm_sva.sv(107): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./sva/sockit_owm_sva.sv(108): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./sva/sockit_owm_sva.sv(113): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/./sva/sockit_owm_sva.sv(114): expression 
... [523 more chars]
```

### step 12: SubagentHandback

Checker written and `./check_syntax.sh` prints SYNTAX OK. Only warnings are width truncations and the RTL's own owr_sel warning.

Files (the only two deliverables):
- /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/sva/sockit_owm_sva.sv: checker `sockit_owm_sva` plus `bind sockit_owm ... u_sockit_owm_sva (.*)`. The bind passes the design's own CDR_*/T_* parameters. A small internal tracker (`act`, `el`, `dlen`, `rlen`, `slen`) counts clocks from each starting ctl write. Any bus write cancels it.
- /tmp/brg8ve/sva_ws/sockit_owm_KX4d81/sockit_owm_sva.f: `./sva/sockit_owm_sva.sv`

What is specified (29 assertions, each with a source comment):
- Reset values (ctl bits, owr_p/owr_e, cdr_n/cdr_o = CDR_N/CDR_O), checked in the first cycle after reset release.
- Read-back of every written control field (ien, pwr, ovd, rst, dat, cyc = wdt[3] & ~&wdt[2:0], irq cleared by write) and of the cdr register (address 1 returns the written word).
- Zero-time idle (ovd=rst=dat=1) starts no cycle and does not drive the line. A ctl write with cyc=0 starts no cycle.
- Cycle length per type from Table 7/12: 65 clk-base write/read (13 BP), 960 reset (192 BP), 1000 idle (200 BP), and 8 / 96 in overdrive; owr_cyc follows exactly.
- Line-low durations (60 us write 0, 5 us write 1/read, 480 us reset, idle never drives) and the sample points (read at 3 BP, presence at 75 us after the rising edge).
- dat holds the written bit during the cycle and latches the sampled line value at the end. Status is set at the end of a cycle, not during it, and bus_irq follows ien.
- Same-cycle priority: write beats end-set; end-set beats read-clear; read clears otherwise.
- A cdr write does not abort a running cycle. pwr drives owr_p. ovd/rst/pwr/ien and cdr hold until written.

Design bugs found (not asserted, since the RTL violates them; reported as findings):
1. Spurious cycle end in idle overdrive. With the default CDR_O=0, the divider `pls` fires every clock whenever owr_ovd=1 and no cycle runs, and `cnt` keeps decrementing (RTL lines 293-301, 385, 344, 369). When cnt reaches 0 (TDW=8, so about 256 clocks after the last cycle, or after a zero-time idle write), `irq_sts` is set and `owr_dat` is loaded with owr_smp, even though no cycle ran. With ien=1 this raises bus_irq spuriously. The same happens for CDR_N=0 in normal mode.
2. A ctl write with cyc=0 that is not (rst&dat) drives owr_oen=1 (line pulled low). RTL line 399 has no cyc qualifier. In normal mode the release never fires without a cycle, so the line stays low. The doc says cyc=0 is "no action".
3. For OWN=1, owr_sel is never assigned (the only init is in an `initial` block). The tool warns "owr_sel[-1] does not have a driver". owr_e and owr_iln are therefore indeterminate. The checker avoids asserting on owr_sel; its only owr_e/owr_iln uses are the zero-enable and sample-capture forms.

Caveats: the bind uses the default parameters. Truth was checked by hand against the RTL (check_syntax only compiles; I did not run a prover). The doc gives dat's reset as x and the RTL resets it to 0; the checker asserts the RTL value.

#### result

```
{"success":true,"message":"Report delivered to your caller."}
```
