import Foundation
import SwiftUI

struct AppColor {
    static var background: Color {
        // this is a bit nasty. reconsider approach to handling light vs. dark
        Color(UIColor { $0.userInterfaceStyle == .light ? UIColor(red: 255, green: 255, blue: 255, alpha: 1) : UIColor(cgColor: Color(hex: "ecf0f1").cgColor!) })
    }
    
    static var activityTint: Color {
        //Color(hex: "56CCF2")
        lightTeal
    }
    // color palette courtesy of https://flatuicolors.com/palette/us
    static var lightBlue: Color {
        Color(hex: "74b9ff")
    }
    
    static var deepBlue: Color {
        Color(hex: "0984e3")
    }
    
    static var lightRed: Color {
        Color(hex: "ff7675")
    }
    
    static var deepRed: Color {
        Color(hex: "d63031")
    }
    
    static var lightOrange: Color {
        Color(hex: "fab1a0")
    }
    
    static var deepOrange: Color {
        Color(hex: "e17055")
    }
    
    static var lightYellow: Color {
        Color(hex: "ffeaa7")
    }
    
    static var deepYellow: Color {
        Color(hex: "fdcb6e")
    }
    
    static var lightGreen: Color {
        Color(hex: "55efc4")
    }
    
    static var deepGreen: Color {
        Color(hex: "00b894")
    }
    
    static var lightTeal: Color {
        Color(hex: "81ecec")
    }
    
    static var deepTeal: Color {
        Color(hex: "00cec9")
    }
    
    static var lightPink: Color {
        Color(hex: "fd79a8")
    }
    
    static var deepPink: Color {
        Color(hex: "e84393")
    }
    
    static var lightPurple: Color {
        Color(hex: "a29bfe")
    }
    
    static var deepPurple: Color {
        Color(hex: "6c5ce7")
    }
    
    static var gray0: Color {
        Color(hex: "dfe6e9")
    }
    
    static var gray1: Color {
        Color(hex: "b2bec3")
    }
    
    static var gray2: Color {
        Color(hex: "636e72")
    }
    
    static var gray3: Color {
        Color(hex: "2d3436")
    }
    
    static var blackText: Color {
        Color("BlackText")
    }
    
    static var white: Color {
        .white
    }

    static var spotifyGreen: Color {
        Color(hex: "#1ED760")
    }
}

extension Color {
    func toUIColor() -> UIColor {
        return UIColor(cgColor: self.cgColor!)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    static var randomColor: UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
                    
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }

    static func getRandomColors(count: Int = 20) -> [UIColor] {
        (0..<count).map { int in
            return randomColor
        }
    }
}
