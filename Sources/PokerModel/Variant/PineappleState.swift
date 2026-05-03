import Foundation

public struct PineappleState: Equatable, Codable, Sendable {
    public var holeCards: [PlayerID: [CardID]]
    public let board: [CardID]
    public var revealedBoardCount: Int
    public var discardedCards: [PlayerID: CardID]
    public var pendingDiscardPlayerIDs: [PlayerID]

    public var visibleBoardIDs: [CardID] {
        Array(board.prefix(revealedBoardCount))
    }

    public init(
        holeCards: [PlayerID: [CardID]],
        board: [CardID],
        revealedBoardCount: Int = 0,
        discardedCards: [PlayerID: CardID] = [:],
        pendingDiscardPlayerIDs: [PlayerID] = []
    ) {
        self.holeCards = holeCards
        self.board = board
        self.revealedBoardCount = revealedBoardCount
        self.discardedCards = discardedCards
        self.pendingDiscardPlayerIDs = pendingDiscardPlayerIDs
    }
}
