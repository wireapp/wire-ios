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
            switch viewModel.fileCategory {
            case .image where viewModel.displaySmall:
                WireCellsImageConversationAttachmentPreview(
                    thumbnailURL: viewModel.imagePreviewURL,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                    noPreviewMessage: nil
                )
                .frame(width: 74, height: 74)
            case .image where viewModel.displayLarge:
                WireCellsImageConversationAttachmentPreview(
                    thumbnailURL: viewModel.imagePreviewURL,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                    noPreviewMessage: L10n.Localizable.Conversation.Message.Attachment.previewNotAvailable
                )
                .aspectRatio(viewModel.previewAspectRatio, contentMode: .fit)
                .frame(
                    idealWidth: min(
                        288,
                        viewModel.previewWidth ?? .infinity,
                        Constants.maxImageHeight * viewModel.previewAspectRatio
                    )
                )
            case .video where viewModel.displaySmall:
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case .video where viewModel.displayLarge:
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case .document where viewModel.displaySmall:
                WireCellsDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    progress: viewModel.progress,
                    isError: viewModel.isError,
                )
                .frame(height: 74)
                .frame(idealWidth: 288)
            case .document where viewModel.displayLarge:
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
            default:
                unsupportedPreview()
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

    private func unsupportedPreview() -> some View {
        assertionFailure("Unsupported file category")
        return EmptyView()
    }

}

// MARK: - Preview

#Preview {
    WireCellsAttachmentsPreviewItemView(
        viewModel: WireCellsAttachmentsPreviewViewModel.makePreview().itemViewModel(index: 0)
    )
    .environment(\.wireTextStyleMapping, WireTextStyleMapping())
}
