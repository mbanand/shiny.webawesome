# Binding Candidate Review

- Metadata: `inst/extdata/webawesome/custom-elements.json`
- Source version: `3.3.1`
- Components reviewed: `58`
- Explicit binding overrides: `1`
- Additional review candidates: `0`

This report is advisory. It highlights wrapper-only components whose
metadata and docs suggest that their Shiny interaction contract may merit
manual review for a binding-support override.

## Explicit Overrides Already Applied

### `wa-button`

- Current classification: `wrapper-binding-action`
- Binding mode: `action`
- Events declared in metadata: blur, focus, wa-invalid
- Public methods: blur, checkValidity, click, focus, formDisabledCallback, formResetCallback, formStateRestoreCallback, getForm, handleDisabledChange, reportValidity, resetValidity, setCustomStates, setCustomValidity, setValidity, setValue, updateValidity
- Summary: Buttons represent actions that are available to the user.
- Why it needed policy: public click() method without declared click event; interactive public methods: blur, focus; docs contain interaction keywords

## Additional Candidates To Review

None.

