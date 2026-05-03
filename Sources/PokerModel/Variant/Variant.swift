import Foundation

public enum Variant: String, Equatable, Codable, Sendable, CaseIterable {
    case noLimitHoldEm
    case limitHoldEm
    case noLimitOmaha
    case potLimitOmaha
    case fiveCardDraw
    case razz
    case sevenCardStud
    case studHighLow
    case pineapple

    public var displayableName: String {
        switch self {
        case .noLimitHoldEm: "No Limit Hold'em"
        case .limitHoldEm: "Limit Hold'em"
        case .noLimitOmaha: "No Limit Omaha"
        case .potLimitOmaha: "Pot Limit Omaha"
        case .fiveCardDraw: "5-Card Draw"
        case .razz: "Razz"
        case .sevenCardStud: "7-Card Stud"
        case .studHighLow: "Stud Hi-Lo"
        case .pineapple: "Pineapple"
        }
    }

    public var maxPlayers: Int {
        switch self {
        case .noLimitHoldEm, .limitHoldEm, .noLimitOmaha, .potLimitOmaha, .pineapple: 10
        case .fiveCardDraw: 6
        case .razz, .sevenCardStud, .studHighLow: 8
        }
    }

    public var minPlayers: Int { 2 }

    public var bettingStructure: BettingStructure {
        switch self {
        case .noLimitHoldEm, .noLimitOmaha, .pineapple: .noLimit
        case .limitHoldEm, .sevenCardStud, .razz, .studHighLow: .fixedLimit
        case .potLimitOmaha: .potLimit
        case .fiveCardDraw: .noLimit
        }
    }

    public var holeCardCount: Int {
        switch self {
        case .noLimitHoldEm, .limitHoldEm: 2
        case .pineapple: 3
        case .noLimitOmaha, .potLimitOmaha: 4
        case .fiveCardDraw: 5
        case .sevenCardStud, .razz, .studHighLow: 0
        }
    }

    public var usesCommunityCards: Bool {
        switch self {
        case .noLimitHoldEm, .limitHoldEm, .noLimitOmaha, .potLimitOmaha, .pineapple: true
        case .fiveCardDraw, .razz, .sevenCardStud, .studHighLow: false
        }
    }

    public var isStudVariant: Bool {
        switch self {
        case .sevenCardStud, .razz, .studHighLow: true
        default: false
        }
    }

    public var usesLowHand: Bool {
        switch self {
        case .razz, .studHighLow: true
        default: false
        }
    }

    public var streetCount: Int {
        switch self {
        case .noLimitHoldEm, .limitHoldEm, .noLimitOmaha, .potLimitOmaha, .pineapple: 4
        case .fiveCardDraw: 2
        case .sevenCardStud, .razz, .studHighLow: 5
        }
    }
}

public enum BettingStructure: String, Equatable, Codable, Sendable {
    case noLimit
    case fixedLimit
    case potLimit
}
