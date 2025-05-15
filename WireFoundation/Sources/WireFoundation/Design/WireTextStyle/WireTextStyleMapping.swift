//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

public import SwiftUI

public final class WireTextStyleMapping: ObservableObject, Sendable {
    #if canImport(UIKit)
        public typealias UIFontMapping = @Sendable (WireTextStyle) -> UIFont
    #endif
    public typealias FontMapping = @Sendable (WireTextStyle) -> Font

    #if canImport(UIKit)
        let uiFontMapping: UIFontMapping
    #endif
    let fontMapping: FontMapping

    #if canImport(UIKit)
        public init(
            uiFontMapping: @escaping UIFontMapping,
            fontMapping: @escaping FontMapping
        ) {
            self.uiFontMapping = uiFontMapping
            self.fontMapping = fontMapping
        }
    #else
        public init(
            fontMapping: @escaping FontMapping
        ) {
            self.fontMapping = fontMapping
        }
    #endif

    #if canImport(UIKit)
        public func uiFont(for textStyle: WireTextStyle) -> UIFont {
            uiFontMapping(textStyle)
        }
    #endif

    public func font(for textStyle: WireTextStyle) -> Font {
        fontMapping(textStyle)
    }
}

private struct WireTextStyleMappingKey: EnvironmentKey {
    static let defaultValue = WireTextStyleMapping?.none
}

public extension EnvironmentValues {
    var wireTextStyleMapping: WireTextStyleMapping? {
        get { self[WireTextStyleMappingKey.self] }
        set { self[WireTextStyleMappingKey.self] = newValue }
    }
}
