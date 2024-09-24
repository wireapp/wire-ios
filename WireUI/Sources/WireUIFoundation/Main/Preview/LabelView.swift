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

/// A simple view which displays a text centered horizontally and vertically.
/// Used for previews only.
struct LabelView: View {
    var content: String
    var backgroundColor: Color
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(content)
                    .ignoresSafeArea()
                Spacer()
            }
            Spacer()
        }.background(backgroundColor)
    }
}
