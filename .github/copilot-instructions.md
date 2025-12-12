# Copilot instructions for LibramSwap (WoW 1.12/Turtle addon)

Goal: Make an AI coding agent productive quickly when modifying this World of Warcraft (Vanilla/Turtle) addon written in Lua.

Quick summary
- This repo is a WoW 1.12 (Vanilla/Turtle) addon that automatically equips the correct libram when a Paladin casts certain spells.
- Key files: `LibramSwap.lua` (core swap logic, hooks, events), `LibramSwapConfigVanilla.lua` (configuration UI / dropdowns), `LibramSwap.toc`, `README.md`.

What matters (big picture)
- `LibramSwap.lua` contains the runtime behavior:
  - `LibramMap` (global table): maps spell base names to preferred libram name strings.
  - `BuildBagIndex()` / `HasItemInBags()` maintain a small cache of where watched librams are in the player's bags.
  - `EquipLibramForSpell(spellName, itemName)` performs the actual UseContainerItem and applies throttles.
  - `ResolveLibramForSpell(spellName)` chooses a libram (special-cased `Consecration`).
  - Hooks: overrides `CastSpell` and `CastSpellByName` to run swap logic before casting. Also uses an event frame for `SPELLCAST` / `BAG_UPDATE`.
- `LibramSwapConfigVanilla.lua` builds the configuration UI (frame + dropdowns). It must be Vanilla-friendly: UIDropDownMenu quirks, `this` vs `self`, `UIDropDownMenu_Initialize` in OnShow, and slash commands declared early.

Critical developer/workflow steps (how to run and debug in this project)
- Install the addon into the WoW `Interface/AddOns/LibramSwap` folder or run from the workspace when starting the client.
- Reload UI in-game to test changes: use `/reload ui` or logout & back in.
- Useful slash commands implemented by the addon:
  - `/libramconfig` - open the configuration menu.
  - `/libramswap` - toggle the addon on/off (watch chat for `LibramSwap ENABLED` / `DISABLED`).
  - `/swaplibram <SpellName>` or `/equiplibram <ExactName>` for manual testing.
- Debugging: the addon uses `DEFAULT_CHAT_FRAME:AddMessage` to print debug lines like `[LibramSwap]` and config messages. Watch the chat window for messages when testing.

Project-specific conventions & gotchas (must-follow)
- Vanilla/Turtle UI API differences:
  - Use `UIDropDownMenu_Initialize(dropdownFrame, initFunc)` inside an `OnShow` handler to populate drop-downs.
  - Use `UIDropDownMenu_SetSelectedID` (not modern SetSelectedValue). Create named frames for each dropdown (`CreateFrame("Frame", "Name", parent, "UIDropDownMenuTemplate")`).
  - Use `this` in `OnDragStart/OnDragStop` handlers if older API is expected.
- Avoid `string:method()` shorthand in some contexts; prefer `string.gsub(s, ...)` when older environments may not expose method syntax.
- Global state:
  - `LibramMap` must be global so config UI can read/write it. Keep its keys exact spell base names (e.g. "Holy Light").
  - Watch `LibramSwapEnabled` toggle — make sure hooks check it before swapping.
- Hooking casts: the addon overrides global functions (`CastSpell`, `CastSpellByName`). Respect existing behavior: always call the original function and avoid swallowing arguments.
- Bag scanning: `BuildBagIndex()` caches only watched names. If you change `WatchedNames` you must rebuild the index.

Files to inspect first when debugging swap failures
- `LibramSwap.lua`:
  - Check `LibramMap` entries for the spell names (exact strings). If `Holy Shield` or `Hand of Freedom` don't work, first verify keys exist.
  - Inspect `ResolveLibramForSpell(spellName)` to confirm it returns the expected libram string for that spell.
  - Inspect `EquipLibramForSpell` for early exits (cursor occupied, interaction windows open, throttles) and bag lookup.
  - Check event handler registration and the `OnEvent` implementation; verify it uses `(event, ...)`/`arg1` appropriately for this codebase.
- `LibramSwapConfigVanilla.lua`:
  - Confirm dropdown handlers set `LibramMap[spell] = selected` and call any apply helper (e.g. `LibramSwap_ApplySelection(spell, item)` if present).
  - Verify the file registers slash commands at the top (Vanilla expects slash defs early).

How to make a safe change to fix a swap that "doesn't work"
1. Reproduce in-game and capture chat debug output (enable minimal prints if necessary).
2. Confirm `LibramMap` contains the exact spell name used by the cast (use `SlashCmdList` test or a quick print of `LibramMap["Holy Shield"]`).
3. If `ResolveLibramForSpell` returns nil, update `LibramMap` or add a fallback.
4. If mapping exists but `EquipLibramForSpell` returns early, check for cursor occupation, open interaction frames, or throttles. Add debug prints around those returns.
5. If bag lookup fails, run `/testbags` (provided debug command) to list container links and verify the libram name substring match.

Persistence (SavedVariables)
- The `.toc` currently must include `## SavedVariables: LibramSwapDB` if you want selections to persist. Implementation pattern in codebase: store mapping into `LibramSwapDB = LibramSwapDB or { map = {} }` and write `LibramSwapDB.map = LibramMap` when changes are made.

Examples & snippets (from this codebase)
- Equip call flow (simplified):
```lua
local libram = ResolveLibramForSpell("Holy Light")
if libram then EquipLibramForSpell("Holy Light", libram) end
```
- Bag lookup uses `string.find(link, itemName, 1, true)` (plain substring match).

Testing checklist for UI changes (dropdowns / scroll)
- After modifying `LibramSwapConfigVanilla.lua`:
  - Ensure slash commands are declared at file top.
  - Ensure each dropdown has a unique global frame name and an initialize function (`UIDropDownMenu_Initialize`) called on parent `OnShow`.
  - For mouse wheel scrolling, use a scrollframe or capture `OnMouseWheel` and check both positive and negative delta handling.

Final notes for the agent
- Prioritize non-invasive fixes: add debug prints, reproduce in-game, then modify behavior.
- Preserve Vanilla compatibility: assume older WoW UI quirks rather than modern WoW APIs.
- Refer to `LibramSwap.lua` and `LibramSwapConfigVanilla.lua` for exact variable names and patterns.

If you want, I'll now write the `SavedVariables` persistence scaffold and wire dropdown handlers to call a small API function `LibramSwap_ApplySelection(spell, libram)` so mapping changes apply immediately and persist across reloads. Tell me to proceed or ask for a different next step.