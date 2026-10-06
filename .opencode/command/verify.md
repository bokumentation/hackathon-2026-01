---
description: Run the full verification gate suite (lint, synth, area, formal, test, sim) for TRI-ARGA and report a pass/fail summary.
agent: build
---

Run the repository verification gates from the repository root:

    bash .opencode/skill/project-workflow/scripts/verify.sh

Then summarize each gate (lint, synth-check, area, formal, test, sim) in a short table with its result. If a gate fails, show the relevant error output and stop.
