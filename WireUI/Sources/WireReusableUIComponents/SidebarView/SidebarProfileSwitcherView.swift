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

struct SidebarProfileSwitcherView<AccountImageView>: View
    where AccountImageView: View {

    @State private var accountImageDiameter: CGFloat = 0

    let displayName: String
    let username: String
    let accountImageView: () -> AccountImageView

    var body: some View {
        HStack {
            accountImageView()
                .frame(width: accountImageDiameter, height: accountImageDiameter)

            VStack(alignment: .leading) {
                Text(displayName)
                    .font(.headline)
                    .foregroundStyle(Color(ColorTheme.Backgrounds.onSurface))
                Text(username)
                    .font(.subheadline)
                    .foregroundStyle(Color(ColorTheme.Base.secondaryText))
            }
            .background(GeometryReader { geometryProxy in
                Color.clear.preference(
                    key: ProfileSwitcherHeightKey.self,
                    value: geometryProxy.size.height
                )
            })
            .onPreferenceChange(ProfileSwitcherHeightKey.self) { height in
                accountImageDiameter = height
            }
        }
    }
}

extension SidebarProfileSwitcherView {

    init(
        _ displayName: String,
        _ username: String,
        _ accountImageView: @escaping () -> AccountImageView
    ) {
        self.init(
            displayName: displayName,
            username: username,
            accountImageView: accountImageView
        )
    }
}

private struct ProfileSwitcherHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // probably never called
        value = nextValue()
    }
}

// MARK: - Previews

#Preview {
    SidebarProfileSwitcherView(displayName: "Firstname Lastname", username: "@username") {
        MockAccountView()
    }
}

private struct MockAccountView: View {

    var body: some View {
        Circle()
    }
}
