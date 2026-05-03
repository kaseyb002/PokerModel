import Foundation

public struct Pot: Hashable, Identifiable, Codable, Sendable {
    public let id: String
    public var amount: Decimal
    public var isFull: Bool = false
    public let playerIds: Set<PlayerID>

    public init(
        id: String = UUID().uuidString,
        amount: Decimal = .zero,
        playerIds: Set<PlayerID>,
        isFull: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.playerIds = playerIds
        self.isFull = isFull
    }
}

extension [Pot] {
    public func debugDescription(playerNameByID: (_ id: PlayerID) -> String) -> String {
        var desc: String = "----Pots----"
        for (index, pot) in enumerated() {
            desc += "\nPot \(index + 1): \(pot.amount.moneyString)"
            desc += "\nPlayers: \(pot.playerIds.map { playerNameByID($0) }.sorted().joined(separator: ", "))"
        }
        return desc
    }
}
