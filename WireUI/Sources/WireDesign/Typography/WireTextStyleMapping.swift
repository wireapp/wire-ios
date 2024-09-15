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
import WireFoundation

public extension WireTextStyleMapping {

    convenience init() {
        self.init { textStyle in
                .textStyle(textStyle)
        }
    }
}

public extension Font {

    /// Creates a font from the given text style.
    ///
    /// - Parameter textStyle: The text style to use to create the Font.
    /// - Returns: Font that uses the style you specify.

    static func textStyle(_ textStyle: WireTextStyle) -> Font {
        switch textStyle {
        case .largeTitle:
            .largeTitle
        case .h1:
            .title3
        case .h2:
            .title3.bold()
        case .h3:
            .headline
        case .h4:
            .subheadline
        case .h5:
            .footnote
        case .body1:
            .body
        case .body2:
            .callout.weight(.semibold)
        case .body3:
            .callout.bold()
        case .subline1:
            .caption
        case .buttonSmall:
            fatalError("not implemented")
        case .buttonBig:
            .title3.weight(.semibold)
        }
    }
}

@available(iOS 16, *)
#Preview {
    WireTextStyleMappingPreview()
}

@available(iOS 16, *) @ViewBuilder @MainActor
func WireTextStyleMappingPreview() -> some View {
    NavigationStack {
        ZStack(alignment: .center) {
            VStack {
                ForEach(WireTextStyle.allCases, id: \.self) { textStyle in
                    HStack {
                        Text("\(textStyle)")
                            .wireTextStyle(textStyle)
                            .wireTextStyleMapping(WireTextStyleMapping())
                        Text("\(textStyle)")
                            .wireTextStyle(textStyle)
                    }
                }
            }
        }
        .navigationTitle(Text(verbatim: "WireTextStyle"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
