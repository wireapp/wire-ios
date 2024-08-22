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

private struct SidebarProfileSwitcherView: View {

    @State private var accountImageDiameter: CGFloat = 0

    var body: some View {
        HStack {

            Circle()
                .foregroundColor(.blue)
                .frame(width: accountImageDiameter, height: accountImageDiameter)

            VStack(alignment: .leading) {
                Text("First Text")
                    .font(.headline)
                Text("Second Text")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .background(GeometryReader { geometryProxy in
                Color.yellow.preference(
                    key: ProfileSwitcherHeightKey.self,
                    value: geometryProxy.size.height
                )
            })
            .onPreferenceChange(ProfileSwitcherHeightKey.self) { height in
                accountImageDiameter = height
            }
        }
        .padding()
    }
}

private struct ProfileSwitcherHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarProfileSwitcherView()
    }
}
