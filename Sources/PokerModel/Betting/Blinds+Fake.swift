import Foundation

extension Blinds {
    public static func fake() -> Blinds {
        [Blinds].presets.randomElement()!
    }
}
