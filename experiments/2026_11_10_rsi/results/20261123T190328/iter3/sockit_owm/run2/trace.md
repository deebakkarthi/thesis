# Generator trace

source: /tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tasks/ae5e3548e85399721.output

note: 10 thinking block(s) were stored without text.

### step 1: Bash

```
cat /tmp/brg8ve/sva_ws/sockit_owm_muudzr/TASK.md
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
... [8796 more chars]
```

### step 2: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_muudzr && find . -type f | head -100 && echo --- && cat *.tcl && echo --- && cat *.f && echo --- && cat check_syntax.sh
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
cd /tmp/brg8ve/sva_ws/sockit_owm_muudzr && cat rtl/sockit_owm.v && echo --- && cat sockit_owm.f && echo && pdftotext -layout doc/sockit_owr.pdf - | wc -l
```

#### result

```
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
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.   //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// The clock divider parameter is computed with the next formula:           //
//                                                                          //
// CDR_N = f_CLK * BTP_N - 1  (example: CDR_N = 1MHz * 5.0us - 1 = 5-1)     //
// CDR_O = f_CLK * BTP_O - 1  (example: CDR_O = 1MHz * 1.0us - 1 = 1-1)     //
//                                                                          //
// If the dividing factor is not a round integer, than the timing of the    //
// controller will be slightly off, and would support only a subset of      //
// 1-wire devices with timing closer to the typical 30us slot.              //
//                                                                          //
// Base time periods BTP_N = "5.0" and BTP_O = "1.0" are optimized for      //
// onewire timing. The default timing restricts the range of available      //
// frequences to multiples of 1MHz.                                         //
//                                                                          //
// If even this restrictions are too strict use timing BTP_N = "6.0" and   
... [14669 more chars]
```

### step 4: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_muudzr && pdftotext -layout doc/sockit_owr.pdf - | sed -n 1,600p
```

### step 5: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_muudzr && pdftotext -layout doc/sockit_owr.pdf - | sed -n 600,1214p
```

#### result

```
<persisted-output>
Output too large (35.9KB). Full output saved to: /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/bfrhou978.txt

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
cd /tmp/brg8ve/sva_ws/sockit_owm_muudzr && pdftotext -layout doc/sockit_owr.pdf /tmp/brg8ve/sva_ws/doc_sockit.txt 2>/dev/null; pdftotext -layout doc/sockit_owr.pdf - | sed -n 40,330p
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
... [16011 more chars]
```

### step 7: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_muudzr && pdftotext -layout doc/sockit_owr.pdf - | sed -n 330,600p
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

### assistant

I have the RTL, the datasheet, and the setup script. Next I'll write the checker, starting with the behaviour list I derived from the RTL and datasheet.

### step 8: Bash

```
mkdir -p /tmp/brg8ve/sva_ws/sockit_owm_muudzr/sva && ls /tmp/brg8ve/sva_ws/sockit_owm_muudzr/
```

#### result

```
check_syntax.sh
doc
rtl
sockit_owm.f
sockit_owm.tcl
sva
TASK.md
```

### step 9: Write

file: /tmp/brg8ve/sva_ws/sockit_owm_muudzr/sva/sockit_owm_sva.sv

```
// SVA checker for sockit_owm (1-wire master), default parameters.
// Sources:
//   DOC  = doc/sockit_owr.pdf (sections 2.1-4.5, Tables 8-12)
//   RTL  = rtl/sockit_owm.v (named construct)
//
// Derived timing model (used by the cycle/line/sample assertions):
//   pc  : number of base-period pulses (pls) seen while owr_cyc is set since
//         the last control write (W0). At pulse P_k the value is pc = k-1.
//   exp_n : cycle length in base periods, latched at W0 from the written
//         ovd/rst/dat bits (DOC Table 12 / Table 7).

module sockit_owm_sva #(
  parameter BDW     = 32,
  parameter BAW     = 1,
  parameter OWN     = 1,
  parameter CDR_E   = 1,
  parameter CDR_N   = 4,
  parameter CDR_O   = 0,
  parameter T_RSTH_N = 96, parameter T_RSTL_N = 96, parameter T_RSTP_N = 15,
  parameter T_DAT0_N = 12, parameter T_DAT1_N = 1,  parameter T_BITS_N = 3,
  parameter T_RCVR_N = 1,  parameter T_IDLE_N = 200,
  parameter T_RSTH_O = 48, parameter T_RSTL_O = 48, parameter T_RSTP_O = 10,
  parameter T_DAT0_O = 6,  parameter T_DAT1_O = 1,  parameter T_BITS_O = 2,
  parameter T_RCVR_O = 2,  parameter T_IDLE_O = 96,
  parameter CDW = (CDR_E ? ((BDW == 32) ? 16 : 8) : $clog2(CDR_N)),
  parameter TDW = ((T_RSTH_O + T_RSTL_O) > (T_RSTH_N + T_RSTL_N))
                ? $clog2(T_RSTH_O + T_RSTL_O) : $clog2(T_RSTH_N + T_RSTL_N)
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
  input                owr_cyc,
  input                owr_ovd,
  input                owr_rst,
  input                owr_dat,
  input                owr_oen,
  input                owr_smp,
  input                owr_iln,
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

// control register write (ctl at address 0), cdr write (address 1), ctl read
wire w0 = bus_wen & ~bus_adr[0];
wire w1 = bus_wen & bus_adr[0];
wire r0 = bus_ren & ~bus_adr[0];

// end of count: the RTL end event (pls & cnt==0), and the same qualified by a running cycle
wire endp = pls & (cnt == '0);
wire endc = endp & owr_cyc;

// cycle type of the currently latched control bits
wire typ_w0 = ~owr_rst & ~owr_dat;   // write 0 slot
wire typ_w1 = ~owr_rst &  owr_dat;   // write 1 / read slot
wire typ_rs =  owr_rst & ~owr_dat;   // reset + presence slot
wire typ_id =  owr_rst &  owr_dat;   // timed idle slot

// pulse indices (pc value at the pulse) for release, presence sample, bit sample
wire [7:0] rel_w0  = owr_ovd ? (T_DAT0_O - 1)           : (T_DAT0_N - 1);
wire [7:0] rel_w1  = owr_ovd ? (T_DAT1_O - 1)           : (T_DAT1_N - 1);
wire [7:0] rel_rs  = owr_ovd ? (T_RSTL_O - 1)           : (T_RSTL_N - 1);
wire [7:0] pres_pc = owr_ovd ? (T_RSTL_O + T_RSTP_O - 1) : (T_RSTL_N + T_RSTP_N - 1);
wire [7:0] samp_pc = owr_ovd ? (T_BITS_O - 1)           : (T_BITS_N - 1);

// cycle length in base periods for a control write (DOC Table 12, Table 7)
function automatic [7:0] cyc_len(input logic o, input logic r, input logic d);
  if (!o) begin
    if (!r)      cyc_len = T_DAT0_N + T_RCVR_N;   // write 0 / write 1 (65 us)
    else if (!d) cyc_len = T_RSTL_N + T_RSTH_N;   // reset + presence (960 us)
    else         cyc_len = T_IDLE_N;              // timed idle (1000 us)
  end else begin
    if (!r)      cyc_len = T_DAT0_O + T_RCVR_O;   // overdrive write (8 us)
    else if (!d) cyc_len = T_RSTL_O + T_RSTH_O;   // overdrive reset (96 us)
    else         cyc_len = 8'd0;                  // overdrive zero-time idle: no cycle
  end
endfunction

logic [7:0] pc;
logic [7:0] exp_n;

always @(posedge clk or posedge rst)
  if (rst) begin
    pc    <= 8'd0;
    exp_n <= 8'd0;
  end else if (w0) begin
    pc    <= 8'd0;
    exp_n <= cyc_len(bus_wdt[2], bus_wdt[1], bus_wdt[0]);
  end else if (pls & owr_cyc) begin
    pc    <= pc + 8'd1;
  end

//////////////////////////////////////////////////////////////////////////////
// reset values (DOC Table 10; RTL reset branches)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC 4.2 "reset value of the registers will be as defined by CDR_N"
a_rst_cdr_n: assert property ($past(rst) |-> cdr_n == CDR_N);

// Source: DOC 4.2 "... and CDR_O parameters"
a_rst_cdr_o: assert property ($past(rst) |-> cdr_o == CDR_O);

// Source: DOC Table 10 reset column (ien, irq, pwr, cyc, ovd, rst = 0); RTL resets
// owr_dat and owr_pwr to 0 as well. No 1-wire cycle is active after reset.
a_rst_ctl: assert property ($past(rst) |-> !owr_cyc && !irq_ena && !irq_sts &&
                                           !owr_pwr && !owr_ovd && !owr_rst && !owr_dat);

// Source: RTL output register reset (owr_oen <= 0); line is not driven after reset.
a_rst_line: assert property ($past(rst) |-> !owr_oen);

// Source: RTL clock divider and cycle counter reset (div <= 0, cnt <= 0).
a_rst_div: assert property ($past(rst) |-> div == '0 && cnt == '0);

//////////////////////////////////////////////////////////////////////////////
// write / read-back of the control/status register (DOC Table 10, 11)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC Table 11 bit 7 ien. A control write followed by a read returns the bit.
a_rb_ien: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[7] == $past(bus_wdt[7]));

// Source: DOC Table 11 bit 6 irq: cleared by a control write (RTL irq_sts priority).
a_rb_irq: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[6] == 1'b0);

// Source: DOC Table 11 bit 4 pwr (readback of the written value).
a_rb_pwr: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[4] == $past(bus_wdt[4]));

// Source: DOC Table 11 bit 3 cyc: a write with cyc=1 and not the zero-time idle code reads back 1.
a_rb_cyc: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |->
          bus_rdt[3] == $past(bus_wdt[3] & ~(bus_wdt[2] & bus_wdt[1] & bus_wdt[0])));

// Source: DOC Table 11 bit 2 ovd.
a_rb_ovd: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[2] == $past(bus_wdt[2]));

// Source: DOC Table 11 bit 1 rst.
a_rb_rst: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[1] == $past(bus_wdt[1]));

// Source: DOC Table 11 bit 0 dat (write value, read back before any cycle end).
a_rb_dat: assert property ((bus_wen & ~bus_adr[0]) ##1 r0 |-> bus_rdt[0] == $past(bus_wdt[0]));

// Source: DOC 4.2 / Table 8: address 1 holds cdr_n (bits 15..0) and cdr_o (bits 31..16);
// one write to address 1 loads both, a read returns them unchanged.
a_rb_cdr: assert property ((bus_wen & bus_adr[0]) ##1 (bus_ren & bus_adr[0]) |->
          bus_rdt == $past(bus_wdt));

// Source: DOC Table 11 bit 6 read: the status bit reads the interrupt status flag.
a_rb_irq_status: assert property (r0 |-> bus_rdt[6] == irq_sts);

//////////////////////////////////////////////////////////////////////////////
// holding behaviour: registers keep their value unless their documented event occurs
//////////////////////////////////////////////////////////////////////////////

// Source: RTL cdr_n/cdr_o load only on a write to address 1 (DOC 4.2 "written ... while no cycle").
a_hold_cdr_n: assert property (!w1 |=> $stable(cdr_n));
a_hold_cdr_o: assert property (!w1 |=> $stable(cdr_o));

// Source: RTL irq_ena, owr_pwr, owr_ovd, owr_rst load only on a control write.
a_hold_ctl: assert property (!w0 |=> $stable({irq_ena, owr_pwr, owr_ovd, owr_rst}));

// Source: RTL owr_cyc changes only on a control write or on the cycle end event.
a_hold_cyc: assert property (!w0 && !endc |=> $stable(owr_cyc));

// Source: RTL owr_dat loads on control write or on the end event (pls & cnt==0).
a_hold_dat: assert property (!w0 && !endp |=> $stable(owr_dat));

// Source: RTL irq_sts holds unless a control write, a control read, or the end event occurs.
a_hold_irq: assert property (!w0 && !r0 && !endp |=> $stable(irq_sts));

// Source: RTL owr_oen loads on control write or on a base-period pulse.
a_hold_oen: assert property (!w0 && !pls |=> $stable(owr_oen));

// Source: RTL cnt loads on control write and decrements only on pls.
a_hold_cnt: assert property (!w0 && !pls |=> $stable(cnt));

// Source: RTL owr_smp loads only on a base-period pulse (its enable is pls).
a_hold_smp: assert property (!pls |=> $stable(owr_smp));

// Source: DOC 4.3 "power ... directly connected" to owr_p; changes only with pwr writes.
a_hold_p: assert property (!w0 |=> $stable(owr_p));

//////////////////////////////////////////////////////////////////////////////
// power output (DOC 2.2.2, 4.3, Table 11 bit 4)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC 4.3 "power[15:0] ... pwr bit from the control/status register is used" (OWN=1).
a_pwr_wr: assert property (w0 |=> owr_p == $past(bus_wdt[4]));

//////////////////////////////////////////////////////////////////////////////
// control write starts/aborts a 1-wire cycle (DOC Table 11 bit 3, Table 12)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC Table 11 bit 3 (write 1 starts a cycle); zero-time idle (ovd=rst=dat=1) is
// the RTL code `wdt[3] & ~&wdt[2:0]` = 0 and DOC Table 12 "0us zero time idle".
a_w0_cyc_start: assert property (w0 |=>
                owr_cyc == $past(bus_wdt[3] & ~(bus_wdt[2] & bus_wdt[1] & bus_wdt[0])));

// Source: RTL `owr_oen <= ~&bus_wdt[1:0]` on a control write: the line is enabled unless
// the written code is the idle cycle (rst=dat=1). NOTE: DOC Table 11 says cyc=0 is no action;
// the RTL still updates owr_oen then (see report). This assertion states the RTL behaviour.
a_w0_line: assert property (w0 |=> owr_oen == !$past(bus_wdt[1] & bus_wdt[0]));

//////////////////////////////////////////////////////////////////////////////
// cycle timing (DOC Table 12, Table 7; counter in base periods)
//////////////////////////////////////////////////////////////////////////////

// Source: RTL cnt loads (T-1) on W0 and decrements per pulse (counter step).
a_cnt_step: assert property (pls & ~w0 & (cnt != '0) |=> cnt == $past(cnt) - 1);

// Source: DOC Table 12 cycle lengths (65/960/1000 us normal, 8/96 us overdrive, in base
// periods) and RTL cnt end condition: the end pulse (cnt==0) is the (exp_n)-th pulse.
// Covers start value, end condition and the restart by a new control write.
a_cyc_len: assert property ((pls & owr_cyc & ~w0) |->
           ((pc == exp_n - 8'd1) == (cnt == '0)));

// Source: RTL `if (pls & cnt==0) owr_cyc <= 0`: the cycle ends at the end event.
a_cyc_end: assert property (endc & ~w0 |=> ~owr_cyc);

//////////////////////////////////////////////////////////////////////////////
// 1-wire line drive (DOC Table 12 waveforms; RTL owr_oen chain)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC 3.2 / Drawing 5: write 0 slot drives the line for T_DAT0 base periods.
// RTL: owr_oen is held 1 until the pulse with cnt==t_dat0 (= pc == T_DAT0-1).
a_line_w0_pre: assert property (owr_cyc & typ_w0 & (pc < rel_w0) |-> owr_oen);
a_line_w0_rel: assert property (pls & owr_cyc & typ_w0 & (pc == rel_w0) & ~w0 |=> ~owr_oen);
a_line_w0_post: assert property (owr_cyc & typ_w0 & (pc > rel_w0) |-> ~owr_oen);

// Source: DOC 3.2 / Drawing 6: write 1 / read slot drives the line for T_DAT1 base periods.
a_line_w1_rel: assert property (pls & owr_cyc & typ_w1 & (pc == rel_w1) & ~w0 |=> ~owr_oen);

// Source: DOC 4.5 / Table 12 reset slot: line low for T_RSTL base periods, then released.
a_line_rs_pre: assert property (owr_cyc & typ_rs & (pc < rel_rs) |-> owr_oen);
a_line_rs_rel: assert property (pls & owr_cyc & typ_rs & (pc == rel_rs) & ~w0 |=> ~owr_oen);
a_line_rs_post: assert property (owr_cyc & typ_rs & (pc > rel_rs) |-> ~owr_oen);

// Source: DOC Table 12 "timed idle cycle" and RTL idle branch: the line is never driven in idle.
a_line_idle: assert property (owr_cyc & typ_id |-> ~owr_oen);

// Source: DOC 2.2.2 / 4.3: the line driver output (owr_e) is only active when the internal
// enable is set. The select mux is unconstrained for OWN=1, so only the implication holds.
a_line_drv: assert property ((|owr_e) |-> owr_oen);

// Source: RTL cycle end clears the line enable (any cycle end).
a_line_end: assert property (endc & ~w0 |=> ~owr_oen);

//////////////////////////////////////////////////////////////////////////////
// sampling and data path (DOC 2.3, 4.4 bit 0; RTL owr_smp/owr_dat)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC 4.4 bit 0 "presence detect status" and RTL presence sample (owr_rst & cnt==t_rstp).
// Sampled at pc = T_RSTL + T_RSTP - 1, i.e. 15 base periods after the reset release (normal).
a_samp_pres: assert property (pls & owr_cyc & ~w0 & typ_rs & (pc == pres_pc)
                              |=> owr_smp == $past(owr_iln));

// Source: DOC 4.4 bit 0 "data receive status" and RTL read sample (cnt==t_bits, pc = T_BITS-1).
a_samp_rd: assert property (pls & owr_cyc & ~w0 & typ_w1 & (pc == samp_pc)
                            |=> owr_smp == $past(owr_iln));

// Source: DOC 4.4 bit 0 (read value of the slot) and RTL end latch (owr_dat <= owr_smp at end).
a_dat_rd: assert property (endc & ~w0 & typ_w1 |=> owr_dat == $past(owr_smp));

// Source: DOC 4.4 bit 0 (presence status) and RTL end latch after reset slot.
a_dat_pres: assert property (endc & ~w0 & typ_rs |=> owr_dat == $past(owr_smp));

//////////////////////////////////////////////////////////////////////////////
// clock divider (DOC 2.1.3 / 4.2 and RTL div logic)
//////////////////////////////////////////////////////////////////////////////

// Source: RTL `if (bus_wen) div <= 0` (a bus write restarts the divider).
a_div_wr: assert property (bus_wen |=> div == '0);

// Source: RTL `div <= div + owr_cyc` only inside a cycle: the divider is idle otherwise.
a_div_idle: assert property (~owr_cyc |-> div == '0);

// Source: RTL `div <= div + owr_cyc` (counter step while a cycle runs, no pulse, no write).
a_div_step: assert property (owr_cyc & ~bus_wen & ~pls |=> div == $past(div) + 1);

// Source: RTL pls = (div == ratio) and div <= 0 at pls: no back-to-back pulses for ratio != 0.
a_div_gap: assert property (pls & ~bus_wen & ((owr_ovd ? cdr_o : cdr_n) != '0) |=> ~pls);

//////////////////////////////////////////////////////////////////////////////
// interrupt (DOC Table 11 bits 6/7, 2.2.1; RTL irq logic)
//////////////////////////////////////////////////////////////////////////////

// Source: DOC Table 11 bit 6 "set on end of 1-wire cycle": RTL `pls & cnt==0` sets irq_sts.
a_irq_set: assert property (endc & ~w0 |=> irq_sts);

// Source: RTL irq_sts priority: it can only be set by the end event.
a_irq_set_only_end: assert property (~irq_sts & ~endp |=> ~irq_sts);

// Source: RTL irq_sts priority: a control write has priority over the end event (clears).
a_irq_wr_wins: assert property (w0 & endp |=> ~irq_sts);

// Source: DOC Table 11 bit 6 "cleared by bus read": RTL `else if (bus_ren_ctl_sts) irq_sts <= 0`.
a_irq_rd_clr: assert property (r0 & ~w0 & ~endp |=> ~irq_sts);

// Source: DOC 2.2.1 "interrupt is cleared after reading the control/status register".
// Interrupt output = enable AND status (RTL assign bus_irq).
a_irq_out_set: assert property (endc & ~w0 & irq_ena |=> bus_irq);
a_irq_out_gate: assert property (~irq_ena |-> ~bus_irq);
a_irq_out_sts: assert property (irq_ena & irq_sts |-> bus_irq);
a_irq_out_clr: assert property (r0 & ~w0 & ~endp |=> ~bus_irq);

endmodule

bind sockit_owm sockit_owm_sva #(
  .BDW(BDW), .BAW(BAW), .OWN(OWN), .CDR_E(CDR_E), .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_RSTP_N(T_RSTP_N),
  .T_DAT0_N(T_DAT0_N), .T_DAT1_N(T_DAT1_N), .T_BITS_N(T_BITS_N),
  .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_RSTP_O(T_RSTP_O),
  .T_DAT0_O(T_DAT0_O), .T_DAT1_O(T_DAT1_O), .T_BITS_O(T_BITS_O),
  .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);

```

#### result

```
File created successfully at: /tmp/brg8ve/sva_ws/sockit_owm_muudzr/sva/sockit_owm_sva.sv (file state is current in your context — no need to Read it back)
```

### step 10: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_muudzr && printf './sva/sockit_owm_sva.sv\n' > sockit_owm_sva.f && cat sockit_owm_sva.f && ./check_syntax.sh
```

#### result

```
./sva/sockit_owm_sva.sv
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./sva/sockit_owm_sva.sv(79): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./sva/sockit_owm_sva.sv(80): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./sva/sockit_owm_sva.sv(81): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./sva/sockit_owm_sva.sv(82): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./sva/sockit_owm_sva.sv(83): expression size 32 truncated to fit in target size 8
[WARN (VERI-9005)] /tmp/brg8ve/sva_ws/sockit_owm_muudzr/./rtl/sockit_owm.v(417): 2-bit index expression 'owr_sel' is larger than the required 1 bits. This might lead to an out-of-bound access
SYNTAX OK
```

### assistant

The syntax check passes. The remaining warnings are the RTL's undriven `owr_sel` (the OWN=1 select register is only set in an `initial` block) and width truncations in my own pulse-index wires. I'll make those wires explicitly 8-bit to clear my warnings.

### step 11: Edit

file: /tmp/brg8ve/sva_ws/sockit_owm_muudzr/sva/sockit_owm_sva.sv

old:
```
wire [7:0] rel_w0  = owr_ovd ? (T_DAT0_O - 1)           : (T_DAT0_N - 1);
wire [7:0] rel_w1  = owr_ovd ? (T_DAT1_O - 1)           : (T_DAT1_N - 1);
wire [7:0] rel_rs  = owr_ovd ? (T_RSTL_O - 1)           : (T_RSTL_N - 1);
wire [7:0] pres_pc = owr_ovd ? (T_RSTL_O + T_RSTP_O - 1) : (T_RSTL_N + T_RSTP_N - 1);
wire [7:0] samp_pc = owr_ovd ? (T_BITS_O - 1)           : (T_BITS_N - 1);
```
new:
```
wire [7:0] rel_w0  = owr_ovd ? 8'(T_DAT0_O - 1)            : 8'(T_DAT0_N - 1);
wire [7:0] rel_w1  = owr_ovd ? 8'(T_DAT1_O - 1)            : 8'(T_DAT1_N - 1);
wire [7:0] rel_rs  = owr_ovd ? 8'(T_RSTL_O - 1)            : 8'(T_RSTL_N - 1);
wire [7:0] pres_pc = owr_ovd ? 8'(T_RSTL_O + T_RSTP_O - 1) : 8'(T_RSTL_N + T_RSTP_N - 1);
wire [7:0] samp_pc = owr_ovd ? 8'(T_BITS_O - 1)            : 8'(T_BITS_N - 1);
```

### step 12: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_muudzr && ./check_syntax.sh 2>&1 | grep -v "sockit_owm.v"
```

#### result

```
The file /tmp/brg8ve/sva_ws/sockit_owm_muudzr/sva/sockit_owm_sva.sv has been updated successfully. (file state is current in your context — no need to Read it back)
```

#### result

```
SYNTAX OK
```

### assistant

Syntax is clean, with no warnings from my checker. Before reporting, I'm adding two read-mux assertions (status and cdr reads at every address) so every readable field is covered.

### step 13: Edit

file: /tmp/brg8ve/sva_ws/sockit_owm_muudzr/sva/sockit_owm_sva.sv

old:
```
// Source: DOC Table 11 bit 6 read: the status bit reads the interrupt status flag.
a_rb_irq_status: assert property (r0 |-> bus_rdt[6] == irq_sts);
```
new:
```
// Source: DOC Table 11 bit 6 read: the status bit reads the interrupt status flag.
a_rb_irq_status: assert property (r0 |-> bus_rdt[6] == irq_sts);

// Source: DOC Table 11 read column: a read of the control/status register returns the
// current enable, power, cycle status, overdrive, reset and data/presence bits.
a_rd_status: assert property (r0 |-> (bus_rdt[7] == irq_ena) && (bus_rdt[4] == owr_pwr[0]) &&
                                     (bus_rdt[3] == owr_cyc) && (bus_rdt[2] == owr_ovd) &&
                                     (bus_rdt[1] == owr_rst) && (bus_rdt[0] == owr_dat));

// Source: DOC Table 8 / 4.2: address 1 read returns cdr_n (15..0) and cdr_o (31..16).
a_rd_cdr: assert property ((bus_ren & bus_adr[0]) |-> bus_rdt == {cdr_o, cdr_n});
```

### step 14: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_muudzr && ./check_syntax.sh 2>&1 | grep -v "sockit_owm.v"; ls -la /tmp/brg8ve/sva_ws/sockit_owm_muudzr /tmp/brg8ve/sva_ws/sockit_owm_muudzr/sva
```

#### result

```
The file /tmp/brg8ve/sva_ws/sockit_owm_muudzr/sva/sockit_owm_sva.sv has been updated successfully. (file state is current in your context — no need to Read it back)
```

#### result

```
SYNTAX OK
/tmp/brg8ve/sva_ws/sockit_owm_muudzr:
total 32
drwx------  5 brg8ve users   143 Nov 23 20:16 .
drwxr-xr-x 12 brg8ve users  4096 Nov 23 20:09 ..
-rwxr-xr-x  1 brg8ve users   846 Nov 23 20:09 check_syntax.sh
drwxr-xr-x  2 brg8ve users    28 Nov 23 20:09 doc
drwxr-xr-x  2 brg8ve users    26 Nov 23 20:09 rtl
-rw-r--r--  1 brg8ve users    19 Nov 23 20:09 sockit_owm.f
-rw-r--r--  1 brg8ve users    24 Nov 23 20:16 sockit_owm_sva.f
-rw-r--r--  1 brg8ve users   224 Nov 23 20:09 sockit_owm.tcl
drwxr-xr-x  2 brg8ve users    31 Nov 23 20:17 sva
-rw-r--r--  1 brg8ve users 11815 Nov 23 20:09 TASK.md

/tmp/brg8ve/sva_ws/sockit_owm_muudzr/sva:
total 20
drwxr-xr-x 2 brg8ve users    31 Nov 23 20:17 .
drwx------ 5 brg8ve users   143 Nov 23 20:16 ..
-rw-r--r-- 1 brg8ve users 17175 Nov 23 20:17 sockit_owm_sva.sv
```

### step 15: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_muudzr && grep -c "assert property" sva/sockit_owm_sva.sv && grep -c "cover property" sva/sockit_owm_sva.sv; cat sockit_owm_sva.f
```

#### result

```
58
0
./sva/sockit_owm_sva.sv
```

### step 16: SubagentHandback

SVA checker for sockit_owm is written and `./check_syntax.sh` prints SYNTAX OK. Nothing in rtl/ or other existing files was modified.

Deliverables (workspace /tmp/brg8ve/sva_ws/sockit_owm_muudzr):
- sva/sockit_owm_sva.sv: checker module `sockit_owm_sva` with 58 labelled `assert property` statements, no cover or assume, and `bind sockit_owm sockit_owm_sva #(...) u_sockit_owm_sva (.*);`. Each assertion has a comment naming its DOC section or RTL construct.
- sockit_owm_sva.f: single line `./sva/sockit_owm_sva.sv`.

What is specified (default parameters: OVD_E=1, CDR_E=1, BDW=32, OWN=1, BTP "5.0"/"1.0"):
- Reset values of cdr_n (=CDR_N), cdr_o (=CDR_O), all control state, the line enable, div and cnt.
- Control/status read-back after a write (ien, irq cleared, pwr, cyc, ovd, rst, dat); cdr read-back at address 1; read mux for every readable field.
- Hold/stability for every register against its documented update events.
- Power output follows the pwr bit.
- Cycle start on write, zero-time idle (no cycle), and restart by a new write.
- Cycle length in base periods for every cycle type, using a pulse counter pc and a length latched at the write (DOC Table 12): 13, 192, 200 (normal), 8, 96 (overdrive); end-at-exact-pulse and cycle-clears-at-end.
- Line-enable waveform: write 0 / write 1 / reset release points, idle never driven, released after the end.
- Presence sample point, read-bit sample point, and the end latch of dat for read and presence slots.
- Clock divider: restart on bus write, idle at zero, counting while a cycle runs, no back-to-back pulses.
- Interrupt: set at cycle end, write beats end, read clears, end beats read, output = enable AND status.

Limitations and findings:
1. Undriven select (RTL line 148, warning VDB-1002): owr_sel is only set in an initial block for OWN=1, so owr_iln (owr_i[owr_sel]) and owr_e are unconstrained. I did not write any value assertion on them: owr_e has only the implication (|owr_e) |-> owr_oen, and the sampling checks a_samp_pres, a_samp_rd, a_dat_rd, a_dat_pres are relations (sample/latch copies an arbitrary-but-consistent input), not value checks. If you want a strict reading of the rule, drop those four assertions. The OWN>1 select and power-select paths are not specified.
2. Possible RTL/DOC discrepancy (not asserted as DOC behaviour): DOC Table 11 says cyc=0 on a control write is "no action", but RTL sets owr_oen <= ~&wdt[1:0] on every control write. A write such as 0x00 (cyc=0, rst=0, dat=0) therefore enables the line driver with no cycle running, and nothing clears it until a cycle ends. I asserted only the RTL behaviour (a_w0_line) and left the DOC claim out, because the RTL violates it.
3. Spurious end event with a zero ratio: with cdr_n=0 (normal) or cdr_o=0 (overdrive, the default), pls fires every clock while idle, cnt wraps, and irq_sts is set and owr_dat is latched from owr_smp with no cycle running. Assertions that depend on this use the raw end event (pls & cnt==0) or are gated on owr_cyc, so they are not violated.
4. Not asserted: reserved bits and tied constants; read data valid only on the first ren cycle; DOC's statement that a line under power cannot run cycles (the RTL does not implement this); the cyc-busy restriction on cdr writes (a usage rule, not a property).
5. Verification was by hand (only syntax checking was allowed). I walked each assertion against the RTL timing (cnt, pc, pulse indices for the release, presence and sample points, all checked for the default parameters) but did not run a formal proof.

#### result

```
{"success":true,"message":"Report delivered to your caller."}
```
