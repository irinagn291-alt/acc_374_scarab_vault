import Foundation

enum Glyph: Int, CaseIterable, Codable, Sendable {
    case scarab, sun, eye, lotus, falcon, wave
    var title: String { ["Scarab", "Sun", "Eye", "Lotus", "Falcon", "Wave"][rawValue] }
    var icon: String { ["ladybug.fill", "sun.max.fill", "eye.fill", "camera.macro", "bird.fill", "water.waves"][rawValue] }
    var meaning: String { ["Renewal • the keeper of beginnings", "Light • the first mark of morning", "Wisdom • a witness in the stone", "Balance • a flower above still water", "Passage • the guardian of the sky", "Memory • a river that remembers"][rawValue] }
}

enum Rule: Int, Codable, CaseIterable, Sendable {
    case solitary, neighbour, mirror, counterweight, cascade
    var title: String { ["Single stones", "Linked stones", "Mirror stones", "Counterweights", "The great cascade"][rawValue] }
    var explanation: String { [
        "Each cylinder turns alone. Match the carved sequence from left to right.",
        "Turning a cylinder also turns the next one to its right. The last cylinder turns alone.",
        "A cylinder and its reflected partner turn together. The middle cylinder turns alone.",
        "Turning a cylinder turns the next one to its right in the opposite direction. The last turns alone.",
        "Turning a cylinder turns every cylinder to its right as well. Work from left to right."
    ][rawValue] }
    var thought: String { [
        "Read the inscription like a sentence. Which stone differs from the mark above it?",
        "Watch the seam to the right. A single turn can move two stones.",
        "Imagine a line through the centre. The outer stones share a hidden axle.",
        "Two weights hang from the same rope. As one rises, the other falls.",
        "A turn travels towards the far end. Set the first stone before the next."
    ][rawValue] }
}

struct Turn: Equatable, Sendable {
    let index: Int
    let direction: Int
}

struct Room: Identifiable, Sendable {
    let id: Int
    let temple: Int
    let number: Int
    let title: String
    let rule: Rule
    let target: [Int]
    let start: [Int]
    let artefact: String
    let lore: String
    var inscription: String { number == 2 ? "Two shores reflect one sky. Restore the mirrored inscription." : "Match the symbols from left to right." }
}

struct Temple: Identifiable, Sendable {
    let id: Int
    let title: String
    let subtitle: String
    let story: String
    var rooms: [Room] { Archive.rooms.filter { $0.temple == id } }
}

enum Archive {
    static let temples: [Temple] = [
        Temple(id: 0, title: "The Sunken Gate", subtitle: "WHERE THE RIVER BEGINS", story: "Beneath the river silt, a doorway still holds the warmth of dawn. Three inscriptions wait for a patient hand."),
        Temple(id: 1, title: "House of Reeds", subtitle: "EVERY STONE HAS A NEIGHBOUR", story: "Roots wind through the walls like ropes. Behind the carvings, bronze axles bind one stone to the next."),
        Temple(id: 2, title: "The Mirror Court", subtitle: "AS ABOVE, SO BELOW", story: "A dry pool reflects nothing, yet the stones remember symmetry. What moves on one shore stirs the other."),
        Temple(id: 3, title: "Tomb of the Tides", subtitle: "ONE RISES, ONE FALLS", story: "Hidden counterweights once measured the river. Balance their opposing motion to reveal the keeper’s chamber."),
        Temple(id: 4, title: "Vault of the Dawn", subtitle: "ALL PATHS MEET THE SUN", story: "Five cylinders share one ancient spine. Let each movement settle in order, and the expedition’s final door will open.")
    ]
    static let artefacts = ["Dawn Scarab", "River Compass", "Lotus Seal", "Reed Pendant", "Bronze Axle", "Keeper’s Tablet", "Twin Falcons", "Stillwater Lens", "Mirror Diadem", "Tide Vessel", "Balance Feather", "Moon Sundial", "Golden Spine", "Sun Cartouche", "Heart of the Vault"]
    static let lores = [
        "A small stone beetle, polished by generations of careful hands. Its wings carry the first line of the expedition’s map.",
        "This compass has no needle. Six carved channels once pointed travellers towards the river at different seasons.",
        "A lotus pressed into warm clay marked the safe return of a keeper. The last impression is still visible beneath its rim.",
        "Seven reeds are tied in bronze. The inscription reads: no stem stands alone against the flood.",
        "A palm-sized model of the temple’s linked mechanism, made for the apprentice who would one day tend it.",
        "The tablet records repairs instead of kings. A nameless craftsperson kept these gates moving for forty summers.",
        "Two falcons share a single wing. Seen in water, their silhouettes form an unbroken circle.",
        "A disc of smoky quartz that softens every sharp edge. It was laid above the mirror court on the longest day.",
        "One half is bright, one half is weathered. Neither was restored: the keeper believed both told the truth.",
        "Fine lines inside this vessel record the height of a vanished river. A blue bead rests at the highest mark.",
        "A bronze feather balances a stone many times its size. Its maker understood leverage as well as beauty.",
        "Tiny silver dots trace moonlight across the dial. It measured the quiet hours when the temple gates were closed.",
        "Five small wheels turn on one golden rod. This teaching model explains the great cascade with a single touch.",
        "The name within the frame has worn away. A small sun remains, as if the maker wanted the light to outlast the name.",
        "A turquoise heart rests inside a carved scarab. The final inscription reads: what you understand, you carry with you."
    ]
    static let rooms: [Room] = (0..<15).map { id in
        let temple = id / 3, number = id % 3
        let rule = Rule(rawValue: temple)!
        let count = temple >= 3 ? 5 : 3
        let target = number == 2 ? (count == 3 ? [3, 1, 3] : [4, 3, 1, 3, 4]) : (0..<count).map { ($0 + id) % 6 }
        var start = target
        // Authored deterministic scramble by legal moves guarantees reachability.
        let scramble = [Turn(index: 0, direction: -1), Turn(index: rule == .mirror ? 1 : count - 1, direction: 1), Turn(index: rule == .mirror ? 0 : 1, direction: -1)]
        for move in scramble.prefix(number + 1) { start = Engine.apply(move, to: start, rule: rule) }
        return Room(id: id, temple: temple, number: number, title: ["The first inscription", "The keeper’s passage", "The reflecting chamber"][number], rule: rule, target: target, start: start, artefact: artefacts[id], lore: lores[id])
    }
}

enum Engine {
    static func apply(_ turn: Turn, to board: [Int], rule: Rule) -> [Int] {
        guard board.indices.contains(turn.index), abs(turn.direction) == 1 else { return board }
        var result = board
        func change(_ index: Int, _ direction: Int) { result[index] = (result[index] + direction + 6) % 6 }
        change(turn.index, turn.direction)
        switch rule {
        case .solitary: break
        case .neighbour, .counterweight:
            if turn.index + 1 < board.count { change(turn.index + 1, rule == .counterweight ? -turn.direction : turn.direction) }
        case .mirror:
            let partner = board.count - 1 - turn.index
            if partner != turn.index { change(partner, turn.direction) }
        case .cascade:
            for index in (turn.index + 1)..<board.count { change(index, turn.direction) }
        }
        return result
    }
    static func solution(from start: [Int], to target: [Int], rule: Rule) -> [Turn]? {
        guard start.count == target.count, !start.isEmpty else { return nil }
        if start == target { return [] }
        var queue = [start], cursor = 0
        var parents: [[Int]: ([Int], Turn)] = [:]
        var visited: Set<[Int]> = [start]
        while cursor < queue.count {
            let current = queue[cursor]; cursor += 1
            for index in current.indices {
                for direction in [1, -1] {
                    let turn = Turn(index: index, direction: direction)
                    let next = apply(turn, to: current, rule: rule)
                    guard visited.insert(next).inserted else { continue }
                    parents[next] = (current, turn)
                    if next == target {
                        var path: [Turn] = [], node = next
                        while let (previous, move) = parents[node] { path.append(move); node = previous }
                        return path.reversed()
                    }
                    queue.append(next)
                }
            }
        }
        return nil
    }
}
