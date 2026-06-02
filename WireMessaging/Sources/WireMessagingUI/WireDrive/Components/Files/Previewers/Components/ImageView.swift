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

struct ImageView: View {
    let url: URL

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    private enum Constants {
        static let animationSpringResponse = 0.35
        static let animationDampingFraction = 0.85
    }

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            withAnimation(.spring(
                                response: Constants.animationSpringResponse,
                                dampingFraction: Constants.animationDampingFraction
                            )) {
                                if scale < 1.0 {
                                    scale = 1.0
                                } else {
                                    scale = min(scale, 5.0)
                                }

                                lastScale = scale
                            }
                        }
                )
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation(.spring(
                                response: Constants.animationSpringResponse,
                                dampingFraction: Constants.animationDampingFraction
                            )) {
                                scale = 1.0
                                lastScale = 1.0
                            }
                        }
                )
        } placeholder: {
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
