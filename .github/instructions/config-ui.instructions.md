---
applyTo: "LibramSwapConfig.lua"
---

# Config UI Instructions

Use these instructions when editing `LibramSwapConfig.lua`, which owns the addon's configuration window, profile flows, spell list management, and slash-command UI behavior.

## Scope

- Keep frame construction, widget layout, picker dialogs, profile UI, and slash-command handlers in this file.
- Do not move swap execution logic or bag/equip decision-making into the UI layer.
- When the UI needs runtime behavior changes, prefer calling the existing runtime APIs instead of duplicating runtime state management here.

## UI Framework Rules

- Preserve compatibility with the WoW 1.12 frame API and template system.
- Follow the existing `CreateFrame`, `SetPoint`, `SetScript`, and template-based patterns instead of introducing a different UI architecture.
- Keep changes incremental. Small layout adjustments are preferred over rebuilding the frame tree.
- Reuse existing popups, scroll frames, and button patterns when extending the UI.

## SavedVariables And State

- Defensively sanitize `LibramSwapDB` fields before indexing them. This file already expects corrupted or non-table fields to be repaired during load.
- Preserve `_broken_fields` behavior when repairing invalid saved data.
- When a UI action changes spell-to-libram assignments, prefer `LibramSwap_ApplySelection()` so runtime state, backup state, and watched-item bookkeeping stay consistent.
- Preserve the addon's explicit-clear semantics: use the existing `"__NONE__"` contract where the fallback path needs to persist a cleared value.
- Preserve existing profile payload shapes unless a task explicitly requires a migration.

## Profile And Spell List Behavior

- Keep the current separation between the visible spell list, the pool of available default spells, and persisted profile data.
- Avoid silent data loss when adding or removing spells from the UI.
- If profile load or save behavior changes, make sure the active-profile label, selected profile fields, and persisted profile tables remain in sync.
- Prefer updating existing UI refresh paths instead of creating one-off refresh logic for individual widgets.

## Slash Commands And User Feedback

- Preserve existing slash commands unless the task explicitly changes the user-facing contract.
- Keep chat feedback concise and actionable.
- When adding debug or status output, align it with the current ShikaSwap chat-message style.

## Interaction Patterns

- Respect the current picker/backdrop behavior for closing overlays and restoring focus.
- Keep scrollable lists usable on the Vanilla client, including mouse-wheel support where it already exists.
- Be careful with frame strata, hide/show ordering, and click-outside behavior so popups do not get stuck open.
- Prefer updating visible labels and indicators immediately after a user action so the UI reflects persisted state without requiring `/reload`.

## Validation Focus

After editing this file, validate with an in-game flow that covers:

1. opening and closing the config with `/ss`
2. selecting a libram from the picker and confirming the visible label and indicator update immediately
3. saving and loading a profile if the change touches profiles or persisted state
4. reloading with `/reload` and confirming the UI still reflects the saved configuration
5. checking any modified slash command or popup flow for regressions

## Avoid

- Do not introduce a second persistence path that bypasses runtime APIs unless there is a deliberate compatibility fallback.
- Do not assume SavedVariables fields always exist or always have the expected type.
- Do not replace the legacy frame/template approach with a modern abstraction layer.
- Do not make user-facing command or label changes casually; they affect documented behavior in the README.