# Design documentation

Design-level documents for TRI-ARGA.

| Document | Contents |
| --- | --- |
| [`architecture.md`](architecture.md) | System architecture, layer boundaries, and RTL module map |
| [`threat-model.md`](threat-model.md) | Assets, threats, CWE mapping, and mitigations |
| [`verification-plan.md`](verification-plan.md) | Simulation, fault injection, formal properties, and metrics |
| [`trade-study.md`](trade-study.md) | Four trade studies: cipher (TS-01), MAC mode (TS-02), freshness (TS-03), tile size (TS-04) |
| [`fmea.md`](fmea.md) | Failure Mode and Effects Analysis, 10 failure modes sorted by RPN |
| [`quartus-plan.md`](quartus-plan.md) | DE10-Nano Quartus synthesis and SignalTap plan |
| [`quartus-report.md`](quartus-report.md) | Measured Quartus synthesis, fit, timing, and power results |
| [`signaltap-plan.md`](signaltap-plan.md) | On-board SignalTap capture procedure for the fail-closed cases |
| [`ideas/`](ideas/) | Earlier design explorations and alternatives |

The architecture, threat model, and verification plan describe the committed Tier A core and Tier B link.
The archived RF versions live under [`appendix/rf/docs/`](../../appendix/rf/docs/).
