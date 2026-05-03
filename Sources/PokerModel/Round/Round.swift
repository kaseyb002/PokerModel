import Foundation

public struct Round: Equatable, Codable, Sendable, Identifiable {
    // MARK: - Initialized Properties
    public let id: String
    public let started: Date
    public let variant: Variant
    public let blinds: Blinds

    // MARK: - Round Progression
    public internal(set) var state: State
    public internal(set) var street: Street
    public internal(set) var players: [RoundPlayer]
    public internal(set) var cardsMap: [CardID: Card]
    public internal(set) var variantRound: VariantRound

    // MARK: - Pots
    public internal(set) var pots: [Pot] = []
    public internal(set) var potResults: [PotResult] = []

    // MARK: - Results
    public internal(set) var ended: Date?

    // MARK: - Log
    public internal(set) var log: Log = .init()

    // MARK: - Config
    public var autoProgress: Bool = true

    public static let maxLogActions: Int = 100

    public enum State: Equatable, Codable, Sendable {
        case waitingForSmallBlind
        case waitingForBigBlind
        case waitingForAnte(playerIndex: Int)
        case waitingForBringIn(playerIndex: Int)
        case waitingForPlayerToAct(playerIndex: Int)
        case waitingForDiscard(playerID: PlayerID)
        case waitingForDraw(playerID: PlayerID)
        case waitingToProgressStreet
        case roundComplete
    }

    public enum Street: Int, Equatable, Codable, Sendable, Comparable {
        case first = 0
        case second = 1
        case third = 2
        case fourth = 3
        case fifth = 4

        public static func < (lhs: Street, rhs: Street) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        public func displayName(for variant: Variant) -> String {
            switch variant {
            case .noLimitHoldEm, .limitHoldEm, .noLimitOmaha, .potLimitOmaha, .pineapple:
                switch self {
                case .first: "Preflop"
                case .second: "Flop"
                case .third: "Turn"
                case .fourth: "River"
                case .fifth: "River"
                }
            case .sevenCardStud, .razz, .studHighLow:
                switch self {
                case .first: "3rd Street"
                case .second: "4th Street"
                case .third: "5th Street"
                case .fourth: "6th Street"
                case .fifth: "7th Street"
                }
            case .fiveCardDraw:
                switch self {
                case .first: "Pre-Draw"
                case .second: "Post-Draw"
                default: "Post-Draw"
                }
            }
        }
    }
}
