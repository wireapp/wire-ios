//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public struct RoundedBorderViewModifier: ViewModifier {

    let backgroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let padding: CGFloat

    public init(
        backgroundColor: Color,
        borderColor: Color,
        borderWidth: CGFloat,
        cornerRadius: CGFloat,
        padding: CGFloat
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .padding(padding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundColor)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: borderWidth)
                        .fill(.clear)
                }
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundColor)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.clear)
                        .border(borderColor, width: borderWidth)
                }
        }
    }
}

public extension View {
    func roundedBorderAndBackground(
        backgroundColor: Color,
        borderColor: Color,
        borderWidth: CGFloat,
        cornerRadius: CGFloat,
        padding: CGFloat
    ) -> some View {
        modifier(RoundedBorderViewModifier(
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            borderWidth: borderWidth,
            cornerRadius: cornerRadius,
            padding: padding
        ))
    }
}
