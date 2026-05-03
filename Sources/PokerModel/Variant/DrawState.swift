import Foundation

public struct DrawState: Equatable, Codable, Sendable {
    public var playerCards: [PlayerID: [CardID]]
    public var deck: [CardID]
    public var drawComplete: Bool
    public var pendingDrawPlayerIDs: [PlayerID]

    public init(
        playerCards: [PlayerID: [CardID]],
        deck: [CardID],
        drawComplete: Bool = false,
        pendingDrawPlayerIDs: [PlayerID] = []
    ) {
        self.playerCards = playerCards
        self.deck = deck
        self.drawComplete = drawComplete
        self.pendingDrawPlayerIDs = pendingDrawPlayerIDs
    }
}
