# Binding Candidate Review

- Metadata: `inst/extdata/webawesome/custom-elements.json`
- Source version: `3.3.1`
- Components reviewed: `58`
- Explicit binding overrides: `1`
- High-confidence review candidates: `0`
- Watch-list near misses: `5`

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
- Why it needed policy: Native click behavior is expected for button-like controls, but upstream metadata does not declare click as a component event for wa-button.

## High-Confidence Candidates To Review

None.

## Watch List / Near Misses

### `wa-copy-button`

- Review tier: `watch`
- Current classification: `wrapper`
- Declared events: wa-copy, wa-error
- Public methods: None
- Summary: Copies text data to the clipboard when the user clicks the trigger.
- Why watched:
- component naming/docs suggest directly activated control
- no declared binding event in metadata
- interactive surface present, but no click()-level action evidence

### `wa-option`

- Review tier: `watch`
- Current classification: `wrapper`
- Declared events: None
- Public methods: None
- Summary: Options define the selectable items within a select component.
- Why watched:
- component naming/docs suggest directly activated control
- no declared binding event in metadata
- interactive surface present, but no click()-level action evidence

### `wa-radio`

- Review tier: `watch`
- Current classification: `wrapper`
- Declared events: blur, focus
- Public methods: checkValidity, formDisabledCallback, formResetCallback, formStateRestoreCallback, getForm, reportValidity, resetValidity, setCustomStates, setCustomValidity, setValidity, setValue, updateValidity
- Summary: Radios allow the user to select a single option from a group.
- Why watched:
- component naming/docs suggest directly activated control
- no declared binding event in metadata
- interactive surface present, but no click()-level action evidence

### `wa-tab`

- Review tier: `watch`
- Current classification: `wrapper`
- Declared events: None
- Public methods: handleActiveChange, handleDisabledChange
- Summary: Tabs are used inside [tab groups](/docs/components/tab-group) to represent and activate [tab panels](/docs/components/tab-panel).
- Why watched:
- component naming/docs suggest directly activated control
- no declared binding event in metadata
- interactive surface present, but no click()-level action evidence

### `wa-tab-group`

- Review tier: `watch`
- Current classification: `wrapper`
- Declared events: wa-tab-hide, wa-tab-show
- Public methods: updateActiveTab, updateScrollControls
- Summary: Tab groups organize content into a container that shows one section at a time.
- Why watched:
- component naming/docs suggest directly activated control
- no declared binding event in metadata
- interactive surface present, but no click()-level action evidence

