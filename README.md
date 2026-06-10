# APB Bus Subsystem (SystemVerilog)

SystemVerilog implementation of a peripheral subsystem built around the **APB
(Advanced Peripheral Bus)** protocol. A bus master communicates with slave
peripherals through an address-decoded bus, with error handling for accesses to
unmapped memory regions. The design is verified in simulation with **ModelSim**.

## Overview

A single master is connected to multiple slaves, each mapped to a distinct
address window. The bus decodes the address of every transaction and routes it
to the correct slave, asserting an error response when a transaction targets an
address outside the mapped ranges.

The peripherals exercised in the testbench are a set of PWM generators and a
serial multiplier, where the multiplication result is reused to configure the
PWM parameters.

## Memory map

| Peripheral | Start address | End address |
|------------|---------------|-------------|
| Slave 0    | 0x0000        | 0x0FFF      |
| Slave 1    | 0x1000        | 0x1FFF      |
| Slave 2    | 0x2000        | 0x2FFF      |
| Slave 3    | 0x3000        | 0x3FFF      |

## Source files

| File                 | Description                                              |
|----------------------|----------------------------------------------------------|
| `APB_BUS.sv`         | Parametrizable APB interface with Master/Slave modports  |
| `APB_BUS_MASTER.sv`  | Master-side logic driving transactions on the bus        |
| `APB_BUS_SLAVE.sv`   | Slave-side logic, address decoding and error handling    |
| `tb.sv`              | Testbench                                                |
| `tb_v3.sv`           | Extended/updated testbench revision                      |

### APB interface

A SystemVerilog `interface` (`APB_BUS`) defines the bus signals (`paddr`,
`pwdata`, `pwrite`, `psel`, `penable`, `prdata`, `pready`, `pslverr`). Address
and data widths default to 32 bits and can be overridden at instantiation.
Separate `Master` and `Slave` modports fix the signal direction on each side.

### Serial multiplier registers

| Register  | Address | Width  | Access |
|-----------|---------|--------|--------|
| Operand A | 0x0     | 16-bit | Write  |
| Operand B | 0x4     | 16-bit | Write  |
| Result    | 0x8     | 32-bit | Read   |
| Start     | 0xC     | 1-bit  | Write  |

Multiplication takes several cycles, so the `pready` signal stalls the master
until the result register is valid.

## Verification

The testbench:

1. Loads operands A and B into the multiplier.
2. Starts the multiplication and reads back the result.
3. Configures the PWM (period = result, pulse = result/2, size = result/4).
4. Starts the PWM and checks the generated output.
5. Verifies that an access to a non-mapped address raises an error.

## Running the simulation (ModelSim)

```tcl
vlib work
vlog APB_BUS.sv APB_BUS_MASTER.sv APB_BUS_SLAVE.sv tb_v3.sv
vsim work.tb
run -all
```

Use `tb.sv` or `tb_v3.sv` as the top module depending on which scenario you
want to run.

## Tools

- **Language:** SystemVerilog
- **Simulator:** ModelSim

## Author

Alessandro Frullo — [github.com/axeldotf](https://github.com/axeldotf)
