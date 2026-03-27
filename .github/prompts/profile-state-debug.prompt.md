---
name: profile-state-debug
description: Investigate profile save/load and SavedVariables state bugs in ShikaSwap.
argument-hint: Describe the profile bug, reload mismatch, missing selection, or SavedVariables symptom.
agent: agent
---

You are debugging profile state and SavedVariables behavior in the ShikaSwap World of Warcraft 1.12 / Turtle WoW addon.

Use the user input as the bug report:

`$ARGUMENTS`

Focus your investigation on profile persistence, UI state, and reload behavior.

Prioritize these areas:

- `LibramSwapConfig.lua` profile creation, save, load, rename, delete, and UI refresh flows
- `LibramSwap_fixed.lua` login-time profile restore, runtime map synchronization, and watchdog behavior
- `LibramSwapDB` field shape and top-level sanitization
- `selectedProfile`, `lastUsedProfile`, `profiles`, `map`, `enabledMap`, and `spells`

Explicitly check for these failure modes when relevant:

- profile appears selected in the UI but runtime mapping does not match
- behavior works only after `/reload`
- dropdowns or indicators do not reflect saved selections after login or load
- a profile exists but contains malformed or incomplete payload fields
- saved map entries bypassed `LibramSwap_ApplySelection()` and left runtime mirrors stale
- invalid top-level SavedVariables fields were repaired, but the UI did not refresh accordingly

Produce the answer in this format:

## Symptom
Restate the profile or SavedVariables issue precisely.

## Likely State Boundary
Identify where state is drifting: UI only, persisted data only, runtime only, or profile load bridge.

## Evidence To Check
List the exact functions, fields, and event paths to inspect.

## Most Likely Causes
Give the top 1 to 3 root causes, ordered by likelihood.

## Recommended Next Step
Pick the best next move: inspect a specific save/load path, add targeted logging, reproduce with a specific `/reload` or relog flow, or implement a narrow fix.

## Validation
List the in-game steps to confirm the diagnosis, including `/ss`, profile save/load actions, and `/reload` when relevant.

If the report is too vague, ask only for the minimum missing detail needed to continue, such as:

- what profile action failed: create, save, load, rename, delete, relog restore
- whether the issue appears immediately or only after `/reload`
- whether the wrong state is visible in the UI, the runtime behavior, or both

Keep the analysis specific to this addon's SavedVariables and profile flow. Avoid generic Lua debugging advice.