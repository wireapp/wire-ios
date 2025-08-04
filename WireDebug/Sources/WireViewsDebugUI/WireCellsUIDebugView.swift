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

public import SwiftUI

import WireCellsUI

public struct WireCellsUIDebugView: View {

    enum PresentationItem: String, Identifiable {
        var id: String { rawValue }

        case uploadImagePreview
        case uploadVideoPreview
    }

    @State private var presentedItem: PresentationItem?

    public init() {}

    public var body: some View {
        List {
            Section(header: Text("Upload")) {
                Button(
                    action: { presentedItem = .uploadImagePreview },
                    label: { Text("Image Upload Preview") }
                )
                Button(
                    action: { presentedItem = .uploadVideoPreview },
                    label: { Text("Video Upload Preview") }
                )
            }
        }
        .fullScreenCover(item: $presentedItem, content: { _ in
            switch presentedItem {
            case .uploadImagePreview:
                fullscreenCover(content: { EmptyView() })
                    .overlay {
                        UploadImagePreview_Preview(demoImageName: "demo-image")
                    }
            case .uploadVideoPreview:
                fullscreenCover(content: { EmptyView() })
                    .overlay {
                        UploadVideoPreview_Preview(demoThumbnailName: "demo-image")
                    }
            case nil:
                EmptyView()
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
