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

import SwiftUI
import WireDesign

struct DeleteItemButtonViewModifier: ViewModifier {
    private enum Constants {
        static let iconFontSize: CGFloat = 24
        static let padding: CGFloat = 2
        static let buttonSize: CGFloat = 35
        static let offset: CGFloat = 17.5
    }

    let onRemove: @Sendable () -> Void

    init(onRemove: @escaping @Sendable () -> Void) {
        self.onRemove = onRemove
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                Button(action: {
                    onRemove()
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Constants.iconFontSize))
                })
                .buttonStyle(CircularIconButtonStyle(padding: Constants.padding))
                .frame(
                    width: Constants.buttonSize,
                    height: Constants.buttonSize
                )
                .offset(
                    x: Constants.offset,
                    y: -Constants.offset
                )
            }
    }
}

extension View {
    func deleteItemButton(onRemove: @escaping @Sendable () -> Void) -> some View {
        modifier(DeleteItemButtonViewModifier(onRemove: onRemove))
    }
}

#Preview {
    RoundedRectangle(cornerRadius: 10)
        .fill(.gray)
        .deleteItemButton(onRemove: {})
        .frame(width: 200, height: 200)
}
