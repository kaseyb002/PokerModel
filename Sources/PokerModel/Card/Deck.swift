import Foundation

public struct Deck: Hashable, Codable, Sendable {
    public var cards: [Card]

    public mutating func shuffle() {
        cards.shuffle()
    }

    public init() {
        var cards: [Card] = []
        for suit in Card.Suit.allCases {
            for rank in Card.Rank.allCases {
                cards.append(.init(rank: rank, suit: suit))
            }
        }
        self.cards = cards
    }

    public init(cards: [Card]) {
        self.cards = cards
    }

    @discardableResult
    public mutating func deal() -> Card {
        cards.removeLast()
    }

    public mutating func deal(_ count: Int) -> [Card] {
        var dealt: [Card] = []
        for _ in 0..<count { dealt.append(cards.removeLast()) }
        return dealt
    }
}
