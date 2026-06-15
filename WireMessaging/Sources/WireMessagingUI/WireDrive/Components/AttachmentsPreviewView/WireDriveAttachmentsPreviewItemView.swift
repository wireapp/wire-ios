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

import Combine
import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport

struct WireDriveAttachmentsPreviewItemView: View {

    private enum Constants {
        static let maxImageHeight: Double = 400
    }

    @StateObject private var viewModel: WireDriveAttachmentsPreviewItemViewModel

    init(viewModel: @autoclosure @escaping () -> WireDriveAttachmentsPreviewItemViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        Group {
            switch (viewModel.fileCategory, viewModel.displayStyle) {
            case (.image, .small):
                WireDriveImageConversationAttachmentPreview(
                    thumbnailURL: viewModel.imagePreviewURL,
                    state: viewModel.fileTracker.state,
                    isLargePreview: false,
                    isAvailableOffline: viewModel.isAvailableOffline
                )
                .frame(width: 120, height: 120)
            case (.image, .large):
                WireDriveImageConversationAttachmentPreview(
                    thumbnailURL: viewModel.imagePreviewURL,
                    state: viewModel.fileTracker.state,
                    isLargePreview: true,
                    isAvailableOffline: viewModel.isAvailableOffline
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
                WireDriveSmallVideoPreviewView(
                    url: viewModel.imagePreviewURL,
                    state: viewModel.fileTracker.state,
                    duration: viewModel.attachmentDuration,
                    isAvailableOffline: viewModel.isAvailableOffline
                )
            case (.video, .large):
                WireDriveLargeVideoPreviewView(
                    url: viewModel.imagePreviewURL,
                    imageAspectRatio: viewModel.previewAspectRatio,
                    duration: viewModel.attachmentDuration,
                    state: viewModel.fileTracker.state,
                    isAvailableOffline: viewModel.isAvailableOffline
                )
                .frame(idealWidth: 288)
            case (.document, .small):
                WireDriveDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    state: viewModel.fileTracker.state,
                    isDraftPreview: false,
                    isAvailableOffline: viewModel.isAvailableOffline
                )
                .frame(idealWidth: 288)
            case (.document, .large):
                WireDriveLargeDocumentPreviewView(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    url: viewModel.imagePreviewURL,
                    state: viewModel.fileTracker.state,
                    isDraftPreview: false,
                    isAvailableOffline: viewModel.isAvailableOffline
                )
                .frame(idealWidth: 288)
            case (.audio, .small), (.audio, .large):
                WireDriveDocumentAttachmentPreview(
                    headerIcon: Image(viewModel.icon),
                    headerText: viewModel.headerText,
                    labelText: viewModel.fileName,
                    state: viewModel.fileTracker.state,
                    isDraftPreview: false,
                    isAvailableOffline: viewModel.isAvailableOffline
                )
                .frame(idealWidth: 288)
            }
        }
        .contentShape(Rectangle()) // Constrains the tappable content area of the view.
        .onAppear(perform: viewModel.startPolling)
        .onDisappear(perform: viewModel.stopPolling)
        .onTapGesture(perform: onTap)
        .quickFilePreview($viewModel.quickPreviewItem)
    }

    private func refresh() {
        Task { await viewModel.refresh() }
    }

    private func onTap() {
        Task { await viewModel.handleAsset() }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        WireDriveAttachmentsPreviewItemView(
            viewModel: WireDriveAttachmentsPreviewViewModel.makePreview().itemViewModel(index: 0)
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.gray)
}
