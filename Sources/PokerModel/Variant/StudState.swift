import Foundation

public struct StudState: Equatable, Codable, Sendable {
    public var playerCards: [PlayerID: StudPlayerCards]
    public var deck: [CardID]
    public var currentStreetIndex: Int

    public init(
        playerCards: [PlayerID: StudPlayerCards],
        deck: [CardID],
        currentStreetIndex: Int = 0
    ) {
        self.playerCards = playerCards
        self.deck = deck
        self.currentStreetIndex = currentStreetIndex
    }
}

public struct StudPlayerCards: Equatable, Codable, Sendable {
    public var downCards: [CardID]
    public var upCards: [CardID]

    public var allCardIDs: [CardID] { downCards + upCards }

    public init(downCards: [CardID] = [], upCards: [CardID] = []) {
        self.downCards = downCards
        self.upCards = upCards
    }
}
