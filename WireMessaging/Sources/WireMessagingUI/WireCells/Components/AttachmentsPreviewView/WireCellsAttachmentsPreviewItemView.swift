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

    private enum Constants {
        static let maxImageHeight: Double = 400
    }

    @StateObject private var viewModel: WireCellsAttachmentsPreviewItemViewModel

    init(viewModel: @autoclosure @escaping () -> WireCellsAttachmentsPreviewItemViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        HStack {
            switch (viewModel.fileCategory, viewModel.displayStyle) {
            case (.image, .small):
                WireCellsImageConversationAttachmentPreview(
                    thumbnailURL: viewModel.imagePreviewURL,
                    progress: viewModel.progress,
                    isAssetDownloadError: viewModel.isAssetDownloadError,
                    canShowNoPreviewMessage: false
                )
                .frame(width: 74, height: 74)
            case (.image, .large):
                WireCellsImageConversationAttachmentPreview(
                    thumbnailURL: viewModel.imagePreviewURL,
                    progress: viewModel.progress,
                    isAssetDownloadError: viewModel.isAssetDownloadError,
                    canShowNoPreviewMessage: true
                )
                .aspectRatio(viewModel.previewAspectRatio, contentMode: .fit)
                .frame(
                    idealWidth: min(
                        288,
                        viewModel.previewWidth ?? .infinity,
                        Constants.maxImageHeight * viewModel.previewAspectRatio
                    )
                )
            case (.video, .small):
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isAssetDownloadError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case (.video, .large):
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isAssetDownloadError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case (.document, .small):
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isAssetDownloadError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case (.document, .large):
                WireCellsLargeDocumentPreviewView(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    downloadError: viewModel.isAssetDownloadError,
                    url: viewModel.imagePreviewURL,
                )
                .frame(idealWidth: 288)
            case (.audio, .small), (.audio, .large):
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isAssetDownloadError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            }
        }
        .contentShape(Rectangle()) // Constrains the tappable content area of the view.
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
}
