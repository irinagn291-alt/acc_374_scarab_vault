import XCTest
@testable import ScarabVault

final class PuzzleTests: XCTestCase {
    func testEveryRoomHasDeterministicSolution() throws {
        XCTAssertEqual(Archive.rooms.count, 15)
        XCTAssertEqual(Set(Archive.rooms.map(\.artefact)).count, 15)
        for room in Archive.rooms {
            XCTAssertNotEqual(room.start, room.target)
            let solution = try XCTUnwrap(Engine.solution(from: room.start, to: room.target, rule: room.rule))
            XCTAssertFalse(solution.isEmpty)
            XCTAssertEqual(solution, Engine.solution(from: room.start, to: room.target, rule: room.rule))
            let result = solution.reduce(room.start) { Engine.apply($1, to: $0, rule: room.rule) }
            XCTAssertEqual(result, room.target, "Room \(room.id)")
        }
    }
    func testEveryMoveIsReversible() {
        for room in Archive.rooms {
            for index in room.start.indices {
                let forward = Engine.apply(Turn(index: index, direction: 1), to: room.start, rule: room.rule)
                XCTAssertEqual(Engine.apply(Turn(index: index, direction: -1), to: forward, rule: room.rule), room.start)
            }
        }
    }
    func testCouplingRules() {
        let board = [0, 0, 0, 0, 0], turn = Turn(index: 1, direction: 1)
        XCTAssertEqual(Engine.apply(turn, to: board, rule: .solitary), [0, 1, 0, 0, 0])
        XCTAssertEqual(Engine.apply(turn, to: board, rule: .neighbour), [0, 1, 1, 0, 0])
        XCTAssertEqual(Engine.apply(turn, to: board, rule: .mirror), [0, 1, 0, 1, 0])
        XCTAssertEqual(Engine.apply(turn, to: board, rule: .counterweight), [0, 1, 5, 0, 0])
        XCTAssertEqual(Engine.apply(turn, to: board, rule: .cascade), [0, 1, 1, 1, 1])
        XCTAssertEqual(Engine.apply(Turn(index: 2, direction: 1), to: board, rule: .mirror), [0, 0, 1, 0, 0])
    }
    func testHintRemainsValidAfterDetour() throws {
        for room in Archive.rooms {
            let detour = Engine.apply(Turn(index: 0, direction: 1), to: room.start, rule: room.rule)
            let path = try XCTUnwrap(Engine.solution(from: detour, to: room.target, rule: room.rule))
            XCTAssertEqual(path.reduce(detour) { Engine.apply($1, to: $0, rule: room.rule) }, room.target)
        }
    }
    func testSaveRoundtripAndCorruption() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = SaveFile(url: root.appendingPathComponent("progress.json"))
        var state = Expedition()
        state.attempts[0] = Attempt(board: [1, 2, 3], selected: 1, moves: 8, hints: 2)
        try file.write(state)
        XCTAssertEqual(try file.read(), state)
        state.lastRoom = 1
        try file.write(state)
        XCTAssertEqual(try file.read().lastRoom, 1)
        XCTAssertEqual(try SaveFile(url: file.url.appendingPathExtension("backup")).read().lastRoom, 0)
        try Data("bad-json".utf8).write(to: file.url)
        XCTAssertThrowsError(try file.read())
        var invalid = Expedition(); invalid.attempts[0] = Attempt(board: [99])
        XCTAssertThrowsError(try file.write(invalid))
    }
    @MainActor func testUnlockRewardsAndPersistence() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("state.json")
        let store = GameStore(url: url); store.load()
        XCTAssertFalse(store.progress.isUnlocked(1))
        XCTAssertFalse(store.open(Archive.rooms[0]))
        for room in Archive.rooms {
            XCTAssertTrue(store.progress.roomUnlocked(room))
            store.enter(room)
            let path = try XCTUnwrap(Engine.solution(from: store.attempt(room).board, to: room.target, rule: room.rule))
            for move in path { store.select(move.index, in: room); store.turn(move.direction, in: room) }
            XCTAssertTrue(store.open(room))
            let record = store.progress.completed[room.id]
            XCTAssertTrue(store.open(room))
            XCTAssertEqual(record, store.progress.completed[room.id])
        }
        XCTAssertEqual(store.seals, 5)
        XCTAssertEqual(store.progress.completed.count, 15)
        let restored = GameStore(url: url); restored.load()
        XCTAssertEqual(restored.progress, store.progress)
        store.reset(Archive.rooms[0])
        XCTAssertEqual(store.progress.completed.count, 15)
    }
    @MainActor func testUnfinishedRoomSurvivesRestart() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("state.json")
        let store = GameStore(url: url); store.load(); store.enter(Archive.rooms[0]); store.select(2, in: Archive.rooms[0]); store.turn(-1, in: Archive.rooms[0]); store.hint(Archive.rooms[0])
        let restored = GameStore(url: url); restored.load()
        XCTAssertEqual(restored.attempt(Archive.rooms[0]), store.attempt(Archive.rooms[0]))
        XCTAssertEqual(restored.attempt(Archive.rooms[0]).selected, 2)
    }
    @MainActor func testUnreadableSaveCanRestoreBackupWithoutSilentReset() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("state.json")
        let original = GameStore(url: url); original.load(); original.enter(Archive.rooms[0])
        original.turn(1, in: Archive.rooms[0]); original.hint(Archive.rooms[0])
        let backup = try SaveFile(url: url.appendingPathExtension("backup")).read()
        let damaged = Data("unreadable-save".utf8)
        try damaged.write(to: url)
        let restored = GameStore(url: url); restored.load()
        XCTAssertTrue(restored.readFailed)
        XCTAssertNotNil(restored.storageError)
        restored.save()
        XCTAssertEqual(try Data(contentsOf: url), damaged)
        restored.recoverBackup()
        XCTAssertFalse(restored.readFailed)
        XCTAssertNil(restored.storageError)
        XCTAssertEqual(restored.progress, backup)
        XCTAssertEqual(try restored.saveFile.read(), backup)
    }

}
