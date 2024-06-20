import Foundation

extension Int {
    var formattedWithAbbreviations: String {
        let number = Double(self)
        let thousand = number / 1000
        let million = number / 1000000
        
        func formatNumber(_ value: Double, suffix: String) -> String {
            let roundedValue = round(value * 10) / 10
            if roundedValue.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(roundedValue))\(suffix)"
            } else {
                return "\(String(format: "%.1f", roundedValue))\(suffix)"
            }
        }
        
        if million >= 1.0 {
            return formatNumber(million, suffix: "M")
        } else if thousand >= 1.0 {
            return formatNumber(thousand, suffix: "k")
        } else {
            return "\(self)"
        }
    }
}
