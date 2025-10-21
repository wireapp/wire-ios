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
import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport

struct WireCellsAttachmentsPreviewItemView: View {
    @StateObject private var viewModel: WireCellsAttachmentsPreviewItemViewModel

    init(viewModel: @autoclosure @escaping () -> WireCellsAttachmentsPreviewItemViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        Group {
            switch viewModel.kind {
            case .smallImage:
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case .largeImage(let aspectRatio, let maxWidth):
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case .smallVideo:
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case .largeVideo(let aspectRatio):
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case .smallDocument:
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case .largeDocument:
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case .audio:
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            }
        }
        .onAppear(perform: refresh)
        .onTapGesture(perform: open)
        .quickLookPreview($viewModel.viewingURL)
    }

    private func refresh() {
        Task { await viewModel.refresh() }
    }

    private func open() {
        Task { await viewModel.open() }
    }

}

// MARK: - Preview

#Preview {
    WireCellsAttachmentsPreviewItemView(
        viewModel: WireCellsAttachmentsPreviewViewModel.makePreview().itemViewModel(index: 0)
    )
    .environment(\.wireTextStyleMapping, WireTextStyleMapping())
}
