import Foundation

public typealias CardID = String

public struct Card: Hashable, Identifiable, Codable, Sendable {
    public let rank: Rank
    public let suit: Suit

    public var id: String { rank.id + suit.id }

    public var debugDescription: String {
        "\(rank.displayValue)\(suit.emoji)"
    }

    public var imageAssetName: String {
        id.uppercased()
    }

    public init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    public init?(id: String) {
        guard let rankChar: Character = id.first,
              let rank: Rank = .init(rawValue: String(rankChar).lowercased()),
              let suitChar: Character = id.last,
              let suit: Suit = .init(rawValue: String(suitChar).lowercased())
        else { return nil }
        self.rank = rank
        self.suit = suit
    }

    public static func > (lhs: Card, rhs: Card) -> Bool? {
        if lhs.rank > rhs.rank { return true }
        else if lhs.rank < rhs.rank { return false }
        return nil
    }

    // MARK: - Rank

    public enum Rank: String, Hashable, Identifiable, CaseIterable, Codable, Sendable {
        case ace = "a", two = "2", three = "3", four = "4", five = "5"
        case six = "6", seven = "7", eight = "8", nine = "9", ten = "t"
        case jack = "j", queen = "q", king = "k"

        public var id: String { rawValue }

        public var displayValue: String {
            switch self {
            case .ace: "A" case .two: "2" case .three: "3" case .four: "4"
            case .five: "5" case .six: "6" case .seven: "7" case .eight: "8"
            case .nine: "9" case .ten: "10" case .jack: "J" case .queen: "Q"
            case .king: "K"
            }
        }

        public var longDisplayValue: String {
            switch self {
            case .ace: "Ace" case .two: "Two" case .three: "Three" case .four: "Four"
            case .five: "Five" case .six: "Six" case .seven: "Seven" case .eight: "Eight"
            case .nine: "Nine" case .ten: "Ten" case .jack: "Jack" case .queen: "Queen"
            case .king: "King"
            }
        }

        public var value: Int {
            switch self {
            case .ace: 12 case .two: 0 case .three: 1 case .four: 2
            case .five: 3 case .six: 4 case .seven: 5 case .eight: 6
            case .nine: 7 case .ten: 8 case .jack: 9 case .queen: 10
            case .king: 11
            }
        }

        public var lowValue: Int {
            switch self {
            case .ace: 1 case .two: 2 case .three: 3 case .four: 4
            case .five: 5 case .six: 6 case .seven: 7 case .eight: 8
            case .nine: 9 case .ten: 10 case .jack: 11 case .queen: 12
            case .king: 13
            }
        }
    }

    // MARK: - Suit

    public enum Suit: String, Hashable, Identifiable, CaseIterable, Codable, Sendable {
        case heart = "h", club = "c", diamond = "d", spade = "s"

        public var id: String { rawValue }

        public var emoji: String {
            switch self {
            case .spade: "♠️" case .heart: "❤️" case .club: "♣️" case .diamond: "♦️"
            }
        }

        public var studOrder: Int {
            switch self {
            case .club: 0 case .diamond: 1 case .heart: 2 case .spade: 3
            }
        }
    }
}

extension Card.Rank: Comparable {
    public static func < (lhs: Card.Rank, rhs: Card.Rank) -> Bool {
        lhs.value < rhs.value
    }
}
