import Foundation

extension [Card] {
    public func sorted() -> [Card] {
        sorted(by: { $0.rank > $1.rank })
    }

    public var debugDescription: String {
        map { $0.debugDescription }.joined(separator: " ")
    }

    public func kind(of n: Int) -> Card? {
        for card in self {
            let sameRanks: [Card] = filter { $0.rank == card.rank }
            if sameRanks.count == n { return card }
        }
        return nil
    }

    public var isStraight: Bool {
        let ranks: [Card.Rank] = map { $0.rank }
        if ranks == [.two, .three, .four, .five, .ace] { return true }
        let maxDiff: Int = ranks.max()!.value - ranks.min()!.value
        return maxDiff == 4 && Set(ranks).count == 5
    }

    public var isFlush: Bool {
        Set(map { $0.suit }).count == 1
    }

    public var allPokerHandCombinations: [[Card]] {
        var combos: [[Card]] = []
        guard count >= 5 else { return combos }
        for i in 0..<(count - 4) {
            for j in (i + 1)..<(count - 3) {
                for k in (j + 1)..<(count - 2) {
                    for m in (k + 1)..<(count - 1) {
                        for n in (m + 1)..<count {
                            combos.append([self[i], self[j], self[k], self[m], self[n]])
                        }
                    }
                }
            }
        }
        return combos
    }

    public func bestPokerHand() throws -> PokerHand {
        let allCombos: [[Card]] = allPokerHandCombinations
        guard let first = allCombos.first else { throw PokerHandError.not5Cards }
        var best: PokerHand = try .init(cards: first)
        for cards in allCombos.dropFirst() {
            let hand: PokerHand = try .init(cards: cards)
            if (hand.topRank > best.topRank) == true { best = hand }
        }
        return best
    }

    public func bestOmahaHand(board: [Card]) throws -> PokerHand {
        guard count >= 2, board.count >= 3 else { throw PokerHandError.not5Cards }
        var best: PokerHand?
        for holePair in twoCombinations() {
            for boardTriple in board.threeCombinations() {
                let hand: PokerHand = try .init(cards: holePair + boardTriple)
                if let current: PokerHand = best {
                    if (hand.topRank > current.topRank) == true { best = hand }
                } else { best = hand }
            }
        }
        guard let result: PokerHand = best else { throw PokerHandError.not5Cards }
        return result
    }

    public func twoCombinations() -> [[Card]] {
        var result: [[Card]] = []
        for i in 0..<(count - 1) {
            for j in (i + 1)..<count { result.append([self[i], self[j]]) }
        }
        return result
    }

    public func threeCombinations() -> [[Card]] {
        var result: [[Card]] = []
        guard count >= 3 else { return result }
        for i in 0..<(count - 2) {
            for j in (i + 1)..<(count - 1) {
                for k in (j + 1)..<count { result.append([self[i], self[j], self[k]]) }
            }
        }
        return result
    }

    public static func > (lhs: [Card], rhs: [Card]) -> Bool? {
        let sortedLHS: [Card] = lhs.sorted(by: { $0.rank > $1.rank })
        let sortedRHS: [Card] = rhs.sorted(by: { $0.rank > $1.rank })
        for (l, r) in zip(sortedLHS, sortedRHS) {
            if let higher: Bool = l > r { return higher }
        }
        return nil
    }
}
