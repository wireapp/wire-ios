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
import WireDesign
import WireFoundation
import WireReusableUIComponents

struct BackButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: { Text(title) }
        )
        .buttonStyle(.plain)
        .wireTextStyle(.buttonBig)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(uiColor: ColorTheme.Strokes.outline), lineWidth: 1)
        }
        .cornerRadius(16)
    }
}
