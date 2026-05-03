import Foundation

extension PokerHand {
    public struct HighCard: Hashable, Codable, Sendable {
        public let cards: [Card]
        init(cards: [Card]) { self.cards = cards.sorted(by: { $0.rank > $1.rank }) }
    }

    public struct Pair: Hashable, Codable, Sendable {
        public let pairCard: Card
        public let remainder: [Card]
        init?(cards: [Card]) {
            guard let pair: Card = cards.kind(of: 2) else { return nil }
            self.pairCard = pair
            let rem: [Card] = cards.filter { $0.rank != pair.rank }.sorted(by: { $0.rank > $1.rank })
            guard Set(rem.map { $0.rank }).count == 3 else { return nil }
            self.remainder = rem
        }
    }

    public struct TwoPair: Hashable, Codable, Sendable {
        public let higher: Card
        public let lower: Card
        public let remainder: Card
        init?(cards unsorted: [Card]) {
            let cards: [Card] = unsorted.sorted(by: { $0.rank > $1.rank })
            guard let higher: Card = cards.kind(of: 2),
                  let lower: Card = cards.reversed().kind(of: 2),
                  lower.rank != higher.rank,
                  let rem: Card = cards.filter({ [lower.rank, higher.rank].contains($0.rank) == false }).first
            else { return nil }
            self.lower = lower
            self.higher = higher
            self.remainder = rem
        }
    }

    public struct ThreeOfAKind: Hashable, Codable, Sendable {
        public let threeOfAKind: Card
        public let remainder: [Card]
        init?(cards: [Card]) {
            guard let trip: Card = cards.kind(of: 3) else { return nil }
            self.threeOfAKind = trip
            let rem: [Card] = cards.filter { $0.rank != trip.rank }.sorted(by: { $0.rank > $1.rank })
            guard Set(rem.map { $0.rank }).count == 2 else { return nil }
            self.remainder = rem
        }
    }

    public struct Straight: Hashable, Codable, Sendable {
        public let highCard: Card
        init?(cards: [Card]) {
            let sorted: [Card] = cards.sorted(by: { $0.rank < $1.rank })
            guard sorted.isStraight else { return nil }
            if sorted.first?.rank == .two {
                self.highCard = sorted.dropLast().last!
            } else {
                self.highCard = sorted.last!
            }
        }
    }

    public struct Flush: Hashable, Codable, Sendable {
        public let cards: [Card]
        init?(cards: [Card]) {
            guard cards.isFlush else { return nil }
            self.cards = cards.sorted(by: { $0.rank > $1.rank })
        }
    }

    public struct FullHouse: Hashable, Codable, Sendable {
        public let threeOfAKind: Card
        public let remainingPair: Card
        init?(cards: [Card]) {
            guard let trip: Card = cards.kind(of: 3) else { return nil }
            self.threeOfAKind = trip
            let rem: [Card] = cards.filter { $0.rank != trip.rank }
            guard let pair: Card = rem.kind(of: 2) else { return nil }
            self.remainingPair = pair
        }
    }

    public struct FourOfAKind: Hashable, Codable, Sendable {
        public let fourOfAKind: Card
        public let remainder: Card
        init?(cards: [Card]) {
            guard let quad: Card = cards.kind(of: 4) else { return nil }
            self.fourOfAKind = quad
            let rem: [Card] = cards.filter { $0.rank != quad.rank }
            guard rem.count == 1 else { return nil }
            self.remainder = rem.first!
        }
    }

    public struct StraightFlush: Hashable, Codable, Sendable {
        public let highCard: Card
        init?(cards: [Card]) {
            guard cards.isFlush else { return nil }
            let sorted: [Card] = cards.sorted(by: { $0.rank < $1.rank })
            guard sorted.isStraight else { return nil }
            if sorted.first?.rank == .two {
                self.highCard = sorted.dropLast().last!
            } else {
                self.highCard = sorted.last!
            }
        }
    }
}
