# ShikaSwap Workspace Instructions

## Project Overview

ShikaSwap is a World of Warcraft 1.12 / Turtle WoW addon that swaps Paladin librams before spell casts.

- Manifest: `LibramSwap.toc`
- Core runtime logic: `LibramSwap_fixed.lua`
- Configuration UI and profiles: `LibramSwapConfig.lua`
- User-facing usage and commands: `README.md`

There is no build pipeline. Changes are validated by loading the addon in-game and using `/reload`.

## Working Agreement

- Keep changes minimal and compatible with WoW 1.12 APIs.
- Preserve the current split between runtime swap logic and configuration UI.
- Prefer extending existing helpers and data flow instead of introducing parallel logic paths.
- Avoid broad refactors unless the task explicitly requires them.

## WoW Addon Constraints

- Target interface version is `11200`; do not assume TBC+ or retail APIs exist.
- SavedVariables persist through `LibramSwapDB` declared in `LibramSwap.toc`.
- Spell lookup is performed through the spellbook APIs and often requires iterating `GetSpellName(i, BOOKTYPE_SPELL)`.
- Item interactions depend on bag state, cursor state, and equipped slot checks.
- UI code uses the legacy frame API (`CreateFrame`, templates, `SetPoint`, `SlashCmdList`).

## SavedVariables Rules

- Defensively validate top-level saved fields before indexing them. This codebase expects patterns like `type(LibramSwapDB) == "table"`.
- Do not rely on `nil` to represent an explicit cleared selection in persisted maps. This addon uses the sentinel `"__NONE__"`.
- When updating spell-to-libram mappings, prefer existing APIs such as `LibramSwap_ApplySelection()` so runtime state, watched names, and backup state remain synchronized.
- Preserve profile payload structure unless a task explicitly changes migration behavior.

## Editing Guidance By File

### `LibramSwap_fixed.lua`

- Keep swap logic, spell resolution, throttling, and bag/equipment checks here.
- Preserve guardrails such as `CursorHasItem()` checks and checks for already equipped librams.
- When adding spell-specific behavior, follow the current pattern of small helper functions and targeted conditionals.
- Be careful with timing and throttle values; even small changes can alter in-game behavior noticeably.

### `LibramSwapConfig.lua`

- Keep UI construction, profile management, and slash-command handlers here.
- Follow existing frame/template patterns instead of introducing a different UI style.
- Preserve defensive sanitization of `LibramSwapDB` fields during load.
- When wiring UI interactions to saved state, use the same persistence path as the runtime logic.

### `LibramSwap.toc`

- Keep interface metadata and load order accurate.
- If new files are added, update load order deliberately.

## Common Pitfalls

- Directly mutating `LibramSwapDB.map` without updating runtime mirrors can create reload-only behavior or watchdog conflicts.
- Re-equipping a libram without checking currently equipped slots can cause redundant item use.
- Bag lookups based on stale cache state can fail unless the bag index is rebuilt appropriately.
- Spell matching for ranked spells is fragile; preserve rank-aware parsing when changing cast resolution.
- Some behavior described in `README.md` depends on macro use for exact spell rank detection.

## Validation

After editing addon behavior, validate manually in-game:

1. Reload the UI with `/reload`.
2. Open the config with `/ss` if the change touches the UI or saved state.
3. Toggle debug output with `/ssikadebug on` when diagnosing swap logic.
4. Exercise the affected spell or command flow and confirm chat/debug output matches expectations.

## Useful References

- See `README.md` for installation, slash commands, and user-facing behavior.
- Use `LibramSwap.toc` as the source of truth for addon entry points and saved variable registration.

## What To Avoid

- Do not add external dependencies or a fake build system for simple Lua changes.
- Do not replace defensive table checks with assumptions about saved data shape.
- Do not move UI logic into the runtime file or swap logic into the UI file unless there is a strong reason.
- Do not change slash commands or persisted keys casually; they are part of the user-facing contract.