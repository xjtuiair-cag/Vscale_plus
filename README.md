# vscale_plus

The Vscale_plus is a 3-stage single-scalar in-order RISC-V CPU, which is inherited from the UCB early project, [vscale](https://github.com/ucb-bar/vscale),
writen by Verilog HDL.
Since the orignal project, vscale, has no longer updated since 2016, we make some enhancements base on that.

Below are the mainly improvements:

* Fixed the combinational loop bug when CSR address is illegal;
* Revised the CSR address mapping to make it be compatible with the latest standard (2019,Aug.);
* Replaced the ERET instruction by MRET according to the latest specification;
* Re-composed the interrupt circuit to support Machine level Timer, software, and external interrupt ability.

In future, we are going to do such enhancements:

* Add instruction prediction circuit;
* Add USER mode, SUPERVISIOR mode support;
* Optimize the multiply, division circuit;

Any verification or suggestions are welcome.

## Simulation

Suppose you have installed VCS, IES, or Vivado simulation environment.

1. Open the Vivado project from /FPGA/vscale_plus173/vscale_plus.xpr.

2. Modify the line 9 of 'vscale_hex_tb.sv', change the 'base_dir' to your location of project.

3. Build the simulation library according to your simulation environment by clicking 'Vivado->Tools->Compile simulation libraries', and configure it to your simulation settings.
4. A sample code is supplied and pre-compiled on '/software/output' directory. Any modifications need a common RISC-V compiler on your PC. Please revise the makefile to fit your environment.
5. Now you can enjoy the simple and elegant vscale_plus design. Good luck~

