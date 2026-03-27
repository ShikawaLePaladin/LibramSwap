---
name: addon-bug-triage
description: Investigate and triage ShikaSwap addon bugs before implementing a fix.
argument-hint: Describe the bug, symptom, affected spell, command, or reproduction steps.
agent: agent
---

You are triaging a bug in the ShikaSwap World of Warcraft 1.12 / Turtle WoW addon.

Use the user input as the bug report:

`$ARGUMENTS`

Follow this workflow:

1. Restate the reported symptom in one or two precise sentences.
2. Identify the most likely subsystem involved:
   - `LibramSwap_fixed.lua` for swap logic, spell resolution, throttling, bag checks, and equip behavior.
   - `LibramSwapConfig.lua` for UI, profiles, slash commands, and SavedVariables sanitization.
   - `LibramSwap.toc` for load order or SavedVariables registration.
   - `README.md` for user-facing behavior, command expectations, and macro requirements.
3. Inspect the relevant code paths before proposing any fix.
4. Prefer root-cause analysis over surface workarounds.
5. Respect the repo constraints from `.github/copilot-instructions.md`.

While investigating, explicitly check for these addon-specific failure modes when relevant:

- WoW 1.12 API limitations or missing modern APIs.
- Ranked spell parsing issues and exact spell-name matching.
- SavedVariables shape problems in `LibramSwapDB`.
- Incorrect use of `nil` where the addon expects the `"__NONE__"` sentinel.
- Direct mutations of persisted maps that bypass `LibramSwap_ApplySelection()`.
- Stale bag index state after item movement.
- Re-equip attempts when the libram is already equipped.
- Cursor or transaction state blocking item usage.
- Profile load behavior that only appears correct after `/reload`.
- Behavior that depends on macros to preserve spell rank.

Produce the answer in this format:

## Symptom
One short paragraph.

## Likely Area
Name the file and subsystem most likely responsible.

## Evidence To Check
List the exact code paths, state transitions, events, or SavedVariables fields to inspect.

## Most Likely Causes
Give the top 1 to 3 plausible root causes, ordered by likelihood.

## Recommended Next Step
State the best next action. Prefer one of:
- inspect a specific function or event flow
- add targeted debug logging
- reproduce with a specific in-game sequence
- implement a small, low-risk fix

## Validation
List the in-game checks to confirm the diagnosis, using `/reload`, `/ss`, `/ssikadebug on`, or the affected command flow when appropriate.

If the report is too vague to investigate well, ask only the minimum missing questions needed to continue, such as:

- the exact spell or libram involved
- whether the problem happens before or after `/reload`
- whether a macro is used
- whether the issue is runtime behavior, UI state, or saved profile behavior

Do not give generic Lua advice. Keep the analysis specific to this addon and its WoW environment.