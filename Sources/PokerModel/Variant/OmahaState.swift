import Foundation

public struct OmahaState: Equatable, Codable, Sendable {
    public let holeCards: [PlayerID: [CardID]]
    public let board: [CardID]
    public var revealedBoardCount: Int

    public var visibleBoardIDs: [CardID] {
        Array(board.prefix(revealedBoardCount))
    }

    public init(holeCards: [PlayerID: [CardID]], board: [CardID], revealedBoardCount: Int = 0) {
        self.holeCards = holeCards
        self.board = board
        self.revealedBoardCount = revealedBoardCount
    }
}
