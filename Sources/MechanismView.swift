import SwiftUI

struct MechanismView: View {
    @Environment(VaultNavigator.self) private var navigator
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let room: Room
    @State private var resetShown = false
    @State private var journalShown = false
    @State private var victory = false
    @State private var message: String?
    @State private var nextHint: Turn?
    @State private var calculating = false
    private var attempt: Attempt { store.attempt(room) }
    var body: some View {
        ZStack { StoneBackground(); ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Eyebrow(text: "\(Archive.temples[room.temple].title.uppercased()) • ROOM \(room.number + 1)")
                    Text(room.title).vaultFont(28, weight: .medium, design: .serif).multilineTextAlignment(.center)
                    HStack { Label("Seals \(store.seals)/5", systemImage: "seal"); Spacer(); Text("\(attempt.moves) moves") }.vaultFont(13).monospacedDigit().foregroundStyle(Palette.secondary)
                }.padding(.top, 16)
                VStack(spacing: 12) {
                    Eyebrow(text: "THE CARVED INSCRIPTION")
                    HStack(spacing: 16) {
                        ForEach(Array(room.target.enumerated()), id: \.offset) { _, value in
                            VStack(spacing: 8) {
                                Image(systemName: Glyph(rawValue: value)!.icon).font(.system(size: 24)).foregroundStyle(Palette.gold).frame(height: 32)
                                Text(Glyph(rawValue: value)!.title).vaultFont(11).foregroundStyle(Palette.secondary)
                            }.frame(maxWidth: .infinity).accessibilityElement(children: .combine)
                        }
                    }.environment(\.layoutDirection, .leftToRight)
                    Text(room.inscription).vaultFont(13).foregroundStyle(Palette.secondary).multilineTextAlignment(.center)
                }.panel()
                VStack(spacing: 16) {
                    HStack { Image(systemName: "diamond.fill"); Rectangle().frame(height: 1); Text("THE STONE CYLINDERS").vaultFont(10, weight: .bold).tracking(1.3).fixedSize(horizontal: true, vertical: false); Rectangle().frame(height: 1); Image(systemName: "diamond.fill") }.foregroundStyle(Palette.gold).vaultFont(7)
                    HStack(spacing: room.start.count == 5 ? 5 : 12) {
                        ForEach(attempt.board.indices, id: \.self) { index in
                            Cylinder(value: attempt.board[index], index: index, selected: attempt.selected == index, matched: attempt.board[index] == room.target[index], compact: room.start.count == 5) {
                                store.select(index, in: room)
                            }
                        }
                    }.environment(\.layoutDirection, .leftToRight)
                    HStack(spacing: 4) { Image(systemName: "arrow.triangle.branch"); Text(room.rule.title) }.vaultFont(12).foregroundStyle(Palette.gold)
                }.padding(16)
                    .background(LinearGradient(colors: [Color(hex: 0x302D20), Palette.background, Color(hex: 0x302D20)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(colors: [Palette.gold, Palette.stone, Palette.gold], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.gold.opacity(0.3), lineWidth: 1).padding(7))
                VStack(spacing: 12) {
                    Text("Cylinder \(attempt.selected + 1) selected").vaultFont(13).foregroundStyle(Palette.secondary).accessibilityIdentifier("selected-cylinder")
                    HStack(spacing: 16) {
                        turnButton("Turn back", icon: "arrow.uturn.left", direction: -1)
                        turnButton("Turn forward", icon: "arrow.uturn.right", direction: 1)
                    }
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                            if store.open(room) { victory.toggle(); message = nil; navigator.path.append(.completion(room.id)) }
                            else { message = "The gate is still. Match each cylinder to the inscription above, then try again." }
                        }
                    } label: { Label("Open the gate", systemImage: "sun.max") }.buttonStyle(GoldButton()).accessibilityIdentifier("open-gate")
                    if let message {
                        Label(message, systemImage: "info.circle").vaultFont(14).foregroundStyle(Palette.ink).panel().accessibilityIdentifier("gate-message")
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button { store.hint(room) } label: { Label(attempt.hints == 0 ? "Ask for a hint" : "Hint \(attempt.hints)/3", systemImage: "lightbulb") }.frame(minHeight: 44).accessibilityIdentifier("hint")
                        Spacer()
                        Button { resetShown = true } label: { Label("Reset", systemImage: "arrow.counterclockwise") }.frame(minHeight: 44).accessibilityIdentifier("reset")
                    }
                    if attempt.hints > 0 {
                        Text(room.rule.thought).vaultFont(15).foregroundStyle(Palette.ink)
                        if attempt.hints >= 2 { Text(room.rule.explanation).vaultFont(15).foregroundStyle(Palette.secondary) }
                        if attempt.hints == 3 {
                            if calculating { ProgressView("Reading the stones…") }
                            else if let move = nextHint {
                                Label("Next move: cylinder \(move.index + 1), turn \(move.direction == 1 ? "forward" : "back").", systemImage: "arrow.right.circle").vaultFont(15, weight: .semibold).foregroundStyle(Palette.gold).accessibilityIdentifier("next-move")
                            } else { Text(attempt.board == room.target ? "The inscription is restored. Open the gate." : "Reset the room to restore the mechanism.").foregroundStyle(Palette.gold) }
                        }
                    }
                }.panel()
                Button { journalShown = true } label: { Label("Consult the expedition journal", systemImage: "book") }.frame(minHeight: 44)
                Text("Take your time. Every turn can be undone.").vaultFont(12).foregroundStyle(Palette.secondary)
            }.page()
        }}
        .navigationTitle("The mechanism").navigationBarTitleDisplayMode(.inline)
        .onAppear { store.enter(room) }
        .sensoryFeedback(.success, trigger: victory)
        .sensoryFeedback(.selection, trigger: attempt.selected)
        .task(id: "\(attempt.board)-\(attempt.hints)") {
            guard attempt.hints == 3 else { return }
            calculating = true
            let board = attempt.board, target = room.target, rule = room.rule
            let solution = await Task.detached(priority: .userInitiated) { Engine.solution(from: board, to: target, rule: rule) }.value
            guard !Task.isCancelled else { return }
            nextHint = solution?.first; calculating = false
        }
        .confirmationDialog("Reset this room? Your collected artefacts will remain in the museum.", isPresented: $resetShown, titleVisibility: .visible) {
            Button("Reset room", role: .destructive) { store.reset(room); message = nil }
        }
        .sheet(isPresented: $journalShown) { NavigationStack { JournalView().toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { journalShown = false } } } }.presentationDragIndicator(.visible) }
    }
    private func turnButton(_ title: String, icon: String, direction: Int) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { store.turn(direction, in: room); message = nil }
        } label: { Label(title, systemImage: icon).vaultFont(15, weight: .medium).frame(maxWidth: .infinity).frame(minHeight: 48).background(Palette.panel, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.gold.opacity(0.4))) }.accessibilityIdentifier(direction == 1 ? "forward" : "backward")
    }
}
struct Cylinder: View {
    let value: Int
    let index: Int
    let selected: Bool
    let matched: Bool
    let compact: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: Glyph(rawValue: (value + 5) % 6)!.icon).font(.system(size: compact ? 20 : 26)).foregroundStyle(Palette.stone.opacity(0.6)).frame(height: 32)
                Rectangle().fill(Palette.gold.opacity(0.25)).frame(height: 1)
                Image(systemName: Glyph(rawValue: value)!.icon).font(.system(size: compact ? 28 : 40, weight: .light)).foregroundStyle(Palette.gold).frame(height: 66).frame(maxWidth: .infinity)
                    .background(Palette.gold.opacity(0.05))
                Rectangle().fill(Palette.gold.opacity(0.25)).frame(height: 1)
                Image(systemName: Glyph(rawValue: (value + 1) % 6)!.icon).font(.system(size: compact ? 20 : 26)).foregroundStyle(Palette.stone.opacity(0.6)).frame(height: 32)
                HStack(spacing: 3) { Text("\(index + 1)"); if matched { Image(systemName: "checkmark").vaultFont(9) } }.font(.system(size: 11).monospacedDigit()).foregroundStyle(selected ? Palette.gold : Palette.secondary).frame(height: 22)
            }.frame(maxWidth: .infinity)
                .background(LinearGradient(colors: [Color(hex: 0x292E25), Color(hex: 0x53513C), Color(hex: 0x30382C), Color(hex: 0x17241D)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(selected ? Palette.gold : Palette.stone.opacity(0.4), lineWidth: selected ? 2 : 1))
                .overlay(alignment: .bottom) { if selected { Capsule().fill(Palette.gold).frame(width: 20, height: 3).offset(y: 7) } }
        }.buttonStyle(.plain).accessibilityLabel("Cylinder \(index + 1), \(Glyph(rawValue: value)!.title)\(matched ? ", matching" : "")")
            .accessibilityValue(selected ? "Selected" : "Not selected").accessibilityHint("Select this cylinder to turn it")
            .accessibilityIdentifier("cylinder-\(index)")
    }
}
struct CompletionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let room: Room
    @State private var opened = false
    var chapterComplete: Bool { Archive.temples[room.temple].rooms.allSatisfy { store.progress.completed[$0.id] != nil } }
    var body: some View {
        ZStack { StoneBackground(); ScrollView {
            VStack(spacing: 24) {
                TempleArt(opened: opened, chapter: room.temple)
                Eyebrow(text: chapterComplete ? "CHAPTER RESTORED" : "THE GATE OPENS")
                Text(room.id == 14 ? "The vault remembers you." : "A secret, brought to light.").vaultFont(32, weight: .medium, design: .serif).multilineTextAlignment(.center)
                VStack(spacing: 16) {
                    Image(systemName: Glyph(rawValue: room.id % 6)!.icon).vaultFont(52).foregroundStyle(Palette.gold).padding(16)
                    Text(room.artefact).vaultFont(26, weight: .medium, design: .serif).accessibilityIdentifier("reward-title")
                    Text("Added to your museum").vaultFont(13).foregroundStyle(Palette.glow)
                    Text(room.lore).vaultFont(16).lineSpacing(4).foregroundStyle(Palette.secondary)
                }.panel()
                HStack {
                    stat("MOVES", value: "\(store.attempt(room).moves)")
                    Spacer(); stat("HINT LEVEL", value: "\(store.attempt(room).hints)/3")
                    Spacer(); stat("SEALS", value: "\(store.seals)/5")
                }.padding(.horizontal, 16)
                if room.id < 14 {
                    NavigationLink(value: VaultRoute.room(room.id + 1)) { Text(chapterComplete ? "Enter the next temple" : "Explore the next room") }.buttonStyle(GoldButton()).accessibilityIdentifier("next-room")
                } else {
                    Text("All five temples are restored. Revisit any room from the map, or explore your complete collection.").foregroundStyle(Palette.secondary).multilineTextAlignment(.center)
                }
            }.page()
        }}.navigationTitle(chapterComplete ? "Temple complete" : "Room restored").navigationBarTitleDisplayMode(.inline)
            .onAppear { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { opened = true } }
    }
    private func stat(_ title: String, value: String) -> some View {
        VStack(spacing: 8) { Text(value).vaultFont(30, weight: .medium, design: .serif).monospacedDigit().foregroundStyle(Palette.gold); Text(title).vaultFont(10, weight: .semibold).tracking(1).foregroundStyle(Palette.secondary) }
    }
}
