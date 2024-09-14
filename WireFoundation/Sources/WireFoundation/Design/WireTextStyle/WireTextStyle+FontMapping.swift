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

public protocol WireTextStyle2FontMapping: Sendable {
    func font(for textStyle: WireTextStyle) -> Font
}

public extension View {
    func wireTextStyle2FontMapping<Mapping: WireTextStyle2FontMapping>(_ mapping: Mapping) -> some View {
        environment(\.wireTextStyle2FontMapping, mapping)
    }
}

extension WireTextStyle2FontMapping where Self == WireTextStyle2FontDefaultMapping {
    static var `default`: Self {
        WireTextStyle2FontDefaultMapping()
    }
}

private struct WireTextStyle2FontDefaultMapping: WireTextStyle2FontMapping {
    func font(for textStyle: WireTextStyle) -> Font {
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

private struct WireTextStyle2FontMappingKey: EnvironmentKey {
    static let defaultValue: any WireTextStyle2FontMapping = .default
}

public extension EnvironmentValues {
    var wireTextStyle2FontMapping: any WireTextStyle2FontMapping {
        get { self[WireTextStyle2FontMappingKey.self] }
        set { self[WireTextStyle2FontMappingKey.self] = newValue }
    }
}
