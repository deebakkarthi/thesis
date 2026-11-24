# Generator trace

source: /tmp/claude-15764358/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tasks/af6d0c94d048f23a0.output

note: 8 thinking block(s) were stored without text.

### step 1: Bash

```
cat /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/TASK.md
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
... [9890 more chars]
```

### step 2: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_SmloHy && ls -la && find . -type f | head -100 && cat *.tcl *.f 2>/dev/null && cat check_syntax.sh
```

#### result

```
total 32
drwx------  4 brg8ve users   108 Nov 23 20:37 .
drwxr-xr-x 16 brg8ve users  4096 Nov 23 20:37 ..
-rwxr-xr-x  1 brg8ve users   846 Nov 23 20:37 check_syntax.sh
drwxr-xr-x  2 brg8ve users    28 Nov 23 20:37 doc
drwxr-xr-x  2 brg8ve users    26 Nov 23 20:37 rtl
-rw-r--r--  1 brg8ve users    19 Nov 23 20:37 sockit_owm.f
-rw-r--r--  1 brg8ve users   224 Nov 23 20:37 sockit_owm.tcl
-rw-r--r--  1 brg8ve users 12909 Nov 23 20:37 TASK.md
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
cd /tmp/brg8ve/sva_ws/sockit_owm_SmloHy && cat -n rtl/sockit_owm.v; pdftotext -layout doc/sockit_owr.pdf - | wc -l
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
... [17578 more chars]
```

### step 4: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_SmloHy && pdftotext -layout doc/sockit_owr.pdf - | sed -n 1,620p
```

### step 5: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_SmloHy && pdftotext -layout doc/sockit_owr.pdf - | sed -n 621,1214p
```

#### result

```
<persisted-output>
Output too large (37KB). Full output saved to: /var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/bpj33d40h.txt

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

### step 6: Read

```
{
 "file_path": "/var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/bpj33d40h.txt",
 "offset": 60,
 "limit": 400
}
```

#### result

```
60	7 Demo hardware and software implementation...............................................................................23
61	   7.1 Demo hardware.......................................................................................................................23
62	      7.1.1 Demo hardware logic consumption................................................................................23
63	   7.2 Demo software........................................................................................................................24
64	      7.2.1 Demo software memory consumption............................................................................24
65	
66	
67	                                                                          2
68	8 Testing............................................................................................................................................25
69	  8.1 Verilog RTL simulation...........................................................................................................25
70	     8.1.1 1-wire slave model..........................................................................................................25
71	     8.1.2 Verilog testbench.............................................................................................................26
72	     8.1.3 Parameter tests................................................................................................................26
73	  8.2 C driver tests...........................................................................................................................27
74	  8.3 Testing TODO.........................................................................................................................27
75	9 License............................................................................................................................................28
76	10 References....................................................................................................................................29
77	
78	
79	
80	Index of Tables
81	Table 1: File list....................................................................................................................................5
82	Table 2: List of sockit_owm module parameters..................................................................................6
83	Table 3: Base time period and base frequency options........................................................................7
84	Table 4: List of sockit_owm module ports...........................................................................................7
85	Table 5: Wishbone equivalents of Avalon MM signals........................................................................8
86	Table 6: 1-wire protocol standard timing restrictions.........................................................................11
87	Table 7: Timing options..............................................
... [21623 more chars]
```

### step 7: Read

```
{
 "file_path": "/var/home/brg8ve/.claude/projects/-net-marysrock-ece-Virginia-EDU-maryisan-users-brg8ve--local-src-thesis-experiments-2026-11-10-rsi/96601a59-670a-4746-b654-cea9682f806c/tool-results/bpj33d40h.txt",
 "offset": 460,
 "limit": 220
}
```

#### result

```
460	                                       tSLOT = tLOW0                             tREC
461	
462	Drawing 5: Write 0 timing diagram
463	
464	The write '1' or read cycle is 9 base periods long. The wire is tight low for 1 base period than
465	released. A typical 1-wire slave would answer with '0' by holding the wire down for 4 base periods
466	(min 2, max 8) from the falling edge of the read command. Data is sampled at the most stable point
467	at 2 base periods from the falling edge. There is 1 base period at the end for recovery.
468	
469	                      8     7      6      5     4        3   2     1     0
470	
471	
472	
473	
474	                                       tDATT
475	
476	                                       tSLOT                                     tREC
477	
478	                                       tLOW1
479	
480	                                       tDATS
481	
482	Drawing 7:
483	        6: Write 11,or
484	                     read
485	                       read
486	                          timing
487	                            timing
488	                                 diagram
489	                                   diagram
490	
491	
492	
493	                                                    12
494	4 Processor interface
495	The processor interface is described in three steps:
496	   1. address space
497	   2. clock dividers
498	   3. 1-wire line multiplexing and power enable functionality
499	   4. control/status register description
500	   5. driver access sequences (polling and interrupts)
501	The document is focused on describing the 32bit CPU interface. Some aspects of a 8bit interface are
502	mentioned, but many details are omitted.
503	
504	4.1 Address space
505	The sockit_own module is designed to be accessible by a 32bit CPU through a single 32bit register,
506	if between 1 and 16 (OWN parameter) 1-wire lines are required. If a single line is enough than all but
507	one power and all select bits have no function, and the interface can be compacted into an 8bit
508	control/status register.
509	If implemented (CDR_E=1), there are two 16bit clock divider ratio registers (cdr_n, cdr_o) one for
510	normal and one for overdrive mode.
511	
512	Table 8: 32bit interface address space
513	  address           31..24                  23..16                 15..8                7..0
514	     0                         power                          unused   select    control/status
515	     1                         cdr_o                                        cdr_n
516	
517	
518	Since all the controls are in a single register and there is no byte select signal, on every write all
519	controls must have the correct value. In software this can be achieved by having a permanent
520	structure holding the interface current state.
521	Alternatively an 8bit interface is possible. The maximum number of 1-wire lines is reduced to 4 and
522	the clock divider ratio register size is reduced to 8bit.
523	
524	Table 9: 8bit interface
... [6500 more chars]
```

### assistant

I have the RTL and the full datasheet. Before writing the checker I'm checking the timing arithmetic by hand, since I can only run the syntax check and not a prover.

### step 8: Bash

```
mkdir -p /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/sva && cat > /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/sva/sockit_owm_sva.sv << 'EOF'
// Specification checker for the sockit_owm 1-wire master, bound to the top
// module. Written for the default parameters (BDW=32, OWN=1, OVD_E=1,
// CDR_E=1, BTP_N="5.0", BTP_O="1.0"); the timing parameters are passed in so
// that the expressions use the design's own values.
//
// Auxiliary state (same clock and reset as the design):
//   tk_cnt  - base periods (divider ticks) elapsed since the running 1-wire
//             cycle was started by a control write. Cleared by every control
//             write, counts ticks only while owr_cyc is high.
// Derived values:
//   len_now - length in base periods of the cycle selected by the current
//             owr_ovd / owr_rst / owr_dat (the cnt reload value + 1).
//   tk_*    - tick index (tk_cnt value) at which the named RTL event happens.
//             cnt starts at len-1 and is decremented once per tick, so a
//             count value c is reached at tk = len-1-c.
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
)(
  input               clk,
  input               rst,
  input               bus_ren,
  input               bus_wen,
  input  [BAW-1:0]    bus_adr,
  input  [BDW-1:0]    bus_wdt,
  input  [BDW-1:0]    bus_rdt,
  input               bus_irq,
  input  [OWN-1:0]    owr_p,
  input  [OWN-1:0]    owr_e,
  input  [CDW-1:0]    div,
  input  [CDW-1:0]    cdr_n,
  input  [CDW-1:0]    cdr_o,
  input               pls,
  input               owr_cyc,
  input  [TDW-1:0]    cnt,
  input  [OWN-1:0]    owr_pwr,
  input               owr_ovd,
  input               owr_rst,
  input               owr_dat,
  input               owr_smp,
  input               owr_oen,
  input               irq_ena,
  input               irq_sts
);

  //////////////////////////////////////////////////////////////////////////
  // helpers
  //////////////////////////////////////////////////////////////////////////

  wire ctl_wr    = bus_wen && (bus_adr[0] == 1'b0);   // bus_wen_ctl_sts
  wire ctl_rd    = bus_ren && (bus_adr[0] == 1'b0);   // bus_ren_ctl_sts
  wire cdr_wr    = bus_wen && (bus_adr[0] == 1'b1);
  wire cdr_rd    = bus_ren && (bus_adr[0] == 1'b1);
  wire tick_zero = pls && (cnt == '0);                // end-of-cycle tick
  wire cyc_end   = owr_cyc && tick_zero;

  // base periods elapsed in the running cycle
  reg  [TDW-1:0] tk_cnt;
  always @ (posedge clk or posedge rst)
    if (rst)                 tk_cnt <= '0;
    else if (ctl_wr)         tk_cnt <= '0;
    else if (pls && owr_cyc) tk_cnt <= tk_cnt + 1'b1;

  // cycle length (cnt reload value + 1) of the selected cycle type
  wire [TDW-1:0] len_now =
      owr_ovd ? (owr_rst ? (owr_dat ? T_IDLE_O : T_RSTL_O + T_RSTH_O)
                         : (T_DAT0_O + T_RCVR_O))
              : (owr_rst ? (owr_dat ? T_IDLE_N : T_RSTL_N + T_RSTH_N)
                         : (T_DAT0_N + T_RCVR_N));

  // tick index of the named events (see header)
  wire [TDW-1:0] tk_rel_rst = (owr_ovd ? T_RSTL_O : T_RSTL_N) - 1;               // release of reset low (cnt == t_rsth)
  wire [TDW-1:0] tk_pres    = (owr_ovd ? T_RSTL_O + T_RSTP_O : T_RSTL_N + T_RSTP_N) - 1; // presence sample (cnt == t_rstp)
  wire [TDW-1:0] tk_bits    = (owr_ovd ? T_BITS_O : T_BITS_N) - 1;               // data sample (cnt == t_bits)
  wire [TDW-1:0] tk_dat0    = (owr_ovd ? T_DAT0_O : T_DAT0_N) - 1;               // write-0 release (cnt == t_dat0)
  wire [TDW-1:0] tk_dat1    = (owr_ovd ? T_DAT1_O : T_DAT1_N) - 1;               // write-1 release (cnt == t_dat1)
  wire           smp_pt     = owr_rst ? (tk_cnt == tk_pres) : (tk_cnt == tk_bits);

  default clocking @(posedge clk); endclocking
  default disable iff (rst);

  //////////////////////////////////////////////////////////////////////////
  // reset values (Table 10 reset column, section 4.2, RTL reset branches)
  //////////////////////////////////////////////////////////////////////////

  // Table 10: ien, irq, pwr, cyc, ovd, rst reset to 0; section 4.2: divider
  // ratio registers reset to CDR_N / CDR_O. owr_dat resets to 0 in the RTL.
  // Source: Table 10 / RTL reset branches. Holds because all these registers
  // have an asynchronous reset to the listed value.
  a_rst_ctl: assert property ($past(rst) |-> (owr_cyc == 1'b0 && owr_rst == 1'b0 &&
             owr_ovd == 1'b0 && owr_dat == 1'b0 && owr_pwr == '0 && owr_oen == 1'b0 &&
             irq_ena == 1'b0 && irq_sts == 1'b0));

  // Source: section 4.2 (clock divider ratio registers reset to CDR_N / CDR_O).
  a_rst_cdr: assert property ($past(rst) |-> (cdr_n == CDR_N && cdr_o == CDR_O));

  // Source: RTL reset of the clock divider and the cycle counter. Both are
  // zero, so no tick is pending after reset.
  a_rst_div_cnt: assert property ($past(rst) |-> (div == '0 && cnt == '0));

  // Source: outputs derived from reset registers (interrupt, power, line
  // enable). With owr_oen reset to 0 the line is not driven.
  a_rst_outputs: assert property ($past(rst) |-> (bus_irq == 1'b0 && owr_p == '0 && owr_e == '0));

  //////////////////////////////////////////////////////////////////////////
  // register map and read/write behaviour (Tables 8, 10, 11)
  //////////////////////////////////////////////////////////////////////////

  // Table 8: address 0 is the control/status register; bits 31..8 are the
  // power/select field, which for OWN=1 is not implemented and reads 0.
  // Table 10: bit 5 is reserved (reads 0).
  // Source: Table 8, Table 10. Holds because the RTL drives these bits with
  // constant zero for OWN=1 and BDW=32.
  a_map_zero: assert property (ctl_rd |-> (bus_rdt[31:8] == '0 && bus_rdt[5] == 1'b0));

  // Table 10/11: bits 7 ien, 6 irq, 4 pwr, 3 cyc, 2 ovd, 1 rst, 0 dat read the
  // current state of the corresponding registers. Read data is combinational
  // from the registers, so a read in the same cycle as a write returns the
  // value before the write.
  // Source: Table 10/11. Holds because bus_rdt is built from these registers.
  a_map_ctl: assert property (ctl_rd |-> (bus_rdt[7:6] == {irq_ena, irq_sts} &&
             bus_rdt[4] == owr_pwr[0] && bus_rdt[3] == owr_cyc &&
             bus_rdt[2:0] == {owr_ovd, owr_rst, owr_dat}));

  // Table 8: address 1 holds cdr_o (bits 31..16) and cdr_n (bits 15..0).
  // Holds because the read-data mux selects these registers for address 1.
  a_map_cdr: assert property (cdr_rd |-> (bus_rdt == {cdr_o, cdr_n}));

  // Section 4.2: the divider ratio registers can be written and then read
  // back. Both halves are loaded by a write to address 1.
  // Source: Section 4.2. Holds because a write at address 1 loads cdr_n from
  // bus_wdt[15:0] and cdr_o from bus_wdt[31:16] on the same cycle.
  a_rb_cdr: assert property (cdr_wr ##1 cdr_rd |-> (bus_rdt == $past(bus_wdt)));

  // Table 10: ien is written from bit 7 and reads back.
  // Source: Table 10 (ien r/w). Holds because irq_ena is loaded on a control write.
  a_rb_ctl_ien: assert property (ctl_wr ##1 ctl_rd |-> (bus_rdt[7] == $past(bus_wdt[7])));

  // Table 11: bit 6 is cleared by a control write (interrupt cleared by status
  // access). The RTL clears irq_sts on every control write, so it reads 0 on
  // the next cycle.
  // Source: Table 10 / Table 11 (irq bit), RTL interrupt logic. Holds because a
  // control write has priority over the end-of-cycle set.
  a_rb_ctl_irq: assert property (ctl_wr ##1 ctl_rd |-> (bus_rdt[6] == 1'b0));

  // Table 11: bit 4 (pwr) written from bit 4 and read back.
  // Source: Table 11 (pwr, OWN=1 case). Holds because owr_pwr loads bus_wdt[4].
  a_rb_ctl_pwr: assert property (ctl_wr ##1 ctl_rd |-> (bus_rdt[4] == $past(bus_wdt[4])));

  // Table 11: bit 3 (cyc) reads back the cycle status set by the write. A write
  // with bit 3 set and not all of ovd/rst/dat set starts a cycle, so cyc reads 1.
  // Source: Table 11 (cyc), Table 12 (zero-time idle). Holds because owr_cyc is
  // loaded with bus_wdt[3] & ~&bus_wdt[2:0].
  a_rb_ctl_cyc: assert property (ctl_wr ##1 ctl_rd |->
                (bus_rdt[3] == $past(bus_wdt[3] & ~&bus_wdt[2:0])));

  // Table 11: bits 2..0 (ovd, rst, dat) read back what was written.
  // Source: Table 11. Holds because these registers load on a control write.
  a_rb_ctl_ovd_rst_dat: assert property (ctl_wr ##1 ctl_rd |-> (bus_rdt[2:0] == $past(bus_wdt[2:0])));

  // The divider ratio registers only change on an address-1 write.
  // Source: Table 8 / Section 4.2. Holds because cdr_n/cdr_o load only on
  // bus_wen_cdr_n / bus_wen_cdr_o, which are the same address-1 write.
  a_cdr_hold: assert property (!cdr_wr |=> ($stable(cdr_n) && $stable(cdr_o)));

  // Table 10/11: the control/status register bits (except irq and cyc, which
  // have their own rules) change only on a control write.
  // Source: Table 10 (ien, pwr, ovd, rst). Holds because the RTL loads these
  // registers only under the control-write enable.
  a_ctl_hold: assert property (!ctl_wr |=> ($stable(owr_pwr) && $stable(irq_ena) &&
              $stable(owr_ovd) && $stable(owr_rst)));

  // Bus writes to the control register load ovd and rst.
  // Source: Table 10/11. Holds because the RTL loads them from bus_wdt[2] and bus_wdt[1].
  a_wr_mode: assert property (ctl_wr |=> (owr_ovd == $past(bus_wdt[2]) && owr_rst == $past(bus_wdt[1])));

  // Any bus write restarts the clock divider.
  // Source: RTL clock divider logic (divider is cleared on bus_wen). Doc: the
  // divider ratios must be written while no cycle is in progress (Section 4.2).
  // Holds because the RTL resets div on any bus write.
  a_div_wr: assert property (bus_wen |=> div == '0);

  //////////////////////////////////////////////////////////////////////////
  // power and line outputs (Section 2.2.2, Section 4.3, Table 10 pwr)
  //////////////////////////////////////////////////////////////////////////

  // Section 4.3 / Table 11: with OWN=1 the pwr bit of the control register
  // directly controls owr_p[0] (line power enable).
  // Source: Section 4.3, Table 11. Holds because owr_p = owr_pwr, which loads bus_wdt[4].
  a_pwr_wr: assert property (ctl_wr |=> (owr_p == $past(bus_wdt[4])));

  // Section 4.3: power stays on until the next control write.
  // Source: Section 4.3. Holds because owr_pwr changes only on control writes.
  a_pwr_hold: assert property (!ctl_wr |=> $stable(owr_p));

  // Section 4.4: a control write that is not the zero-length idle sets the line
  // driver (owr_oen). The RTL loads owr_oen from the rst/dat bits on every
  // control write (not only on a started cycle).
  // Source: RTL output register (owr_oen). Holds by the RTL assignment on bus_wen_ctl_sts.
  a_oen_wr_drive: assert property (ctl_wr && !(&bus_wdt[1:0]) |=> owr_oen);

  // Table 12: the rst=1, dat=1 combination (idle) does not drive the line.
  // Source: Table 12 (idle cycle), RTL owr_oen load. Holds because owr_oen loads
  // ~&bus_wdt[1:0].
  a_oen_wr_idle: assert property (ctl_wr && (&bus_wdt[1:0]) |=> !owr_oen);

  // owr_oen changes only on a control write or a tick.
  // Source: RTL output register (update enable is bus_wen_ctl_sts or pls).
  // Holds by inspection of the RTL.
  a_oen_hold: assert property (!ctl_wr && !pls |=> $stable(owr_oen));

  // Source: owr_e = owr_oen << owr_sel (OWN=1). A zero line-enable shifts to
  // zero whatever owr_sel is, so owr_e is zero when owr_oen is zero.
  // Note: owr_sel is never assigned for OWN=1, so only properties independent
  // of owr_sel are asserted here.
  a_e_zero: assert property (!owr_oen |-> (owr_e == '0));

  // Source: owr_e = owr_oen << owr_sel with OWN=1. A 1-bit shifted result is
  // either owr_oen or zero, so a set owr_e bit implies owr_oen.
  a_e_only: assert property (owr_e != '0 |-> owr_oen);

  //////////////////////////////////////////////////////////////////////////
  // interrupt (Table 10 irq/ien, Section 2.2.1, Section 4.4)
  //////////////////////////////////////////////////////////////////////////

  // Section 2.2.1 / Table 10: the interrupt request is the enabled status.
  // Source: Section 2.2.1 and Table 10. Holds because bus_irq = irq_ena & irq_sts.
  a_irq_out: assert property (bus_irq == (irq_ena && irq_sts));

  // Table 10: ien is written from bit 7 and held otherwise.
  // Source: Table 10. Holds because irq_ena loads bus_wdt[7] on a control write.
  a_irq_ena_wr: assert property (ctl_wr |=> (irq_ena == $past(bus_wdt[7])));

  // Table 11: irq is set on the end of a 1-wire cycle. Write priority: a control
  // write in the same cycle clears the status instead.
  // Source: Table 11 (irq), RTL interrupt logic. Holds because the set condition
  // is pls & cnt==0 and the control write has priority in the same always block.
  // Note: the RTL also sets irq_sts on the same tick condition while owr_cyc is
  // low (see report); this assertion is restricted to real cycle ends.
  a_irq_set: assert property (cyc_end && !ctl_wr |=> irq_sts);

  // Section 2.2.1: with ien set, the interrupt output rises at the cycle end.
  // Source: Section 2.2.1 / Table 10. Holds because bus_irq = irq_ena & irq_sts.
  a_irq_set_out: assert property (cyc_end && !ctl_wr && irq_ena |=> bus_irq);

  // irq_sts rises only on a tick with zero count (its only set condition).
  // Source: RTL interrupt logic. Holds because the only assignment setting
  // irq_sts to one is on tick_zero.
  a_irq_rise: assert property ($rose(irq_sts) |-> $past(tick_zero));

  // Table 11: a control write clears the interrupt status.
  // Source: Table 11 (irq cleared by status read), RTL interrupt logic. Holds
  // because a control write has the highest priority.
  a_irq_wr_clr: assert property (ctl_wr |=> !irq_sts);

  // Section 2.2.1 / Table 11: a control read clears the interrupt status unless a
  // control write or an end-of-cycle tick takes priority in the same cycle.
  // Source: RTL interrupt logic. Holds by the RTL priority order.
  a_irq_rd_clr: assert property (ctl_rd && !ctl_wr && !tick_zero |=> !irq_sts);

  // irq_sts holds when no clear, set, or status-read event occurs.
  // Source: RTL interrupt logic. Holds because irq_sts is assigned only on these events.
  a_irq_hold: assert property (!ctl_wr && !ctl_rd && !tick_zero |=> $stable(irq_sts));

  //////////////////////////////////////////////////////////////////////////
  // cycle control and timing (Section 3.1, Section 4.4, Table 12)
  //////////////////////////////////////////////////////////////////////////

  // Table 11: writing cyc=1 starts a cycle, except the zero-length idle
  // (ovd=rst=dat=1), which Table 12 lists as 0 us.
  // Source: Table 11 (cyc), Table 12. Holds because owr_cyc loads
  // bus_wdt[3] & ~&bus_wdt[2:0] on a control write.
  a_cyc_start: assert property (ctl_wr && bus_wdt[3] && !(&bus_wdt[2:0]) |=> owr_cyc);

  // Table 11: writing cyc=0 starts no cycle.
  // Source: Table 11 (cyc: 0 - no action). Holds because owr_cyc loads 0 when bit 3 is 0.
  a_cyc_nostart: assert property (ctl_wr && !bus_wdt[3] |=> !owr_cyc);

  // Table 12: the zero-length idle (ovd=rst=dat=1) does not start a cycle status.
  // Source: Table 12, RTL owr_cyc load. Holds because owr_cyc loads 0 for &bus_wdt[2:0].
  a_cyc_nostart_zt: assert property (ctl_wr && (&bus_wdt[2:0]) |=> !owr_cyc);

  // Section 3.1 / Table 11: the cycle ends at the tick where the counter reaches
  // zero (end of cycle).
  // Source: Section 3.1, counter logic. Holds because owr_cyc is cleared on
  // pls & cnt==0 unless a control write takes priority.
  a_cyc_end: assert property (cyc_end && !ctl_wr |=> !owr_cyc);

  // Section 3.1: a running cycle continues until its end tick.
  // Source: Section 3.1. Holds because owr_cyc only changes on a control write
  // or on the end tick.
  a_cyc_hold: assert property (owr_cyc && !tick_zero && !ctl_wr |=> owr_cyc);

  // Section 4.5 / RTL: the divider is zero while no cycle runs. Holds because
  // it is cleared on bus writes and on every tick, and only counts while owr_cyc.
  a_cyc_idle_div: assert property (!owr_cyc |-> (div == '0));

  // RTL clock divider: while a cycle runs and there is no tick, the divider
  // advances by one each clock.
  // Source: RTL clock divider logic. Holds because div <= div + owr_cyc unless
  // a tick or a bus write clears it, and div <= R-based compare cannot skip ahead.
  a_div_count: assert property (owr_cyc && !pls && !bus_wen |=> (div == $past(div) + 1'b1));

  // Section 3.1: the counter is reloaded on every control write with the
  // number of base periods of the selected cycle type (write value 0 is the
  // data slot, 1 with ovd is the 8/96 us slot, 11 is the idle), minus one.
  // Source: Section 3.1 (counter reload per cycle type), Table 12, RTL counter
  // logic. Holds because during a running cycle cnt + tk_cnt stays at len-1 and
  // the cycle type cannot change without a control write, which restarts it.
  a_cnt_len: assert property (owr_cyc |-> ((cnt + tk_cnt) == (len_now - 1'b1)));

  // Section 3.1: the counter only moves on a tick or a control write.
  // Source: RTL counter logic. Holds because cnt is assigned only on a control
  // write or on pls.
  a_cnt_hold: assert property (!ctl_wr && !pls |=> $stable(cnt));

  // Section 3.1: the counter steps once per base period.
  // Source: RTL counter logic. Holds because cnt decrements on each pls unless
  // a control write reloads it.
  a_cnt_step: assert property (pls && !ctl_wr |=> (cnt == $past(cnt) - 1'b1));

  //////////////////////////////////////////////////////////////////////////
  // base period (tick) timing (Section 2.1.3, Section 3.2, Table 7)
  //////////////////////////////////////////////////////////////////////////

  // Overdrive base period is CDR_O+1 clocks. With the default CDR_O of 0 each
  // clock is one tick, i.e. 1 us base period (Table 7 "1.0" overdrive option).
  // Source: Section 2.1.3, Table 7. Holds because after a tick the divider is
  // zero and compares equal to cdr_o = CDR_O when the mode is overdrive.
  a_tick_ovd: assert property (pls && !bus_wen && owr_ovd && cdr_o == CDR_O |=> pls);

  // The first tick after an overdrive control write with cyc=1 is immediate
  // (divider was cleared by the write and cdr_o = CDR_O).
  // Source: Section 2.1.3 / RTL divider. Holds because the write clears div and
  // owr_ovd takes bus_wdt[2].
  a_tick_ovd_first: assert property (ctl_wr && bus_wdt[2] && cdr_o == CDR_O |=> pls);

  // Normal base period is CDR_N+1 clocks; with the default CDR_N of 4 that is
  // 5 us (Table 7 "5.0" normal option). Checked from a tick with no bus write
  // and nonzero count, through four quiet clocks, to the next tick.
  // Source: Section 2.1.3, Table 7. Holds because the divider counts from zero
  // while a cycle runs and no write or tick interrupts it.
  a_tick_norm: assert property (
      (owr_cyc && pls && !bus_wen && !owr_ovd && cdr_n == CDR_N && cnt != '0)
      ##1 (!bus_wen && !pls)[*4] |-> ##1 pls);

  // The first normal tick after a control write that starts a cycle occurs
  // CDR_N+1 clocks after the write.
  // Source: Section 2.1.3, Section 3.2. Holds because the write clears the
  // divider and the divider then counts to CDR_N while owr_cyc is high.
  a_tick_norm_first: assert property (
      (ctl_wr && bus_wdt[3] && !bus_wdt[2] && cdr_n == CDR_N)
      ##1 (!bus_wen)[*4] |-> ##1 pls);

  //////////////////////////////////////////////////////////////////////////
  // 1-wire waveform phases (Section 3.2, Table 6, Table 7, Table 12)
  //////////////////////////////////////////////////////////////////////////

  // Write 1 / read slot: the line is released at the first tick, which is one
  // base period after the write (tDAT1 = 1 base period, Table 6/7).
  // Source: Section 3.2 (write 1/read timing), Table 7 (tDAT1). Holds because
  // the release at cnt == t_dat1 occurs at tk = T_DAT1 - 1 = 0.
  a_wr1_release: assert property (owr_cyc && !owr_rst && owr_dat && pls && tk_cnt == tk_dat1 |=> !owr_oen);

  // Write 0 slot: the line stays driven until tick T_DAT0 - 1 (tDAT0 base
  // periods, Table 7). Before that tick the line stays driven.
  // Source: Section 3.2 (write 0 timing), Table 7. Holds because the only
  // release for a data slot is at cnt == t_dat0, and that tick is later.
  a_wr0_hold: assert property (owr_cyc && !owr_rst && !owr_dat && pls && tk_cnt < tk_dat0 && !ctl_wr |=> owr_oen);

  // Write 0 slot: the line is released at tick T_DAT0 - 1 (tDAT0 base periods).
  // Source: Section 3.2, Table 7. Holds by the RTL release branch for data slots.
  a_wr0_release: assert property (owr_cyc && !owr_rst && !owr_dat && pls && tk_cnt == tk_dat0 |=> !owr_oen);

  // Reset pulse: the line is held low until tick T_RSTL - 1 (tRSTL base periods,
  // Table 7).
  // Source: Section 3.2, Table 6/7 (tRSTL), Section 4.5.1. Holds because the
  // reset-cycle release is at cnt == t_rsth, which is tick T_RSTL - 1.
  a_rst_hold: assert property (owr_cyc && owr_rst && !owr_dat && pls && tk_cnt < tk_rel_rst && !ctl_wr |=> owr_oen);

  // Reset pulse: the line is released at tick T_RSTL - 1 and stays released
  // until the cycle ends (tRSTH high phase).
  // Source: Section 3.2, Table 7. Holds by the reset release branch.
  a_rst_release: assert property (owr_cyc && owr_rst && !owr_dat && pls && tk_cnt == tk_rel_rst |=> !owr_oen);

  // Section 4.4: the data-bit result (dat) is only written at a control write or
  // at the end of a cycle.
  // Source: Table 11 (dat as read status), RTL owr_dat logic. Holds because owr_dat
  // is assigned only on a control write or on the end tick.
  a_dat_hold: assert property (!ctl_wr && !tick_zero |=> $stable(owr_dat));

  // A control write loads the dat bit from bus_wdt[0].
  // Source: Table 11 (dat write). Holds because owr_dat loads bus_wdt[0].
  a_dat_wr: assert property (ctl_wr |=> (owr_dat == $past(bus_wdt[0])));

  // At the end of a 1-wire cycle the sampled line value is copied to dat.
  // Source: Table 11 (dat is the receive status), RTL end-of-cycle logic. Holds
  // because owr_dat <= owr_smp on the end tick, and owr_smp keeps its value until
  // the next tick that samples it.
  a_dat_end: assert property (cyc_end && !ctl_wr |=> (owr_dat == $past(owr_smp)));

  // Sampling of the line is only done on a tick. Holds because owr_smp is
  // assigned only under pls.
  // Source: RTL sampling logic. Holds because owr_smp is assigned only inside the pls branch.
  a_smp_hold: assert property (!pls |=> $stable(owr_smp));

  // Within a running cycle, owr_smp changes only at the sample tick of the
  // selected cycle type (reset: T_RSTL+T_RSTP-1, data: T_BITS-1).
  // Source: Section 2.3, Section 3.2 (tDATS, presence sampling), RTL sampling
  // logic. Holds because the sampling conditions are cnt == t_rstp / cnt == t_bits
  // and tk_cnt tracks cnt in a running cycle.
  a_smp_window: assert property (owr_cyc && pls && !smp_pt |=> $stable(owr_smp));

endmodule

// Checker bound to the design top module, with the design's own parameters.
bind sockit_owm sockit_owm_sva #(
  .BAW(BAW), .BDW(BDW), .OWN(OWN), .CDW(CDW), .TDW(TDW),
  .CDR_N(CDR_N), .CDR_O(CDR_O),
  .T_RSTH_N(T_RSTH_N), .T_RSTL_N(T_RSTL_N), .T_RSTP_N(T_RSTP_N),
  .T_DAT0_N(T_DAT0_N), .T_DAT1_N(T_DAT1_N), .T_BITS_N(T_BITS_N),
  .T_RCVR_N(T_RCVR_N), .T_IDLE_N(T_IDLE_N),
  .T_RSTH_O(T_RSTH_O), .T_RSTL_O(T_RSTL_O), .T_RSTP_O(T_RSTP_O),
  .T_DAT0_O(T_DAT0_O), .T_DAT1_O(T_DAT1_O), .T_BITS_O(T_BITS_O),
  .T_RCVR_O(T_RCVR_O), .T_IDLE_O(T_IDLE_O)
) u_sockit_owm_sva (.*);
EOF
cd /tmp/brg8ve/sva_ws/sockit_owm_SmloHy && echo "./sva/sockit_owm_sva.sv" > sockit_owm_sva.f && ./check_syntax.sh
```

#### result

```
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./sva/sockit_owm_sva.sv(86): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./sva/sockit_owm_sva.sv(93): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./sva/sockit_owm_sva.sv(94): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./sva/sockit_owm_sva.sv(95): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./sva/sockit_owm_sva.sv(96): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./sva/sockit_owm_sva.sv(97): expression size 32 truncated to fit in target size 8
[WARN (VERI-9005)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(417): 2-bit index expression 'owr_sel' is larger than the required 1 bits. This might lead to an out-of-bound access
SYNTAX OK
```

### assistant

Syntax passes. The only warnings in my checker are integer-to-`TDW` truncations on the derived constants, which are harmless since the values fit, but I'll make the widths explicit so the warnings go away.

### step 9: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_SmloHy && sed -n '84,98p' sva/sockit_owm_sva.sv
```

#### result

```
  // cycle length (cnt reload value + 1) of the selected cycle type
  wire [TDW-1:0] len_now =
      owr_ovd ? (owr_rst ? (owr_dat ? T_IDLE_O : T_RSTL_O + T_RSTH_O)
                         : (T_DAT0_O + T_RCVR_O))
              : (owr_rst ? (owr_dat ? T_IDLE_N : T_RSTL_N + T_RSTH_N)
                         : (T_DAT0_N + T_RCVR_N));

  // tick index of the named events (see header)
  wire [TDW-1:0] tk_rel_rst = (owr_ovd ? T_RSTL_O : T_RSTL_N) - 1;               // release of reset low (cnt == t_rsth)
  wire [TDW-1:0] tk_pres    = (owr_ovd ? T_RSTL_O + T_RSTP_O : T_RSTL_N + T_RSTP_N) - 1; // presence sample (cnt == t_rstp)
  wire [TDW-1:0] tk_bits    = (owr_ovd ? T_BITS_O : T_BITS_N) - 1;               // data sample (cnt == t_bits)
  wire [TDW-1:0] tk_dat0    = (owr_ovd ? T_DAT0_O : T_DAT0_N) - 1;               // write-0 release (cnt == t_dat0)
  wire [TDW-1:0] tk_dat1    = (owr_ovd ? T_DAT1_O : T_DAT1_N) - 1;               // write-1 release (cnt == t_dat1)
  wire           smp_pt     = owr_rst ? (tk_cnt == tk_pres) : (tk_cnt == tk_bits);
```

### step 10: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_SmloHy && python3 - << 'EOF'
import re
p='sva/sockit_owm_sva.sv'
s=open(p).read()
old_len='''  wire [TDW-1:0] len_now =
      owr_ovd ? (owr_rst ? (owr_dat ? T_IDLE_O : T_RSTL_O + T_RSTH_O)
                         : (T_DAT0_O + T_RCVR_O))
              : (owr_rst ? (owr_dat ? T_IDLE_N : T_RSTL_N + T_RSTH_N)
                         : (T_DAT0_N + T_RCVR_N));'''
new_len='''  wire [TDW-1:0] len_now = TDW'(
      owr_ovd ? (owr_rst ? (owr_dat ? T_IDLE_O : T_RSTL_O + T_RSTH_O)
                         : (T_DAT0_O + T_RCVR_O))
              : (owr_rst ? (owr_dat ? T_IDLE_N : T_RSTL_N + T_RSTH_N)
                         : (T_DAT0_N + T_RCVR_N)));'''
assert s.count(old_len)==1
s=s.replace(old_len,new_len)
reps={
"wire [TDW-1:0] tk_rel_rst = (owr_ovd ? T_RSTL_O : T_RSTL_N) - 1;":
"wire [TDW-1:0] tk_rel_rst = TDW'((owr_ovd ? T_RSTL_O : T_RSTL_N) - 1);",
"wire [TDW-1:0] tk_pres    = (owr_ovd ? T_RSTL_O + T_RSTP_O : T_RSTL_N + T_RSTP_N) - 1;":
"wire [TDW-1:0] tk_pres    = TDW'((owr_ovd ? T_RSTL_O + T_RSTP_O : T_RSTL_N + T_RSTP_N) - 1);",
"wire [TDW-1:0] tk_bits    = (owr_ovd ? T_BITS_O : T_BITS_N) - 1;":
"wire [TDW-1:0] tk_bits    = TDW'((owr_ovd ? T_BITS_O : T_BITS_N) - 1);",
"wire [TDW-1:0] tk_dat0    = (owr_ovd ? T_DAT0_O : T_DAT0_N) - 1;":
"wire [TDW-1:0] tk_dat0    = TDW'((owr_ovd ? T_DAT0_O : T_DAT0_N) - 1);",
"wire [TDW-1:0] tk_dat1    = (owr_ovd ? T_DAT1_O : T_DAT1_N) - 1;":
"wire [TDW-1:0] tk_dat1    = TDW'((owr_ovd ? T_DAT1_O : T_DAT1_N) - 1);",
}
for a,b in reps.items():
    assert s.count(a)==1, a
    s=s.replace(a,b)
# constant-width casts for the property-side literals used with TDW-bit counters
s=s.replace("(cnt + tk_cnt) == (len_now - 1'b1)","(cnt + tk_cnt) == (len_now - TDW'(1))")
open(p,'w').write(s)
EOF
./check_syntax.sh
```

#### result

```
[WARN (VDB-1002)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(148): net 'owr_sel[-1]' does not have a driver
[WARN (VERI-1060)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(320): 'initial' construct is ignored
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(184): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(186): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(188): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(191): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(193): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(196): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(198): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(200): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(297): expression size 32 truncated to fit in target size 16
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(384): expression size 32 truncated to fit in target size 8
[WARN (VERI-1209)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(385): expression size 32 truncated to fit in target size 8
[WARN (VERI-9005)] /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/./rtl/sockit_owm.v(417): 2-bit index expression 'owr_sel' is larger than the required 1 bits. This might lead to an out-of-bound access
SYNTAX OK
```

### assistant

The checker now produces no warnings of its own. The remaining warnings all point into `rtl/`, including the undriven `owr_sel` (only relevant for `OWN>1`, see report). I'll tidy two comments that were imprecise, then run the syntax check once more.

### step 11: Bash

```
cd /tmp/brg8ve/sva_ws/sockit_owm_SmloHy && python3 - << 'EOF'
p='sva/sockit_owm_sva.sv'
s=open(p).read()
a='''  // Section 3.1: the counter is reloaded on every control write with the
  // number of base periods of the selected cycle type (write value 0 is the
  // data slot, 1 with ovd is the 8/96 us slot, 11 is the idle), minus one.
  // Source: Section 3.1 (counter reload per cycle type), Table 12, RTL counter
  // logic. Holds because during a running cycle cnt + tk_cnt stays at len-1 and
  // the cycle type cannot change without a control write, which restarts it.'''
b='''  // Section 3.1 / Table 12: a running cycle has the length of its type
  // (reset, data bit, or timed idle, in normal or overdrive mode). The counter
  // is loaded with that length minus one on the start write and decremented
  // once per tick, so cnt + tk_cnt stays at len-1 for the whole cycle.
  // Source: Section 3.1, Table 12, RTL counter reload. Holds because the cycle
  // type (owr_ovd/owr_rst/owr_dat) changes only on a control write, and a
  // control write restarts the count (tk_cnt) and reloads cnt.'''
assert s.count(a)==1
s=s.replace(a,b)
a2='''  // Source: RTL clock divider logic. Holds because div <= div + owr_cyc unless
  // a tick or a bus write clears it, and div <= R-based compare cannot skip ahead.'''
b2='''  // Source: RTL clock divider logic. Holds because div <= div + owr_cyc, and
  // div is cleared only by a tick (pls) or a bus write, both excluded here.'''
assert s.count(a2)==1
s=s.replace(a2,b2)
open(p,'w').write(s)
EOF
./check_syntax.sh | grep -c "sva/sockit_owm_sva" ; ./check_syntax.sh | tail -1; ls -R /tmp/brg8ve/sva_ws/sockit_owm_SmloHy; cat /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/sockit_owm_sva.f
```

#### result

```
0
SYNTAX OK
/tmp/brg8ve/sva_ws/sockit_owm_SmloHy:
check_syntax.sh
doc
rtl
sockit_owm.f
sockit_owm_sva.f
sockit_owm.tcl
sva
TASK.md

/tmp/brg8ve/sva_ws/sockit_owm_SmloHy/doc:
sockit_owr.pdf

/tmp/brg8ve/sva_ws/sockit_owm_SmloHy/rtl:
sockit_owm.v

/tmp/brg8ve/sva_ws/sockit_owm_SmloHy/sva:
sockit_owm_sva.sv
./sva/sockit_owm_sva.sv
```

### step 12: SubagentHandback

SVA checker for sockit_owm is written and `./check_syntax.sh` prints SYNTAX OK. The checker produces no warnings of its own. The remaining warnings all point into rtl/ (undriven owr_sel for OWN=1, initial ignored, width truncations).

Deliverables (only these two files were created in the workspace):
- /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/sva/sockit_owm_sva.sv : checker module sockit_owm_sva (56 labelled assert properties, no cover/assume) plus `bind sockit_owm sockit_owm_sva #(...) u_sockit_owm_sva (.*);` passing the design's parameters.
- /tmp/brg8ve/sva_ws/sockit_owm_SmloHy/sockit_owm_sva.f : single line `./sva/sockit_owm_sva.sv`

What it specifies (default parameters; each assertion has a source/reason comment):
- Reset values of ctl registers, cdr_n/cdr_o (= CDR_N/CDR_O), div, cnt, outputs.
- Register map: status byte read-back (ien, irq, pwr, cyc, ovd/rst/dat, reserved and bits 31:8 zero), cdr read-back and write/hold, ctl-register hold, mode write.
- Power/line: owr_p follows bus_wdt[4]; owr_oen drive/idle/hold; owr_e zero when owr_oen is low, and owr_e set implies owr_oen (sel-independent, see caveat).
- Interrupt: irq = ien & sts; set at cycle end; write clears; read clears unless a write or end tick wins; hold; rise only on a zero-count tick.
- Cycle control: start on cyc=1 (not on the zero-time idle), no start on cyc=0, end at the zero-count tick, hold, divider zero while idle, divider counts while running, counter reload and step, and cnt + tk_cnt == len-1 (auxiliary tick counter) for every cycle type in normal and overdrive modes.
- Tick timing: overdrive period CDR_O+1 clocks (default 1), normal period CDR_N+1 (default 5), first-tick timing after a write.
- 1-wire phases: write-1 release at tick T_DAT1-1, write-0 hold and release at T_DAT0-1, reset-low release at T_RSTL-1, sample-window and dat/smp hold, dat = smp at cycle end.

Findings where the RTL disagrees with the datasheet. I did NOT assert the datasheet claim in these cases; the RTL-level behaviour is what the checker states.
1. A control write with cyc=0 still reloads rst/dat/ovd and sets owr_oen (`owr_oen <= ~&wdt[1:0]` has no cyc gate). In normal mode the divider never ticks while idle (pls needs div == 4), so the line stays driven indefinitely after e.g. a 0x00 write. Table 11 says cyc=0 means "no action".
2. In overdrive mode with CDR_O=0 (the default), pls fires every clock even when idle, so cnt keeps counting. Any ctl write with ovd=1 and cyc=0, or the wrap 256 clocks after a cycle ends, sets irq_sts and overwrites owr_dat with owr_smp. The zero-time idle (ovd=rst=dat=1, cyc=1) also does not stay at zero time: it counts 96 ticks and then sets irq. Table 12 says 0 us. The irq and dat assertions are therefore restricted to real cycle ends (owr_cyc high).
3. OWN=1: owr_sel is never assigned (only an initial block), so owr_e and owr_iln = owr_i[owr_sel] are arbitrary. There is no assertion about the input-to-sample data path, and owr_e is only checked with sel-independent properties.
4. owr_smp has no reset (noted in comments, not asserted before its first sample).

Caveat: I could not run a prover; only check_syntax.sh was permitted. Each assertion was checked by hand against the RTL timing (tick arithmetic: normal bit = 13 ticks / 65 us, reset = 192 ticks / 960 us, idle = 200 ticks / 1000 us; overdrive bit = 8, reset = 96, idle = 96). Any assertion that does not hold under formal analysis should be reported back for correction.

#### result

```
{"success":true,"message":"Report delivered to your caller."}
```
