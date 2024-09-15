//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import SwiftUI

// TODO: check if WireTextStyle->UIFont and WireTextStyle->Font are both needed, what about CTFont?
public final class WireTextStyleMapping: ObservableObject, Sendable {

    // public typealias UIFontMapping = @Sendable (WireTextStyle) -> UIFont
    public typealias FontMapping = @Sendable (WireTextStyle) -> Font

    // let uiFontMapping: UIFontMapping
    let fontMapping: FontMapping

    //public convenience init(uiFontMapping: @escaping UIFontMapping) {
    //    self.init(uiFontMapping: uiFontMapping) { uiFont in
    //        Font(uiFontMapping(uiFont))
    //    }
    //}

    public init(
        // uiFontMapping: @escaping UIFontMapping,
        fontMapping: @escaping FontMapping
    ) {
        // self.uiFontMapping = uiFontMapping
        self.fontMapping = fontMapping
    }

    // public func uiFont(for textStyle: WireTextStyle) -> UIFont {
    //     uiFontMapping(textStyle)
    // }

    public func color(for textStyle: WireTextStyle) -> Font {
        fontMapping(textStyle)
    }
}

private struct WireTextStyleMappingKey: EnvironmentKey {
    static let defaultValue = WireTextStyleMapping { textStyle in
        switch textStyle {
        case .largeTitle:
                .largeTitle
        case .h1:
                .footnote
        case .h2:
                .footnote
        case .h3:
                .footnote
        case .h4:
                .footnote
        case .h5:
                .footnote
        case .body1:
                .footnote
        case .body2:
                .footnote
        case .body3:
                .footnote
        case .subline1:
                .footnote
        case .buttonSmall:
                .footnote
        case .buttonBig:
                .footnote
        }
    }
}

public extension EnvironmentValues {
    var wireTextStyleMapping: WireTextStyleMapping {
        get { self[WireTextStyleMappingKey.self] }
        set { self[WireTextStyleMappingKey.self] = newValue }
    }
}
