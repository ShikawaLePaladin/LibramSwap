---
applyTo: "LibramSwap_fixed.lua"
---

# Runtime Swap Logic Instructions

Use these instructions when editing `LibramSwap_fixed.lua`, which owns the addon's runtime libram swap behavior.

## Scope

- Keep cast-time swap logic, spell resolution, bag indexing, throttling, and runtime SavedVariables synchronization in this file.
- Do not move UI, profile menu, or slash-command presentation logic here unless the runtime API truly needs a new integration point.

## Runtime Rules

- Preserve WoW 1.12 compatibility. Do not assume newer APIs or secure execution features exist.
- Prefer small helper functions and targeted conditionals over broad rewrites of the cast flow.
- Keep defensive table validation around `LibramSwapDB` before indexing nested fields.
- When changing mapping persistence, prefer the existing `LibramSwap_ApplySelection()` path so runtime mirrors, watched names, and backup state stay aligned.
- Preserve the `"__NONE__"` sentinel behavior for explicit cleared selections.

## Spell Resolution

- Preserve rank-aware spell parsing. If you touch spell matching, keep `SplitNameAndRank()` semantics intact.
- Be careful with spell-name normalization. Trailing-space fixes are acceptable; broad fuzzy matching is not.
- When changing spell readiness or cooldown checks, verify the logic still walks the spellbook safely and exits when `GetSpellName()` returns nil.
- If a behavior depends on macros to preserve exact spell rank, keep that assumption explicit and consistent with the README.

## Equip And Bag State

- Avoid re-equipping a libram if it is already equipped in the checked slots.
- Respect guardrails around `CursorHasItem()` and any other state that makes item use unsafe.
- If you change bag lookup behavior, make sure stale cached state still gets rebuilt through the bag index path.
- Do not add equip attempts that skip bag presence validation.

## Timing And Throttling

- Treat throttle and delay changes as behavior-sensitive. Small numeric edits can materially change in-game feel.
- Keep generic and per-spell throttle logic easy to inspect.
- If you add a spell-specific exception, keep it localized and document the reason briefly in code only if the behavior is otherwise non-obvious.

## Persistence And Reload Safety

- Runtime state should not depend on `/reload` to become correct.
- If you update `LibramSwapDB.map` or related runtime mirrors, ensure watchdog backup state remains synchronized.
- Avoid direct persisted-map mutations that bypass the code path responsible for bag index refresh and runtime bookkeeping.

## Validation Focus

After editing this file, validate with an in-game flow that covers:

1. selecting or loading a spell-to-libram mapping
2. casting the affected spell with the expected rank or macro form
3. confirming the swap does not repeat unnecessarily
4. confirming the behavior still works before and after `/reload`
5. checking `/ssikadebug on` output when diagnosing timing or resolution issues

## Avoid

- Do not introduce default libram selections implicitly at runtime.
- Do not replace exact matching with loose matching that could map the wrong spell.
- Do not split persistence logic across parallel helper paths unless the runtime contract is being intentionally redesigned.