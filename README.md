# BitJam

BitJam is a 32-bit CPU architecture, as well as a reference implementation in SystemVerilog.

Bitjam offers a novel architecture, in which the minimum addressible unit is the 32-bit word 
(rather than the byte, as is typical with most other CPUs), as well as a flexible and expressive
set of operations, allowing for rapid assembly programming and easier bootstrapping of 
programming languages on top of the base architecture.

The reference implementation given here targets the [Nexys A7-100T](https://digilent.com/reference/programmable-logic/nexys-a7/start)
FPGA, but can easily be adapted to other FPGA architectures.

See [BitJASM](https://github.com/StefanKopieczek/bitjasm.git) for an assembler implementation.

## Is this useful?

Almost certainly not, but it's fun!

## Is there any documentation?

Yes but it's not in Github yet. I'll upload it once iteration on the underlying architecture slows down.

## You're terrible at Verilog.

That's not a question, but I agree completely. Feedback is welcome &#150; I'm always happy to learn! :)

## How is this code licensed?

All of Bitjam falls under the MIT license.

Note that this project includes a modified version of the official Nexys A7-100T Xilinx constraints file, the
original version of which has *also* been made available under the MIT license by Digilent.

You can find the original version at https://github.com/Digilent/digilent-xdc/blob/master/Nexys-A7-100T-Master.xdc.
