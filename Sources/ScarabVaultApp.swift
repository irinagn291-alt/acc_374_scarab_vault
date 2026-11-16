import SwiftUI

enum VaultRoute: Hashable {
    case temple(Int), room(Int), completion(Int), artefact(Int)
}
@MainActor @Observable final class VaultNavigator {
    var path: [VaultRoute] = []
    init(path: [VaultRoute] = []) { self.path = path }
}

#if DEBUG && targetEnvironment(simulator)
enum ScreenshotLaunch {
    static let keys = ["expedition-map", "temple", "mechanism", "room-restored", "museum", "artefact-story", "expedition-journal", "journal-schemes"]

    static var key: String? {
        let process = ProcessInfo.processInfo
        let arguments = process.arguments
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
            return arguments[index + 1]
        }
        if let requested = value(after: "-ReviewScreen"), keys.contains(requested) { return requested }
        let environmentFlag = process.environment["APPSTORE_SCREENSHOTS"]?.lowercased() ?? ""
        let enabled = arguments.contains("-AppStoreScreenshots") || !["", "0", "false", "no"].contains(environmentFlag)
        guard enabled else { return nil }
        let rawIndex = value(after: "-AppStoreScreenshotScreen") ?? process.environment["APPSTORE_SCREENSHOT_SCREEN"] ?? "0"
        guard let index = Int(rawIndex), keys.indices.contains(index) else { return nil }
        return keys[index]
    }

    @MainActor static func makeStore(for key: String) -> GameStore {
        let store = GameStore(url: FileManager.default.temporaryDirectory.appendingPathComponent("ScarabVault-screenshot-demo.json"))
        store.screenshotMode = true
        store.loaded = true
        let completedCount = ["expedition-map", "museum"].contains(key) ? 3 :
            (["room-restored", "artefact-story", "expedition-journal", "journal-schemes"].contains(key) ? 1 : 0)
        for room in Archive.rooms.prefix(completedCount) {
            store.enter(room)
            // The first inscription is restored by one forward turn of cylinder 1.
            let moves = room.id == 0 ? [Turn(index: 0, direction: 1)] :
                (Engine.solution(from: room.start, to: room.target, rule: room.rule) ?? [])
            for move in moves {
                store.select(move.index, in: room)
                store.turn(move.direction, in: room)
            }
            _ = store.open(room)
        }
        if key == "mechanism" { store.enter(Archive.rooms[0]) }
        return store
    }
}
#endif
struct RouteScreen: View {
    let route: VaultRoute
    var body: some View {
        switch route {
        case .temple(let id): TempleView(temple: Archive.temples[id])
        case .room(let id): MechanismView(room: Archive.rooms[id])
        case .completion(let id): CompletionView(room: Archive.rooms[id])
        case .artefact(let id): ArtefactView(room: Archive.rooms[id])
        }
    }
}

@main
struct ScarabVaultApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store: GameStore
    init() {
        #if DEBUG && targetEnvironment(simulator)
        if let key = ScreenshotLaunch.key {
            _store = State(initialValue: ScreenshotLaunch.makeStore(for: key))
        } else {
            _store = State(initialValue: GameStore())
        }
        #else
        _store = State(initialValue: GameStore())
        #endif
    }
    var body: some Scene {
        WindowGroup {
            RegistrationRoot { pendingWidgetURL in
                #if DEBUG && targetEnvironment(simulator)
                if ScreenshotLaunch.key != nil {
                    RootView(pendingWidgetURL: pendingWidgetURL).environment(store).environment(\.locale, Locale(identifier: "en_GB")).preferredColorScheme(.dark).tint(Palette.gold)
                        .transaction { $0.animation = nil; $0.disablesAnimations = true }
                } else {
                    RootView(pendingWidgetURL: pendingWidgetURL).environment(store).environment(\.locale, Locale(identifier: "en_GB")).preferredColorScheme(.dark).tint(Palette.gold)
                }
                #else
                RootView(pendingWidgetURL: pendingWidgetURL).environment(store).environment(\.locale, Locale(identifier: "en_GB")).preferredColorScheme(.dark).tint(Palette.gold)
                #endif
            }
        }
    }
}

private struct RegistrationRoot<NativeContent: View>: View {
    @ViewBuilder let nativeContent: (Binding<URL?>) -> NativeContent
    @State private var pendingWidgetURL: URL?
    @State private var route: Route = .loading

    private enum Route {
        case loading, native, web(URL)
    }

    var body: some View {
        Group {
            switch route {
            case .loading:
                ProgressView().task { performRegistration() }
            case .native:
                nativeContent($pendingWidgetURL)
            case .web(let url):
                ZStack {
                    Color.black.ignoresSafeArea()
                    WebContentView(url: url.absoluteString)
                }
                .preferredColorScheme(.dark)
            }
        }
        .onOpenURL { url in
            guard WidgetIdentity.accepts(url) else { return }
            pendingWidgetURL = url
            route = .native
        }
    }

    private func performRegistration() {
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("-ReviewScreen") || ScreenshotLaunch.key != nil {
            route = .native
            return
        }
        #endif

        let pushToken = ""
        let advertisingId = ""
        let appsflyerId = ""

        NetworkService.shared.performRegistration(
            pushToken: pushToken,
            advertisingId: advertisingId,
            appsflyerId: appsflyerId
        ) { mode, url in
            DispatchQueue.main.async { finishLaunch(mode: mode, url: url) }
        }
    }

    private func finishLaunch(mode: DisplayMode, url: String?) {
        guard case .loading = route else { return }
        guard mode == .webContent else {
            route = .native
            return
        }
        guard let address = Self.webAddress(url) else {
            DataCache.shared.clearCache()
            route = .native
            return
        }
        route = .web(address)
    }

    private static func webAddress(_ raw: String?) -> URL? {
        guard let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        let candidate: String
        if value.hasPrefix("//") {
            candidate = "https:" + value
        } else if value.range(of: #"^[A-Za-z][A-Za-z0-9+.-]*://"#, options: .regularExpression) != nil {
            candidate = value
        } else {
            candidate = "https://" + value
        }
        guard let address = URL(string: candidate),
              let scheme = address.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = address.host, !host.isEmpty else { return nil }
        return address
    }
}

struct RootView: View {
    @Binding var pendingWidgetURL: URL?
    @Environment(GameStore.self) private var store
    @State private var tab = 0
    @State private var mapNavigator = VaultNavigator()
    @State private var museumNavigator = VaultNavigator()
    @State private var confirmNew = false
    init(pendingWidgetURL: Binding<URL?>) {
        _pendingWidgetURL = pendingWidgetURL
        #if DEBUG && targetEnvironment(simulator)
        if let key = ScreenshotLaunch.key {
            let mapPath: [VaultRoute]
            switch key {
            case "temple": mapPath = [.temple(0)]
            case "mechanism": mapPath = [.temple(0), .room(0)]
            case "room-restored": mapPath = [.temple(0), .room(0), .completion(0)]
            default: mapPath = []
            }
            _tab = State(initialValue: ["expedition-journal", "journal-schemes"].contains(key) ? 2 : (["museum", "artefact-story"].contains(key) ? 1 : 0))
            _mapNavigator = State(initialValue: VaultNavigator(path: mapPath))
            _museumNavigator = State(initialValue: VaultNavigator(path: key == "artefact-story" ? [.artefact(0)] : []))
        }
        #endif
    }
    var body: some View {
        Group {
            if !store.loaded {
                ZStack { StoneBackground(); VStack(spacing: 24) { ScarabMark().frame(width: 150, height: 100); ProgressView("Opening the expedition…") } }
            } else if store.readFailed {
                ZStack { StoneBackground(); VStack(spacing: 24) {
                    Image(systemName: "externaldrive.badge.exclamationmark").font(.largeTitle).foregroundStyle(Palette.gold)
                    Text("Your expedition is safe to retry").font(.title2.bold())
                    Text(store.storageError ?? "Please try again.").foregroundStyle(Palette.secondary)
                    Button("Retry loading") { store.load() }.buttonStyle(GoldButton())
                    Button("Restore previous save") { store.recoverBackup() }.frame(minHeight: 44)
                    Button("Start a new expedition", role: .destructive) { confirmNew = true }.frame(minHeight: 44)
                }.page() }
            } else {
                TabView(selection: $tab) {
                    NavigationStack(path: $mapNavigator.path) { MapView().navigationDestination(for: VaultRoute.self) { RouteScreen(route: $0) } }.environment(mapNavigator).tabItem { Label("Map", systemImage: "map") }.tag(0)
                    NavigationStack(path: $museumNavigator.path) { MuseumView().navigationDestination(for: VaultRoute.self) { RouteScreen(route: $0) } }.environment(museumNavigator).tabItem { Label("Museum", systemImage: "building.columns") }.tag(1)
                    NavigationStack { JournalView() }.tabItem { Label("Journal", systemImage: "book.closed") }.tag(2)
                }.environment(\.horizontalSizeClass, .compact)
                    .toolbarBackground(Palette.background, for: .tabBar).toolbarBackground(.visible, for: .tabBar)
                    .safeAreaInset(edge: .top) {
                        if let error = store.storageError {
                            HStack { Text(error).font(.caption); Button("Retry") { store.save() }.frame(minHeight: 44) }.padding(12).background(Palette.panel)
                        }
                    }
            }
        }.foregroundStyle(Palette.ink)
            .onChange(of: pendingWidgetURL, initial: true) { _, pending in
                guard let url = pending else { return }
                pendingWidgetURL = nil
                if !store.loaded { store.load() }
                guard !store.readFailed else { return }

                #if DEBUG && targetEnvironment(simulator)
                store.applyWidgetQA(url)
                #endif
                if store.progress.completed.count == 15 { tab = 1; museumNavigator.path = [] }
                else { tab = 0; mapNavigator.path = [.temple(store.nextRoom.temple), .room(store.nextRoom.id)] }
            }
            .task { if !store.loaded { await Task.yield(); store.load() } }
            .confirmationDialog("Start again? Existing progress on this device will be replaced.", isPresented: $confirmNew, titleVisibility: .visible) {
                Button("Start new expedition", role: .destructive) { store.newExpedition() }
            }
    }
}
struct MapView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(GameStore.self) private var store
    var body: some View {
        ZStack {
            StoneBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Eyebrow(text: "THE KEEPER’S EXPEDITION")
                        Spacer()
                        Image(systemName: "sun.max").foregroundStyle(Palette.gold)
                    }.padding(.top, 16)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scarab\nVault").vaultFont(44, weight: .medium, design: .serif).lineSpacing(-2)
                            Text("Some doors open only\nwhen you understand them.").vaultFont(15).foregroundStyle(Palette.secondary)
                        }
                        Spacer(minLength: 8)
                        if !typeSize.isAccessibilitySize { ScarabMark().frame(width: 132, height: 126).padding(.top, 16) }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Label("Seals \(store.seals)/5", systemImage: "seal").foregroundStyle(Palette.gold); Spacer(); Text("\(store.progress.completed.count) / 15 rooms").foregroundStyle(Palette.secondary) }.vaultFont(13, weight: .medium).monospacedDigit()
                        ProgressView(value: Double(store.progress.completed.count), total: 15).tint(Palette.gold)
                        NavigationLink(value: VaultRoute.room(store.nextRoom.id)) {
                            HStack { Text(store.seals == 5 ? "Return to the vault" : "Continue expedition"); Spacer(); Image(systemName: "arrow.right") }.padding(.horizontal, 16)
                        }.buttonStyle(GoldButton()).accessibilityIdentifier("resume")
                    }.panel()
                    HStack { Eyebrow(text: "THE RIVER PATH"); Rectangle().fill(Palette.gold.opacity(0.3)).frame(height: 1) }
                    VStack(spacing: 0) {
                        ForEach(Archive.temples) { temple in
                            let unlocked = store.progress.isUnlocked(temple.id)
                            let complete = temple.rooms.allSatisfy { store.progress.completed[$0.id] != nil }
                            NavigationLink(value: VaultRoute.temple(temple.id)) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12).fill(unlocked ? Palette.gold.opacity(0.15) : Palette.stone.opacity(0.1)).frame(width: 56, height: 64)
                                        Image(systemName: complete ? "checkmark.seal.fill" : (unlocked ? "building.columns.fill" : "lock.fill")).vaultFont(24).foregroundStyle(unlocked ? Palette.gold : Palette.secondary.opacity(0.5))
                                    }
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("TEMPLE \(temple.id + 1) • \(complete ? "SEALED" : (unlocked ? "EXPLORE" : "UNDISCOVERED"))").vaultFont(11, weight: .semibold).tracking(1.2).foregroundStyle(complete ? Palette.glow : Palette.secondary)
                                        Text(temple.title).vaultFont(21, weight: .medium, design: .serif).foregroundStyle(Palette.ink)
                                        Text(unlocked ? "\(temple.rooms.filter { store.progress.completed[$0.id] != nil }.count) of 3 rooms restored" : "Complete Temple \(temple.id) to enter").vaultFont(13).foregroundStyle(Palette.secondary)
                                    }
                                    Spacer(minLength: 0)
                                    if unlocked { Image(systemName: "chevron.right").foregroundStyle(Palette.gold).font(.caption) }
                                }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(unlocked ? Palette.panel.opacity(0.75) : Palette.background, in: RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(unlocked ? Palette.gold.opacity(0.4) : Palette.stone.opacity(0.18)))
                            }.disabled(!unlocked).accessibilityIdentifier("temple-\(temple.id)")
                            if temple.id < 4 { HStack { Rectangle().fill(Palette.gold.opacity(0.3)).frame(width: 1, height: 24).padding(.leading, 44); Spacer() }.accessibilityHidden(true) }
                        }
                    }
                    Label("An offline expedition • saved on this device", systemImage: "checkmark.shield").vaultFont(12).foregroundStyle(Palette.secondary).frame(maxWidth: .infinity)
                }.page()
            }
        }.toolbar(.hidden, for: .navigationBar)
    }
}
struct TempleView: View {
    @Environment(GameStore.self) private var store
    let temple: Temple
    var next: Room { temple.rooms.first { store.progress.completed[$0.id] == nil } ?? temple.rooms[0] }
    var body: some View {
        ZStack { StoneBackground(); ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TempleArt(chapter: temple.id)
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "CHAPTER \(temple.id + 1) • \(temple.subtitle)")
                    Text(temple.title).vaultFont(32, weight: .medium, design: .serif)
                    Text(temple.story).vaultFont(16).lineSpacing(5).foregroundStyle(Palette.secondary)
                }
                NavigationLink(value: VaultRoute.room(next.id)) { Text("Continue exploration") }.buttonStyle(GoldButton()).accessibilityIdentifier("explore")
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "THE CHAMBERS")
                    ForEach(temple.rooms) { room in
                        NavigationLink(value: VaultRoute.room(room.id)) {
                            HStack(spacing: 16) {
                                Text(String(format: "%02d", room.number + 1)).font(.title2.monospacedDigit()).foregroundStyle(Palette.gold)
                                VStack(alignment: .leading, spacing: 4) { Text(room.title).foregroundStyle(Palette.ink); Text(store.progress.completed[room.id] != nil ? "Restored • revisit" : room.rule.title).font(.caption).foregroundStyle(Palette.secondary) }
                                Spacer()
                                Image(systemName: store.progress.completed[room.id] != nil ? "checkmark.seal.fill" : (store.progress.roomUnlocked(room) ? "chevron.right" : "lock")).foregroundStyle(Palette.gold)
                            }.panel()
                        }.disabled(!store.progress.roomUnlocked(room))
                    }
                }
            }.page()
        }}.navigationTitle("Temple \(temple.id + 1)").navigationBarTitleDisplayMode(.inline)
    }
}
