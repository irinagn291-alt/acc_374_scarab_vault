import Foundation

extension GameStore {
    var widgetSnapshot: WidgetSnapshot {
        let room = nextRoom
        return WidgetSnapshot(title: Archive.temples[room.temple].title, value: "\(progress.completed.count) / 15", label: "artefacts recovered",
            detail: progress.completed.count == 15 ? "Expedition complete · explore your museum" : "Next: \(room.title)",
            footnote: "\(seals) of 5 temple seals", progress: Double(progress.completed.count)/15,
            symbols: room.target.prefix(3).map { Glyph(rawValue:$0)?.icon ?? "ladybug.fill" })
    }
    func publishWidget() { WidgetStore.publish(widgetSnapshot) }
}

#if DEBUG && targetEnvironment(simulator)
extension GameStore {
    /// Only explicit UI-test launches in disposable simulators can mutate this fixture.
    func applyWidgetQA(_ url: URL) {
        guard ProcessInfo.processInfo.arguments.contains("-WidgetQA"),
              URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "qa" && ["1", "2"].contains($0.value ?? "") }) == true else { return }
        let secondUpdate = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "qa" && $0.value == "2" }) == true
        let room = Archive.rooms[secondUpdate ? 1 : 0]
        enter(room)
        for move in Engine.solution(from: attempt(room).board, to: room.target, rule: room.rule) ?? [] {
            select(move.index, in: room); turn(move.direction, in: room)
        }
        _ = open(room)
    }
}
#endif
