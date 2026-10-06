# Golden vectors

Reference captures come from the `tt07-bep-decode` baseline submodule:

- `baseline/tt07-bep-decode/test/data/`

The baseline CSV captures encode the Manchester waveform used to validate the
decoder. They are consumed read-only from the submodule so the upstream data
stays canonical.

Frame-level vectors for SALARAS (valid frames, single-bit-flip faults on the
payload byte, and single-bit-flip faults on the integrity field) will be placed
here once the integrity field parameters are confirmed. The verification plan is
maintained in the local design documentation.
