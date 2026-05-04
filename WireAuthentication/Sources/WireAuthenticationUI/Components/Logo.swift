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

struct Logo: View {
    var body: some View {
        GeometryReader { geometry in
            Image(ImageResource(name: "logo", bundle: .module))
                .resizable()
                .scaledToFit()
                .padding(.all, min(geometry.size.height, geometry.size.width) / 3)
        }
    }
}

#Preview {
    Logo()
        .frame(height: 95)
}
