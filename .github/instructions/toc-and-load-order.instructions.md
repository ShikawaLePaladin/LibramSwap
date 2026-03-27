---
applyTo: "LibramSwap.toc"
---

# TOC And Load Order Instructions

Use these instructions when editing `LibramSwap.toc`, which defines addon metadata, SavedVariables registration, and file load order.

## Scope

- Keep this file limited to addon metadata, SavedVariables declarations, and the ordered list of files loaded by WoW.
- Treat file ordering as runtime behavior, not just documentation.

## Rules

- Preserve WoW 1.12 compatibility and keep the interface version aligned with the target client.
- Keep `LibramSwapDB` registered as the SavedVariables table unless a task explicitly changes persistence design.
- If new files are added, place them deliberately so dependencies load before the code that uses them.
- Preserve the current separation where runtime logic loads before config UI code unless a change intentionally restructures initialization.
- Keep metadata concise and user-facing. Do not add noisy or speculative notes.

## Validation Focus

After editing this file, validate that:

1. the addon appears in-game without load errors
2. SavedVariables still persist across `/reload` and relog
3. runtime globals expected by the config UI exist when the UI opens
4. no file depends on functions or globals that now load too late

## Avoid

- Do not reorder files casually.
- Do not register new SavedVariables without a clear persistence requirement.
- Do not change metadata fields just to mirror README wording.