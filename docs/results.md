# Implementation and verification results

## Overview

The multiplier was functionally validated at RTL, post-synthesis and post-layout
levels using Cadence Xcelium. The implementation flow includes Genus synthesis,
Innovus physical implementation and activity-based power estimation.

The results below summarize the simulation logs and implementation reports from
June 2026. Verification covers the project's numerical and exception contract,
described in [Architecture](architecture.md).

## Implementation results

| Measurement | Synthesis | Layout |
| --- | --- | --- |
| Target clock | 4 ns / 250 MHz | 4 ns / 250 MHz |
| Cell count | 3,099 | 3,004 |
| Reported cell area | 10,234.008 library area units | 7,082.478 library area units |
| Reported setup slack | +0.2 ps | +0.002 ns |
| Tool | Genus 21.19-s055_1 | Innovus 21.19-s058_1 |

Synthesis results come from `multiplier32fp_250MHz_qor.rpt` dated June 9,
2026. Layout results come from the corresponding area and timing reports;
the timing report is dated June 17, 2026 and names the slow setup analysis view.
The synthesis clock is reported as 4000 timing units and is consistent with the
4 ns target; its slack is expressed here in ps. Area is left in library units
rather than assuming a physical-unit conversion absent from the report headers.

The timing result describes the reported setup path at the 250 MHz target.
Maximum-frequency characterization, all-corner signoff and fabrication signoff
are separate extensions to this implementation study.

## Functional validation

Xcelium 23.09-s013 simulation logs record the following passing checks:

| Verification level | Operand vectors | Directed exception cases |
| --- | --- | --- |
| RTL | 100 passed | Passed |
| Post-synthesis | 100 passed | Passed |
| Post-layout | 100 passed | Passed |

Directed cases cover normal multiplication, NaN inputs, infinity multiplied by
zero, signed infinity, overflow, signed subnormals, underflow and truncation.
The reference model implements the same numerical contract as the RTL.
Independent arithmetic-oracle coverage is listed below as a future extension.

## Power estimate

The `power_2x_250MHz_layout` report records **0.1523 mW** total power at 0.9 V.
Its methodology is netlist-based activity analysis: the report explicitly states
`PreRoute`, `No SPEF/RCDB` and SI off, even though the input is a layout netlist.
The VCD-derived clock is approximately 249.881 MHz. The tool also reports a
default `90nm` design-mode label despite the GPDK045 library configuration;
the library configuration and this tool-mode label are recorded separately.

This is a netlist-based power estimate for the measured workload, including its
idle interval, library assumptions and activity annotation. Extracted parasitic
power analysis is a future extension.

## Future extensions

- Extend the recorded regression results with the additional streaming/reset
  testbench included in the repository and the consolidated batch runner.
- Add an independent arithmetic reference and broader randomized coverage.
- Characterize maximum frequency and timing across additional operating corners.
- Extend physical verification with comprehensive hold, DRC and LVS signoff.
- Estimate power using extracted routed parasitics and additional workloads.
- Associate future result sets with the source hashes recorded by the runner.
