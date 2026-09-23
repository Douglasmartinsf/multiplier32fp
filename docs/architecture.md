# Architecture and numerical contract

## Interface

| Port | Direction / width | Meaning |
| --- | --- | --- |
| `clk` | input / 1 | Rising-edge clock |
| `rst_n` | input / 1 | Asynchronous active-low reset; flushes pending work |
| `a_i`, `b_i` | input / 32 each | Binary32-encoded operands |
| `start_i` | input / 1 | Capture a transaction at the current rising edge |
| `product_o` | output / 32 | Encoded result, valid when `done_o` is high |
| `done_o` | output / 1 | Response valid; consecutive responses may keep it high |
| `nan_o`, `infinit_o` | output / 1 each | NaN/invalid case and infinite-input result |
| `overflow_o`, `underflow_o` | output / 1 each | Project-specific range indicators |

There is no ready signal or backpressure. At edge N the first stage captures
the transaction. At edge N+1 the second stage updates the result and flags.
Two operations may occupy the pipeline simultaneously. With continuous input,
throughput is one result per clock, after the initial latency.

| Rising edge | Captured input | Response after propagation |
| --- | --- | --- |
| N | A | No earlier request in this example |
| N+1 | B | Result A, `done_o=1` |
| N+2 | None | Result B, `done_o=1` |
| N+3 | None | Hold result B, `done_o=0`, flags cleared |

Reset clears the pipeline, result, valid signal and flags. Deassert reset away
from the active clock edge and meet the target cell recovery/removal constraints.

## Datapath

Operands contain one sign bit, eight exponent bits and 23 fraction bits. Normal
operands restore the implicit leading one; subnormals use a leading zero and
an unbiased exponent of -126. Significands multiply into a 48-bit intermediate.

The first stage stores the product, exponent sum, sign and special-case state.
The second stage normalizes the product, adjusts the exponent and discards low
bits. Normal operands use a shorter normalization path; subnormal operands use
a highest-set-bit search. No rounding increment is applied.

## Arithmetic and exceptions

| Condition | Result | Asserted flag |
| --- | --- | --- |
| Finite representable product | Magnitude truncated toward zero | None |
| Representable nonzero subnormal | Subnormal, preserving sign | None |
| NaN input, or infinity × zero | `0x00000000` | `nan_o` |
| Infinity × nonzero, non-NaN operand | Infinity with XOR sign | `infinit_o` |
| Zero × finite operand | Zero with XOR sign | None |
| Finite overflow | `0x7FFFFFFF`, independent of sign | `overflow_o` |
| Nonzero finite result too small to retain any fraction bit | Positive zero | `underflow_o` |

`0x7FFFFFFF` is a NaN encoding in binary32, but this circuit uses it as its
overflow sentinel; consumers must inspect flags. NaN payloads are not propagated.
There are no selectable rounding modes, inexact flag or separate signaling-NaN
behavior. These conventions deliberately describe the existing implementation;
portfolio preparation does not change the arithmetic contract.

## Verification design

The vector testbench retains the original 100 operand pairs and reference task.
That reference resembles the RTL and is not an independent compliance oracle.
Directed cases use explicit expected encodings. A separate protocol testbench
checks back-to-back inputs, bubbles, result retention, flag clearing, reset
flushing and numerical boundaries. Every suite has a timeout and a pass marker;
the runner requires successful completion and checks error diagnostics.
