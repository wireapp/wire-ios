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

struct ScreenCurtainView: View {

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                // for some reason `Image(.Wire.shield)` didn't show the shield
                Image(uiImage: .init(resource: .Wire.shield))
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        // Ignore all safe areas (incl. the keyboard) so the curtain fully covers the screen.
        // Otherwise, when the keyboard is visible (e.g. on the AppLock passcode screen),
        // SwiftUI's keyboard avoidance shrinks the black background to the keyboard top,
        // leaving an uncovered gray bar when the app resigns active.
        .ignoresSafeArea()
    }
}

#Preview {
    ScreenCurtainView()
}
