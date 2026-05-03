import Foundation

public enum BoolExtensions: Sendable {
    public static func random(withProbability probability: Float) -> Bool {
        probability > .random(in: 0...1)
    }
}
