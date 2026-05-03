import Foundation

extension Array where Element: Hashable {
    public func asSet() -> Set<Element> {
        Set(self)
    }
}
