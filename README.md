\# EGO1 DDS Waveform Generator with Vivado 2024.2



A clean Verilog implementation of a \*\*DDS-based waveform generator\*\* for the Xilinx Artix-7 / EGO1 platform.  

The design generates three digital waveforms:



\- Sine wave

\- Square wave

\- Triangle wave



The project focuses on \*\*Vivado simulation\*\*, modular Verilog design, FSM control, waveform switching, and common debugging issues.



> Target device used in the project: `xc7a35tcsg324-1`  

> Tool version: Vivado 2024.2  

> Board reference: EGO1 / Xilinx Artix-7 XC7A35T



\---



\## Quick Preview



The simulation verifies waveform switching through `key\_wave`.



| `wave\_led` | Waveform |

|---|---|

| `3'b001` | Sine wave |

| `3'b010` | Square wave |

| `3'b100` | Triangle wave |



Example simulation overview:



!\[DDS waveform overview](screenshots/01\_overview\_sine\_square\_triangle.png)



\---



\## What This Project Contains



```text

rtl/

&#x20; top\_dds\_wavegen.v      Top-level module

&#x20; dds\_core\_fixed.v       DDS core: sine / square / triangle generation

&#x20; sin\_lut\_256x8.v        256-point 8-bit sine lookup table

&#x20; wave\_select.v          Waveform and frequency selection

&#x20; sys\_fsm.v              Main FSM: IDLE / RUN / HOLD

&#x20; key\_debounce.v         Key debounce module

&#x20; seg7\_driver.v          Seven-segment display driver



sim/

&#x20; tb\_top\_dds\_wavegen.v   Vivado behavioral simulation testbench



docs/

&#x20; experience\_zh.md       Project experience and workflow notes

&#x20; debug\_notes\_zh.md      Debugging notes and common pitfalls







Design Overview



The design uses a DDS phase accumulator to generate waveform samples.



The core idea is:



A 32-bit phase accumulator continuously increases by freq\_word.

The high 8 bits of the phase accumulator are used as the waveform phase address.

Different output functions are selected according to wave\_sel.



Waveform mapping:



2'd0 -> sine wave

2'd1 -> square wave

2'd2 -> triangle wave



The system also includes a main FSM:



IDLE -> RUN -> HOLD



key\_start controls start/pause, and key\_wave switches waveform types.



Module Functions

top\_dds\_wavegen.v



Top-level connection module.

It instantiates:



key\_debounce

sys\_fsm

wave\_select

dds\_core\_fixed

seg7\_driver

dds\_core\_fixed.v



DDS waveform generation core.



It produces:



sine\_data

square\_data

triangle\_data



Then selects one of them:



case (wave\_sel)

&#x20;   2'd0: wave\_data = sine\_data;

&#x20;   2'd1: wave\_data = square\_data;

&#x20;   2'd2: wave\_data = triangle\_data;

endcase

wave\_select.v



Switches waveform and frequency according to key pulses.



sys\_fsm.v



Main control FSM with three states:



State	Meaning

IDLE	Waiting for start

RUN	DDS phase accumulator enabled

HOLD	DDS output paused

Simulation Guide

1\. Create a Vivado Project



Use Vivado 2024.2 and create an RTL project.



Recommended part:



xc7a35tcsg324-1

2\. Add Design Sources



Add all files under:



rtl/



Set the design top module as:



top\_dds\_wavegen

3\. Add Simulation Source



Add:



sim/tb\_top\_dds\_wavegen.v



Set the simulation top module as:



tb\_top\_dds\_wavegen

4\. Run Behavioral Simulation



Run:



Run Simulation -> Run Behavioral Simulation



Then run long enough to observe all waveform stages.



For example:



run 110 us

Expected Simulation Result

Sine Wave



When:



wave\_led = 3'b001



dac\_data shows a sine-like waveform.



Square Wave



When:



wave\_led = 3'b010



dac\_data switches between high and low levels.



Important note:



If dac\_data\[7:0] is displayed in analog style, Vivado may draw linear connections between sample points.

For a clearer square wave view, display dac\_data\[7:0] in digital/hex mode or observe dac\_data\[7].



Triangle Wave



When:



wave\_led = 3'b100



dac\_data shows linear rising and falling slopes.



Screenshots

Function	Screenshot

Overview	screenshots/01\_overview\_sine\_square\_triangle.png

Sine wave	screenshots/02\_sine\_wave.png

Square wave	screenshots/03\_square\_wave.png

Triangle wave	screenshots/04\_triangle\_wave.png

FSM HOLD state	screenshots/05\_fsm\_hold\_state.png

Common Pitfalls

1\. Square wave looks like triangle wave



This may happen when dac\_data\[7:0] is displayed in analog mode.

The actual data may still be switching between 8'hFF and 8'h00.



Recommended check:



Change display radix to Hexadecimal

Observe dac\_data\[7]

Check whether wave\_led = 3'b010

2\. Vivado uses old source files



Avoid mixing files from different folders.

Create a clean project and make sure all files come from the same source directory.



3\. Do not upload Vivado cache folders



Only upload clean source code, testbench, screenshots, and documentation.



Repository Purpose



This repository is intended for FPGA beginners who want a clear, reproducible example of:



DDS waveform generation

Modular Verilog design

Vivado behavioral simulation

FSM-based control

Debugging waveform display issues

License



This project is released for learning and reference purposes.

