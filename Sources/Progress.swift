import Foundation
import SwiftUI

struct Attempt: Codable, Equatable {
    var board: [Int]
    var selected = 0
    var moves = 0
    var hints = 0
}
struct Record: Codable, Equatable {
    let moves: Int
    let hints: Int
    let date: Date
}
struct Expedition: Codable, Equatable {
    var version = 1
    var attempts: [Int: Attempt] = [:]
    var completed: [Int: Record] = [:]
    var visited: Set<Int> = [0]
    var lastRoom = 0
    func isUnlocked(_ temple: Int) -> Bool {
        temple == 0 || Archive.temples[temple - 1].rooms.allSatisfy { completed[$0.id] != nil }
    }
    func roomUnlocked(_ room: Room) -> Bool {
        isUnlocked(room.temple) && (room.number == 0 || completed[room.id - 1] != nil)
    }
    func validated() throws -> Expedition {
        guard version == 1, (0..<15).contains(lastRoom), visited.allSatisfy({ (0..<5).contains($0) }),
              completed.keys.allSatisfy({ (0..<15).contains($0) }),
              completed.values.allSatisfy({ $0.moves >= 0 && (0...3).contains($0.hints) }) else { throw SaveError.invalid }
        for (id, attempt) in attempts {
            guard (0..<15).contains(id), attempt.board.count == Archive.rooms[id].start.count,
                  attempt.board.allSatisfy({ (0..<6).contains($0) }), attempt.board.indices.contains(attempt.selected),
                  attempt.moves >= 0, (0...3).contains(attempt.hints) else { throw SaveError.invalid }
        }
        return self
    }
}
enum SaveError: Error { case invalid }
struct SaveFile {
    let url: URL
    func read() throws -> Expedition {
        guard FileManager.default.fileExists(atPath: url.path) else { return Expedition() }
        return try JSONDecoder().decode(Expedition.self, from: Data(contentsOf: url)).validated()
    }
    func write(_ expedition: Expedition) throws {
        _ = try expedition.validated()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let valid = try? read(), FileManager.default.fileExists(atPath: url.path) {
            try JSONEncoder().encode(valid).write(to: url.appendingPathExtension("backup"), options: .atomic)
        }
        try JSONEncoder().encode(expedition).write(to: url, options: .atomic)
    }
}

@MainActor @Observable final class GameStore {
    var progress = Expedition()
    var loaded = false
    var storageError: String?
    var readFailed = false
    #if DEBUG && targetEnvironment(simulator)
    var screenshotMode = false
    #endif
    let saveFile: SaveFile
    init(url: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        #if DEBUG
        let testRun = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        let name = testRun ? "UITest-expedition.json" : "expedition.json"
        #else
        let name = "expedition.json"
        #endif
        saveFile = SaveFile(url: url ?? base.appendingPathComponent("ScarabVault/\(name)"))
        #if DEBUG
        #if targetEnvironment(simulator)
        if ScreenshotLaunch.key == nil && testRun && ProcessInfo.processInfo.arguments.contains("--reset-progress") {
            try? FileManager.default.removeItem(at: saveFile.url)
        }
        #else
        if testRun && ProcessInfo.processInfo.arguments.contains("--reset-progress") {
            try? FileManager.default.removeItem(at: saveFile.url)
        }
        #endif
        #endif
    }
    func load() {
        do { progress = try saveFile.read(); storageError = nil; readFailed = false }
        catch { storageError = "Your saved expedition could not be read. Retry, restore the previous save, or start a new expedition."; readFailed = true }
        loaded = true
        if !readFailed { publishWidget() }
    }
    func save() {
        #if DEBUG && targetEnvironment(simulator)
        if screenshotMode { return }
        #endif
        guard !readFailed else { return }
        do { try saveFile.write(progress); storageError = nil; publishWidget() }
        catch { storageError = "Your latest changes could not be saved. Keep the app open and retry saving." }
    }
    func recoverBackup() {
        do {
            progress = try SaveFile(url: saveFile.url.appendingPathExtension("backup")).readExisting()
            readFailed = false; save()
        } catch { storageError = "No readable previous save was found. Your existing files have been kept." }
    }
    func newExpedition() { readFailed = false; progress = Expedition(); save() }
    func attempt(_ room: Room) -> Attempt { progress.attempts[room.id] ?? Attempt(board: room.start) }
    func enter(_ room: Room) {
        guard progress.roomUnlocked(room) else { return }
        progress.lastRoom = room.id; progress.visited.insert(room.temple)
        if progress.attempts[room.id] == nil { progress.attempts[room.id] = Attempt(board: room.start) }
        save()
    }
    func select(_ index: Int, in room: Room) { var a = attempt(room); a.selected = index; progress.attempts[room.id] = a; save() }
    func turn(_ direction: Int, in room: Room) {
        var a = attempt(room)
        a.board = Engine.apply(Turn(index: a.selected, direction: direction), to: a.board, rule: room.rule)
        a.moves += 1; progress.attempts[room.id] = a; save()
    }
    func reset(_ room: Room) { progress.attempts[room.id] = Attempt(board: room.start); save() }
    func hint(_ room: Room) { var a = attempt(room); a.hints = min(3, a.hints + 1); progress.attempts[room.id] = a; save() }
    func open(_ room: Room) -> Bool {
        let a = attempt(room)
        guard a.board == room.target else { return false }
        if progress.completed[room.id] == nil { progress.completed[room.id] = Record(moves: a.moves, hints: a.hints, date: Date()) }
        save(); return true
    }
    var nextRoom: Room { Archive.rooms.first { progress.completed[$0.id] == nil } ?? Archive.rooms[14] }
    var seals: Int { Archive.temples.filter { t in t.rooms.allSatisfy { progress.completed[$0.id] != nil } }.count }
}
extension SaveFile {
    func readExisting() throws -> Expedition {
        guard FileManager.default.fileExists(atPath: url.path) else { throw SaveError.invalid }
        return try read()
    }
}
