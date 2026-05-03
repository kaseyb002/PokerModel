import Foundation

public struct LowHand: Hashable, Codable, Sendable {
    public let cards: [Card]
    public let ranks: [Int]
    public let description: String

    /// Standard low hand with 8-or-better qualifier (for Hi-Lo)
    public init?(cards: [Card]) {
        guard cards.count == 5 else { return nil }
        let sorted: [Card] = cards.sorted(by: { $0.rank.lowValue < $1.rank.lowValue })
        let rankValues: [Int] = sorted.map { $0.rank.lowValue }
        guard Set(rankValues).count == 5 else { return nil }
        guard rankValues.last! <= 8 else { return nil }
        self.cards = sorted
        self.ranks = rankValues
        self.description = sorted.map { $0.rank.displayValue }.joined(separator: "-")
    }

    /// Razz low hand - no qualifier, pairs allowed as last resort
    public init?(razzCards: [Card]) {
        guard razzCards.count == 5 else { return nil }
        let sorted: [Card] = razzCards.sorted(by: { $0.rank.lowValue < $1.rank.lowValue })
        let rankValues: [Int] = sorted.map { $0.rank.lowValue }
        self.cards = sorted
        self.ranks = rankValues
        self.description = sorted.map { $0.rank.displayValue }.joined(separator: "-")
    }

    public static func bestLowHand(from allCards: [Card]) -> LowHand? {
        let combos: [[Card]] = allCards.allPokerHandCombinations
        var best: LowHand?
        for combo in combos {
            guard let low: LowHand = .init(cards: combo) else { continue }
            if let current: LowHand = best {
                if low < current { best = low }
            } else {
                best = low
            }
        }
        return best
    }

    public static func bestRazzHand(from allCards: [Card]) -> LowHand? {
        let combos: [[Card]] = allCards.allPokerHandCombinations
        var best: LowHand?
        for combo in combos {
            guard let low: LowHand = .init(razzCards: combo) else { continue }
            if let current: LowHand = best {
                if low.razzCompare(current) { best = low }
            } else {
                best = low
            }
        }
        return best
    }

    public static func bestOmahaLowHand(holeCards: [Card], board: [Card]) -> LowHand? {
        var best: LowHand?
        for holePair in holeCards.twoCombinations() {
            for boardTriple in board.threeCombinations() {
                guard let low: LowHand = .init(cards: holePair + boardTriple) else { continue }
                if let current: LowHand = best {
                    if low < current { best = low }
                } else { best = low }
            }
        }
        return best
    }

    /// Razz comparison: fewer pairs is better, then compare highest card down
    public func razzCompare(_ other: LowHand) -> Bool {
        let selfPairs: Int = pairCount(ranks)
        let otherPairs: Int = pairCount(other.ranks)
        if selfPairs < otherPairs { return true }
        if selfPairs > otherPairs { return false }
        for (l, r) in zip(ranks.reversed(), other.ranks.reversed()) {
            if l < r { return true }
            if l > r { return false }
        }
        return false
    }

    private func pairCount(_ vals: [Int]) -> Int {
        let counts: [Int: Int] = Dictionary(grouping: vals, by: { $0 }).mapValues(\.count)
        return counts.values.filter { $0 >= 2 }.count
    }
}

extension LowHand: Comparable {
    public static func < (lhs: LowHand, rhs: LowHand) -> Bool {
        for (l, r) in zip(lhs.ranks.reversed(), rhs.ranks.reversed()) {
            if l < r { return true }
            if l > r { return false }
        }
        return false
    }
}
