import Foundation

extension Decimal {
    private static let moneyFormatter: NumberFormatter = {
        let f: NumberFormatter = .init()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "en_US")
        f.currencySymbol = "$"
        f.maximumFractionDigits = 2
        return f
    }()

    public var moneyString: String {
        var formatted: String = Self.moneyFormatter.string(for: self) ?? ""
        if formatted.hasSuffix(".00") { formatted = String(formatted.dropLast(3)) }
        return formatted
    }

    public var roundToClosestPenny: Decimal {
        let dn: NSDecimalNumber = .init(decimal: self)
        let handler: NSDecimalNumberHandler = .init(
            roundingMode: .bankers, scale: 2,
            raiseOnExactness: false, raiseOnOverflow: false,
            raiseOnUnderflow: false, raiseOnDivideByZero: false
        )
        return dn.rounding(accordingToBehavior: handler).decimalValue
    }
}
