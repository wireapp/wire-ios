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

import Combine
package import SwiftUI
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport

/// A collection of attachment previews suitable for displaying in a conversation message.
package struct WireCellsAttachmentsPreviewView: View {

    @StateObject var viewModel: WireCellsAttachmentsPreviewViewModel

    package init(viewModel: @autoclosure @escaping () -> WireCellsAttachmentsPreviewViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    package var body: some View {
        FlowLayout(alignment: viewModel.alignment) {
            ForEach(Array(viewModel.attachments.enumerated()), id: \.element) { index, _ in
                itemRow(index: index)
            }
        }
        .frame(maxWidth: .infinity, alignment: viewModel.alignment == .leading ? .leading : .trailing)
    }

    @ViewBuilder
    func itemRow(index: Int) -> some View {
        WireCellsAttachmentsPreviewItemView(viewModel: viewModel.itemViewModel(index: index))
    }
}

// MARK: - Preview

#Preview {
    WireCellsAttachmentsPreviewView(viewModel: .makePreview())
}
