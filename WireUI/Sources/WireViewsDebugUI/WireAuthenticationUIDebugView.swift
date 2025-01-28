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
import WireAuthenticationUI

public struct WireAuthenticationUIDebugView: View {

    enum PresentationItem: String, Identifiable {
        var id: String { rawValue }

        case background
        case switchBackend

    }

    @State private var presentedItem: PresentationItem?

    public init() {}

    public var body: some View {
        List {
            Button(
                action: { presentedItem = .background },
                label: { Text("Background") }
            )
            Button(
                action: { presentedItem = .switchBackend },
                label: { Text("Switch backend confirmation") }
            )
        }
        .fullScreenCover(item: $presentedItem, content: { item in
            switch item {
            case .background:
                fullscreenCover(content: { BackgroundView() })
            case .switchBackend:
                fullscreenCover(content: {
                    BackgroundView()
                        .overlay(
                            ZStack {
                                SwitchBackendConfirmationViewPreview()
                                    .padding()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                })
            }
        })
    }

    @ViewBuilder
    private func fullscreenCover(content: () -> some View) -> some View {
        content()
            .overlay {
                HStack {
                    Spacer()
                    VStack {
                        Button(
                            action: { presentedItem = nil },
                            label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.largeTitle)
                            }
                        )
                        .frame(width: 50, height: 50)
                        Spacer()
                    }
                }
                .padding(.top, 40)
                .padding(.trailing, 20)
            }
    }
}

#Preview {
    NavigationView {
        WireAuthenticationUIDebugView()
    }
}
