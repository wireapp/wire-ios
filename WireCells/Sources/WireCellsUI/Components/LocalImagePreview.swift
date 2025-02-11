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

struct LocalImagePreview: View {
    let image: Image

    var body: some View {
        GeometryReader { geometry in
            image
                .resizable()
                .scaledToFill()
                // Image won't clip to the container's frame.
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .circular))
        }
    }
}

#Preview {
    VStack {
        LocalImagePreview(image: Image("demo-image", bundle: .module))
            .foregroundStyle(.black)
            .frame(width: 200, height: 200)
            .background(.white)
    }
    .padding()
    .background(.gray)
}
