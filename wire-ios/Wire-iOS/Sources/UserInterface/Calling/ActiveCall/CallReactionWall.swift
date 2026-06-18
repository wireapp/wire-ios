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

/// Transparent overlay drawn on top of the call grid.
/// Received emoji reactions float upward with the sender's name.
struct CallReactionWall: View {

    var viewModel: CallReactionWallViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                ForEach(viewModel.items) { item in
                    VStack(spacing: 2) {
                        Text(item.emoji)
                            .font(.system(size: 36))
                        Text(item.senderName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(.leading, 16)
                    .offset(y: item.yOffset)
                    .opacity(item.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomLeading)
        }
        .allowsHitTesting(false)
    }
}
