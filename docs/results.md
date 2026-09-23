# Results and evidence

## Status

The portfolio preparation preserves the RTL arithmetic. Scripts and testbenches
have changed and **await execution on the academic Cadence server**. The SSH
connection encountered a host-identity mismatch during preparation; validation
must wait until the server identity is verified through a trusted channel.

The following values were transcribed from existing local reports, not measured
with the revised flow. Historical reports are not bound to a recorded source
hash, so they cannot establish equivalence to the current checkout.

## Historical implementation observations

| Measurement | Synthesis | Layout |
| --- | --- | --- |
| Target clock | 4 ns / 250 MHz | 4 ns / 250 MHz |
| Cell count | 3,099 | 3,004 |
| Reported cell area | 10,234.008 library area units | 7,082.478 library area units |
| Reported setup slack | +0.2 ps | +0.002 ns |
| Tool | Genus 21.19-s055_1 | Innovus 21.19-s058_1 |

Synthesis observations come from `multiplier32fp_250MHz_qor.rpt` dated June 9,
2026. Layout observations come from the corresponding area and timing reports;
the timing report is dated June 17, 2026 and names the slow setup analysis view.
The synthesis clock is reported as 4000 timing units and is consistent with the
4 ns target; its slack is expressed here in ps. Area is left in library units
rather than assuming a physical-unit conversion absent from the report headers.

These excerpts do not prove maximum frequency, all-corner timing closure,
hold closure, DRC/LVS signoff or fabrication readiness. Differences in cell count
must not be attributed to a particular optimization without matching run data.

## Historical functional checks

Xcelium 23.09-s013 logs report 100 passing vectors at RTL, post-synthesis and
post-layout levels. Separate logs report passing directed exception cases at
all three levels. They predate the new protocol suite and fail-fast handling.
The reference model shares structure with the RTL; this is functional regression
evidence, not an independent floating-point conformance certification.

## Historical power estimate

The `power_2x_250MHz_layout` report records **0.1523 mW** total power at 0.9 V.
Its methodology is netlist-based activity analysis: the report explicitly states
`PreRoute`, `No SPEF/RCDB` and SI off, even though the input is a layout netlist.
The VCD-derived clock is approximately 249.881 MHz. The tool also reports a
default `90nm` design-mode label despite the GPDK045 library configuration;
this inconsistency remains a limitation to inspect in a fresh run.

Do not describe this value as extracted post-route signoff power. It depends on
the historical workload, its idle interval, library assumptions and activity
annotation. No power-efficiency or cross-design comparison is claimed.

## Pending validation checklist

- Verify server identity and restore trusted SSH access.
- Configure tools, license environment, cell models and technology locally.
- Execute the three RTL suites and confirm all assertions and timeouts.
- Regenerate synthesis/layout outputs at 4 ns; inspect constraints and warnings.
- Run all three suites against both generated netlists with SDF annotation.
- Inspect setup/hold reports and annotation coverage, beyond the pass markers.
- Regenerate power estimates and document workload and parasitic limitations.
- Update this document from the new logs and recorded source hashes, retaining
  the distinction between historical and reproduced results.
