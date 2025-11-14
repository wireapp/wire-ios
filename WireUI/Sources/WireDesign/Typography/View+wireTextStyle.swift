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

public extension View {

    /// Sets a font for the given text style.
    ///
    /// - Parameter textStyle: The text style to use to create the Font.
    /// - Returns: Font that uses the style you specify.

    func font(for textStyle: WireTextStyle) -> some View {
        self.font(.textStyle(textStyle))
    }

}

extension Font {

    fileprivate static func textStyle(_ textStyle: WireTextStyle) -> Font {
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
        case .subline2:
            .caption.weight(.semibold)
        case .buttonSmall:
            .system(size: 14, weight: .semibold)
        case .buttonBig:
            .title3.weight(.semibold)
        }
    }

}

// MARK: - Previews

#Preview("SwiftUI.Font") {
    WireTextStyleFontMappingPreview()
}

@ViewBuilder @MainActor
func WireTextStyleFontMappingPreview() -> some View {
    NavigationStack {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(WireTextStyle.allCases, id: \.self) { textStyle in
                    Text(textStyle.rawValue)
                        .font(for: textStyle)
                }
                .padding(.top)
            }
        }
        .navigationTitle(Text(verbatim: "WireTextStyle -> SwiftUI.Font"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
