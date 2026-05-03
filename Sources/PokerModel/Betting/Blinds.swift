import Foundation

public struct Blinds: Equatable, Codable, Sendable, Identifiable {
    public let smallBlind: Decimal
    public let bigBlind: Decimal
    public let ante: Decimal

    public var id: String {
        "\(smallBlind.moneyString)-\(bigBlind.moneyString)"
    }

    public init(smallBlind: Decimal, bigBlind: Decimal, ante: Decimal = .zero) {
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
        self.ante = ante
    }

    public init(_ smallBlind: Double, _ bigBlind: Double, ante: Double = 0) {
        self.smallBlind = .init(floatLiteral: smallBlind)
        self.bigBlind = .init(floatLiteral: bigBlind)
        self.ante = .init(floatLiteral: ante)
    }
}

extension [Blinds] {
    public static var presets: [Blinds] {
        [
            .init(0.01, 0.02), .init(0.05, 0.10), .init(0.10, 0.20),
            .init(0.25, 0.50), .init(0.50, 1.00), .init(1, 2),
            .init(2, 4), .init(5, 10), .init(10, 20),
            .init(25, 50), .init(50, 100), .init(100, 200),
        ]
    }
}
