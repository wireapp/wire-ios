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

package import SwiftUI
import WireMessagingDomain
import WireFoundation

/// A collection of attachment previews suitable for displaying in a conversation message.
package struct WireCellsAttachmentsPreviewView: View {

    @StateObject var viewModel: WireCellsAttachmentsPreviewViewModel

    init(viewModel: @autoclosure @escaping () -> WireCellsAttachmentsPreviewViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    package var body: some View {
        FlowLayout {
            ForEach(Array(viewModel.items.enumerated()), id: \.element) { index, item in
                itemRow(index: index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func itemRow(index: Int) -> some View {
        WireCellsAttachmentsPreviewItemView(viewModel: viewModel.itemViewModel(index: index))
    }
}

#Preview {
    WireCellsAttachmentsPreviewView(
        viewModel: WireCellsAttachmentsPreviewViewModel(
            attachments: [
                WireCellsMessageAttachment(
                    nodeID: UUID(),
                    contentType: "image/png",
                    initialName: "Picture.png",
                    initialSize: 1000,
                    initialMetadata: nil
                ),
                WireCellsMessageAttachment(
                    nodeID: UUID(),
                    contentType: "video/mp4",
                    initialName: "Video.mp4",
                    initialSize: 2000,
                    initialMetadata: nil
                ),
                WireCellsMessageAttachment(
                    nodeID: UUID(),
                    contentType: "application/pdf",
                    initialName: "Document.pdf",
                    initialSize: 3000,
                    initialMetadata: nil
                )
            ]
        )
    )
    .environment(\.wireTextStyleMapping, WireTextStyleMapping())
}
