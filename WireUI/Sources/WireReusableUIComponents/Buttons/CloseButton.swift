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
import WireLocators

public struct CloseButton: View {

    private let action: () -> Void
    private let accessibilityLabel: String
    private let foregroundColor: UIColor

    public init(
        action: @escaping @MainActor () -> Void,
        foregroundColor: UIColor = SemanticColors.Icon.foregroundDefaultBlack,
        accessibilityLabel: String
    ) {
        self.action = action
        self.foregroundColor = foregroundColor
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        Button(action: action) {
            Image(.close)
        }
        .buttonStyle(.plain)
        .foregroundColor(Color(uiColor: foregroundColor))
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityIdentifier(Locators.UserDetailsPage.close.rawValue)
    }
}

#Preview {
    NavigationStack {
        Text("Hello, World!")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton(action: { print("Close") }, accessibilityLabel: "Close")
                }
            }
    }
}
