import Foundation

public struct RoundPlayer: Equatable, Codable, Sendable {
    public var player: Player
    public let startingChipCount: Decimal
    public var currentBet: Decimal = .zero
    public var hasActedThisStreet: Bool = false
    public var status: Status

    public var isAllIn: Bool { player.chipCount == .zero && status == .in }

    public enum Status: String, Equatable, Codable, Sendable {
        case `in`, out
    }

    public init(
        player: Player,
        currentBet: Decimal = .zero,
        hasActedThisStreet: Bool = false,
        status: Status = .in
    ) {
        self.player = player
        self.startingChipCount = player.chipCount
        self.currentBet = currentBet
        self.hasActedThisStreet = hasActedThisStreet
        self.status = status
    }
}
