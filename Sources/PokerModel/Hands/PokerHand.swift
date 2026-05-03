import Foundation

public struct PokerHand: Hashable, Codable, Sendable {
    public let cards: [Card]
    public let topRank: Rank
    public let description: String

    public init(cards unsortedCards: [Card]) throws {
        guard unsortedCards.count == 5 else { throw PokerHandError.not5Cards }
        let cards: [Card] = unsortedCards.sorted()

        let highCard: HighCard = .init(cards: cards)
        var topRank: Rank = .highCard(highCard)

        if let pair: Pair = .init(cards: cards) { topRank = .onePair(pair) }
        if let twoPair: TwoPair = .init(cards: cards) { topRank = .twoPair(twoPair) }
        if let threeOfAKind: ThreeOfAKind = .init(cards: cards) { topRank = .threeOfAKind(threeOfAKind) }
        if let straight: Straight = .init(cards: cards) { topRank = .straight(straight) }
        if let flush: Flush = .init(cards: cards) { topRank = .flush(flush) }
        if let fullHouse: FullHouse = .init(cards: cards) { topRank = .fullHouse(fullHouse) }
        if let fourOfAKind: FourOfAKind = .init(cards: cards) { topRank = .fourOfAKind(fourOfAKind) }
        if let straightFlush: StraightFlush = .init(cards: cards) { topRank = .straightFlush(straightFlush) }

        self.cards = cards
        self.topRank = topRank
        self.description = topRank.displayName + ": " + cards.debugDescription
    }
}

public enum PokerHandError: Error, Sendable {
    case not5Cards
}
