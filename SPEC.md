# Scarab Vault

Native offline adventure puzzle for iPhone and iPad, iOS 17+, SwiftUI, Swift 6. English (UK) throughout. Account identifier acc_374; local application identifier com.scarabvault.expedition (not an account identifier).

## Product
Five sequential temples, three rooms each. Each solved room permanently grants its own named artefact. Fifteen authored, deterministic starting positions; no randomness, currency, purchases, ads or network dependency. Unlimited attempts. Five rules: independent cylinders, next-neighbour coupling, reflected pairs, opposite neighbour movement and a five-cylinder cascade. Targets include ordered sequences, symbolic clues and mirrored arrangements. A finite-state breadth-first solver provides a valid next move from any reachable position.

## Screens
- Expedition map: five temples, active chapter, completed seals, progress, resume in one action.
- Temple: illustrated gates, story, room list, continue exploration.
- Mechanism: three/five stone cylinders, engraved target clues, selected cylinder, forward/back controls, reset confirmation, three-level hints, journal shortcut, gold Open slab.
- Journal: discovered rule diagrams, symbol meanings, room records with actual moves and hints.
- Museum: deterministic collection, empty state, locked shelves and individual artefact lore.
- Chapter/room completion: opening gate, guaranteed artefact, real move/hint statistics, next room/temple.

## Visual language
Background #071D1A, panels #113A32, gold #DDB65E, glow #46D8C5, stone #89775A, text #F6EBD1, secondary #ADBAA7. Original vector scarab, carved gate and stone patterns; restrained glow, serif editorial titles, gold frames. 8 pt spacing rhythm, 16 pt gutters, minimum 44 pt actions. Adaptive content max width on iPad, scrolling landscape, Dynamic Type, VoiceOver labels, Reduce Motion.

## State and correctness
Atomic versioned JSON save in Application Support, with backup of last valid file; unfinished board, selection, moves, hint level and solved records survive restart. Loading UI, recoverable read/write error with retry and explicit fresh-start confirmation. Complete offline by design. Tabs retain independent navigation stacks. Each room can be replayed; earned artefacts remain earned. No live data claim or external provider required.

## Verification
Unit tests: all 15 rooms solvable, inverse moves, deterministic coupling, shortest-path hints, corrupt persistence, save/reload, chapter unlock and fixed rewards. UI tests: map/temple/puzzle, incorrect Open, reset, three hints, solve and reward, museum detail, journal, restart persistence, iPad layout. QA uses factory simulator pool and build lock; evidence in output/ScarabVault-implementation. No shipping or deployment.
