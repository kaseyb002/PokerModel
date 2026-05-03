import Foundation

public enum VariantRound: Equatable, Codable, Sendable {
    case noLimitHoldEm(HoldEmState)
    case limitHoldEm(HoldEmState)
    case noLimitOmaha(OmahaState)
    case potLimitOmaha(OmahaState)
    case fiveCardDraw(DrawState)
    case razz(StudState)
    case sevenCardStud(StudState)
    case studHighLow(StudState)
    case pineapple(PineappleState)
}

extension VariantRound {
    public var holeCardIDs: [PlayerID: [CardID]] {
        switch self {
        case .noLimitHoldEm(let s), .limitHoldEm(let s): s.holeCards
        case .noLimitOmaha(let s), .potLimitOmaha(let s): s.holeCards
        case .pineapple(let s): s.holeCards
        case .fiveCardDraw(let s): s.playerCards
        case .razz(let s), .sevenCardStud(let s), .studHighLow(let s):
            Dictionary(uniqueKeysWithValues: s.playerCards.map { ($0.key, $0.value.allCardIDs) })
        }
    }

    public var visibleBoardIDs: [CardID] {
        switch self {
        case .noLimitHoldEm(let s), .limitHoldEm(let s): s.visibleBoardIDs
        case .noLimitOmaha(let s), .potLimitOmaha(let s): s.visibleBoardIDs
        case .pineapple(let s): s.visibleBoardIDs
        default: []
        }
    }
}
