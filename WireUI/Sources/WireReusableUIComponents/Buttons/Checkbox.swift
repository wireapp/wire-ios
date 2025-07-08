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

public struct Checkbox: View {

    @Binding var isChecked: Bool

    private let title: AttributedString

    public init(isChecked: Binding<Bool>, title: AttributedString) {
        self._isChecked = isChecked
        self.title = title
    }

    public init(isChecked: Binding<Bool>, title: String) {
        self._isChecked = isChecked
        self.title = AttributedString(title)
    }

    public var body: some View {
        HStack {
            Button(action: {
                isChecked.toggle()
            }, label: {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24))
            })
            .buttonStyle(.plain)
            .foregroundStyle(isChecked ? ColorTheme.Checkbox.selected.color : ColorTheme.Checkbox.enabled.color)
            Text(title)
                .wireTextStyle(.subline1)
        }
    }

}
