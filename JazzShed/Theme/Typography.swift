import SwiftUI

/// Jazz-themed typography helpers.
enum JazzTypography {
    static let scoreDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
    static let comboDisplay = Font.system(size: 32, weight: .bold, design: .rounded)
    static let chordSymbol = Font.system(.title3, design: .rounded).weight(.semibold)
    static let sectionHeader = Font.caption.weight(.bold)
    static let monospaced = Font.system(.body, design: .monospaced)
}
