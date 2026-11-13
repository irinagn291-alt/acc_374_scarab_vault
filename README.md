# Scarab Vault

An original, entirely English (UK), offline adventure puzzle. Five temples contain 15 deterministic mechanisms, each with a permanent artefact and an original story. Built with SwiftUI, Swift 6, minimum iOS 17; supports iPhone and iPad.

Open `ScarabVault.xcodeproj` and choose the `ScarabVault` scheme. The project was generated with the factory's bundled XcodeGen; `project.yml` is its reproducible definition. There are no packages, secrets, accounts, purchases, ads or online services needed to play. Development code signing is disabled for simulator builds; a physical-device/archive build needs an appropriate signing team.

## Play

Choose **Continue expedition** on the map. Select a cylinder, turn it forwards or backwards and match the inscription above. **Open the gate** checks the arrangement without consuming anything. Hints progress from a direction of thought to a rule explanation and then a valid next move. **Reset** restores the room after confirmation. Each temple teaches a different rule. The Museum contains recovered objects and their stories; the Journal contains symbols, discovered schemes and real completion records.

The first room takes one forward turn of the first cylinder. Later temples introduce linked neighbours, mirrored partners, opposing counterweights and cascades. Room targets and starting positions are authored, repeatable and solvable; no random rolls are used.

## Persistence

A versioned JSON save and its previous valid version live under the app's Application Support directory. Unfinished boards, selected cylinders, moves, hints, completed rooms and discovered schemes survive restart. Writes are atomic. Read failures offer retry, backup restoration or a confirmed fresh start. Write failures keep the in-memory state and offer retry. Everything works offline.

## Verification

`Tests/PuzzleTests.swift` checks all room solutions, inverse and coupled moves, valid hints after detours, progression, idempotent rewards, saved unfinished state, JSON validation and backup behaviour. `UITests/ExpeditionUITests.swift` traverses all five temples with actual controls, plus the failure/reset/hint/collection/journal/relaunch journey and landscape capture. UI tests use a separate debug save file.

Build and runtime evidence is kept at:
`/Users/belzephyrus/Documents/gambling_factory/output/ScarabVault-implementation/`

Use the factory shims and lock for builds. For runtime QA, run the entire `qa.sh` under the factory simulator pool, passing an existing template UDID. Never create or erase a shared simulator. The script obtains its device from `GF_SIMULATOR_UDID` and writes evidence before the pool disposes of it.

## Factory

Imported into Scratch as `com.scarabvault.expedition`, linked to account `374` (`acc_374`) and New app `cmwc7to5l00l1fdfl02t2h5fk`. No shipping, domain operation or deployment was started. The original task's metadata locales are preserved; the delivered interface is English as explicitly requested.
