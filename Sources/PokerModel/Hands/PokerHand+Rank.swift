import Foundation

extension PokerHand {
    public enum Rank: Hashable, Codable, Sendable {
        case highCard(HighCard)
        case onePair(Pair)
        case twoPair(TwoPair)
        case threeOfAKind(ThreeOfAKind)
        case straight(Straight)
        case flush(Flush)
        case fullHouse(FullHouse)
        case fourOfAKind(FourOfAKind)
        case straightFlush(StraightFlush)

        public var rankLevel: Int {
            switch self {
            case .highCard: 0 case .onePair: 1 case .twoPair: 2
            case .threeOfAKind: 3 case .straight: 4 case .flush: 5
            case .fullHouse: 6 case .fourOfAKind: 7 case .straightFlush: 8
            }
        }

        public var displayName: String {
            switch self {
            case .highCard(let h): "\(h.cards.max(by: { $0.rank < $1.rank })!.rank.longDisplayValue) High"
            case .onePair: "Pair"
            case .twoPair: "Two Pair"
            case .threeOfAKind: "Three of a Kind"
            case .straight: "Straight"
            case .flush: "Flush"
            case .fullHouse: "Full House"
            case .fourOfAKind: "Four of a Kind"
            case .straightFlush(let sf): sf.highCard.rank == .ace ? "Royal Flush" : "Straight Flush"
            }
        }

        public static func > (lhs: Rank, rhs: Rank) -> Bool? {
            if lhs.rankLevel > rhs.rankLevel { return true }
            if lhs.rankLevel < rhs.rankLevel { return false }
            switch (lhs, rhs) {
            case let (.highCard(l), .highCard(r)):
                return l.cards > r.cards
            case let (.onePair(l), .onePair(r)):
                if let g: Bool = l.pairCard > r.pairCard { return g }
                return l.remainder > r.remainder
            case let (.twoPair(l), .twoPair(r)):
                if let g: Bool = l.higher > r.higher { return g }
                if let g: Bool = l.lower > r.lower { return g }
                return [l.remainder] > [r.remainder]
            case let (.threeOfAKind(l), .threeOfAKind(r)):
                if let g: Bool = l.threeOfAKind > r.threeOfAKind { return g }
                return l.remainder > r.remainder
            case let (.straight(l), .straight(r)):
                return l.highCard > r.highCard
            case let (.flush(l), .flush(r)):
                return l.cards > r.cards
            case let (.fullHouse(l), .fullHouse(r)):
                if let g: Bool = l.threeOfAKind > r.threeOfAKind { return g }
                return l.remainingPair > r.remainingPair
            case let (.fourOfAKind(l), .fourOfAKind(r)):
                if let g: Bool = l.fourOfAKind > r.fourOfAKind { return g }
                return l.remainder > r.remainder
            case let (.straightFlush(l), .straightFlush(r)):
                return l.highCard > r.highCard
            default:
                return nil
            }
        }
    }
}
