import Foundation

public struct WinningHand: Hashable, Codable, Sendable {
    public let playerID: PlayerID
    public let pokerHand: PokerHand

    public enum CodingKeys: String, CodingKey {
        case playerID = "playerId"
        case pokerHand
    }

    public init(playerID: PlayerID, pokerHand: PokerHand) {
        self.playerID = playerID
        self.pokerHand = pokerHand
    }
}

public struct LowWinningHand: Hashable, Codable, Sendable {
    public let playerID: PlayerID
    public let lowHand: LowHand

    public enum CodingKeys: String, CodingKey {
        case playerID = "playerId"
        case lowHand
    }

    public init(playerID: PlayerID, lowHand: LowHand) {
        self.playerID = playerID
        self.lowHand = lowHand
    }
}

public struct PotResult: Hashable, Codable, Sendable {
    public let pot: Pot
    public let highWinners: Set<WinningHand>
    public let lowWinners: Set<LowWinningHand>

    public init(
        pot: Pot,
        highWinners: Set<WinningHand>,
        lowWinners: Set<LowWinningHand> = []
    ) {
        self.pot = pot
        self.highWinners = highWinners
        self.lowWinners = lowWinners
    }
}
