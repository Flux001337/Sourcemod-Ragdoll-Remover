# Changelog

## 1.2.1

- Use Core dissolve (type 3) with zero magnitude instead of normal dissolve to avoid lifting ragdolls during removal.

## 1.2.0

- Add `sm_rgremove_time` to configure the delay before dissolving starts (default: 5 seconds).
- Track ragdolls when created instead of scanning all ragdolls every three seconds.
- Prevent duplicate scheduling for the same ragdoll.
- Remove ragdolls immediately if creating, spawning, or invoking the dissolver fails.
- Add fallback removal five seconds after dissolving starts if the ragdoll still exists.
- Track existing ragdolls when loaded late or enabled again.
- Preserve cleanup of in-progress dissolves when disabled.
- Clear tracked references on map end.
- Generate `cfg/sourcemod/plugin.ragdoll_remover.cfg` automatically.
- Modernize SourcePawn syntax.

## 1.1.0

The preceding local version included:

- Direct scans for `cs_ragdoll`, independent of the player's `m_hRagdoll` property.
- Entity references and class validation before dissolving.
- Validation before allocating a dissolver and cleanup of the temporary dissolver.
- A repeating scan timer supporting map changes and late loading.

Earlier release notes have not been supplied.
