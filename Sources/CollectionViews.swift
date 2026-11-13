import SwiftUI

struct MuseumView: View {
    @Environment(GameStore.self) private var store
    var body: some View {
        ZStack { StoneBackground(); ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "OBJECTS WITH A MEMORY")
                    Text("The museum").vaultFont(36, weight: .medium, design: .serif)
                    Text("\(store.progress.completed.count) of 15 artefacts recovered").vaultFont(15).monospacedDigit().foregroundStyle(Palette.secondary)
                }.padding(.top, 16)
                if store.progress.completed.isEmpty {
                    VStack(spacing: 16) {
                        ScarabMark().frame(width: 160, height: 100)
                        Text("Your first discovery awaits").vaultFont(23, weight: .medium, design: .serif)
                        Text("Restore a room’s inscription to uncover its artefact. Each piece has a place and a story.").vaultFont(16).foregroundStyle(Palette.secondary).multilineTextAlignment(.center)
                        NavigationLink(value: VaultRoute.room(0)) { Text("Explore the first room") }.buttonStyle(GoldButton())
                    }.panel()
                }
                ForEach(Archive.temples) { temple in
                    VStack(alignment: .leading, spacing: 16) {
                        Eyebrow(text: "\(temple.id + 1) / \(temple.title.uppercased())")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                            ForEach(temple.rooms) { room in
                                let found = store.progress.completed[room.id] != nil
                                NavigationLink(value: VaultRoute.artefact(room.id)) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            Circle().stroke(Palette.gold.opacity(found ? 0.35 : 0.1), lineWidth: 1).frame(width: 80, height: 80)
                                            Image(systemName: found ? Glyph(rawValue: room.id % 6)!.icon : "lock").font(.system(size: found ? 34 : 23)).foregroundStyle(found ? Palette.gold : Palette.stone)
                                        }.frame(height: 96)
                                        Text(found ? room.artefact : "Unrecovered").vaultFont(17, weight: .medium, design: .serif).foregroundStyle(found ? Palette.ink : Palette.secondary).multilineTextAlignment(.center).frame(minHeight: 44)
                                        Text("Room \(room.number + 1)\(found ? " • view story" : " • restore to reveal")").vaultFont(11).foregroundStyle(Palette.secondary)
                                    }.frame(maxWidth: .infinity).panel()
                                }.disabled(!found).accessibilityIdentifier("artefact-\(room.id)")
                            }
                        }
                    }
                }
            }.page()
        }}.navigationTitle("Museum").navigationBarTitleDisplayMode(.inline)
    }
}
struct ArtefactView: View {
    @Environment(GameStore.self) private var store
    let room: Room
    var body: some View {
        ZStack { StoneBackground(); ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [Palette.gold.opacity(0.18), .clear], center: .center, startRadius: 10, endRadius: 140))
                    Circle().stroke(Palette.gold.opacity(0.2), lineWidth: 1).padding(24)
                    if room.id == 0 || room.id == 14 { ScarabMark().frame(width: 220, height: 180) }
                    else { Image(systemName: Glyph(rawValue: room.id % 6)!.icon).vaultFont(100, weight: .ultraLight).foregroundStyle(Palette.gold) }
                }.frame(height: 280).frame(maxWidth: .infinity).accessibilityHidden(true)
                Eyebrow(text: "ARTEFACT \(String(format: "%02d", room.id + 1)) / 15")
                Text(room.artefact).vaultFont(36, weight: .medium, design: .serif)
                Text(room.lore).vaultFont(18, design: .serif).lineSpacing(7).foregroundStyle(Palette.ink)
                VStack(alignment: .leading, spacing: 12) {
                    Label(Archive.temples[room.temple].title, systemImage: "building.columns")
                    Text("Recovered from \(room.title.lowercased()).").foregroundStyle(Palette.secondary)
                    if let record = store.progress.completed[room.id] {
                        Text("Found \(record.date.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "en_GB")))) • \(record.moves) moves").vaultFont(13).foregroundStyle(Palette.secondary)
                    }
                }.vaultFont(16).panel()
            }.page()
        }}.navigationTitle("Artefact story").navigationBarTitleDisplayMode(.inline)
    }
}
struct JournalView: View {
    @Environment(GameStore.self) private var store
    @State private var section = 0
    init() {
        #if DEBUG && targetEnvironment(simulator)
        _section = State(initialValue: ScreenshotLaunch.key == "journal-schemes" ? 1 : 0)
        #endif
    }
    var body: some View {
        ZStack { StoneBackground(); ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "THE KEEPER’S FIELD NOTES")
                    Text("Expedition journal").vaultFont(32, weight: .medium, design: .serif)
                    Text("Observe. Understand. Remember.").vaultFont(15).foregroundStyle(Palette.secondary)
                }.padding(.top, 16)
                Picker("Journal section", selection: $section) {
                    Text("Symbols").tag(0); Text("Schemes").tag(1); Text("Records").tag(2)
                }.pickerStyle(.segmented)
                if section == 0 {
                    Text("The inscription above each mechanism shows the exact order to restore. These six signs form its alphabet.").vaultFont(16).foregroundStyle(Palette.secondary).lineSpacing(4)
                    ForEach(Glyph.allCases, id: \.rawValue) { glyph in
                        HStack(spacing: 16) {
                            Image(systemName: glyph.icon).vaultFont(30).foregroundStyle(Palette.gold).frame(width: 48)
                            VStack(alignment: .leading, spacing: 6) { Text(glyph.title).vaultFont(22, weight: .medium, design: .serif); Text(glyph.meaning).vaultFont(14).foregroundStyle(Palette.secondary) }
                            Spacer(minLength: 0)
                        }.panel()
                    }
                } else if section == 1 {
                    ForEach(Archive.temples.filter { store.progress.visited.contains($0.id) }) { temple in
                        let rule = Rule(rawValue: temple.id)!
                        VStack(alignment: .leading, spacing: 16) {
                            Eyebrow(text: "SCHEME \(temple.id + 1) • \(temple.title.uppercased())")
                            Text(rule.title).vaultFont(24, weight: .medium, design: .serif)
                            Text(["[1]   [2]   [3]", "[1] → [2] → [3]", "[1] ↔ [3]   ·   [2]", "[1] ↑   [2] ↓   [3] ↑", "[1] → [2] → [3] → [4] → [5]"][temple.id])
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .minimumScaleFactor(0.7).lineLimit(1).foregroundStyle(Palette.gold)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .environment(\.layoutDirection, .leftToRight).accessibilityLabel(rule.explanation)
                            Text(rule.explanation).vaultFont(16).foregroundStyle(Palette.secondary).lineSpacing(4)
                        }.panel()
                    }
                    Text("New schemes are recorded when you enter a temple.").vaultFont(13).foregroundStyle(Palette.secondary)
                } else {
                    if store.progress.completed.isEmpty {
                        VStack(spacing: 16) { Image(systemName: "pencil.and.outline").font(.largeTitle).foregroundStyle(Palette.gold); Text("The first page is yours to write").font(.title3); Text("Restored rooms will appear here with their discoveries, moves and hints.").foregroundStyle(Palette.secondary) }.frame(maxWidth: .infinity).panel()
                    }
                    ForEach(Archive.rooms.filter { store.progress.completed[$0.id] != nil }) { room in
                        if let record = store.progress.completed[room.id] {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: "TEMPLE \(room.temple + 1) • ROOM \(room.number + 1)")
                                Text(room.artefact).vaultFont(24, weight: .medium, design: .serif)
                                Text("\(record.moves) moves • hint level \(record.hints)/3").vaultFont(15).monospacedDigit().foregroundStyle(Palette.secondary)
                                Text(record.date.formatted(.dateTime.day().month(.abbreviated).year().hour().minute().locale(Locale(identifier: "en_GB")))).vaultFont(12).foregroundStyle(Palette.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading).panel()
                        }
                    }
                }
            }.page()
        }}.navigationTitle("Journal").navigationBarTitleDisplayMode(.inline)
    }
}
