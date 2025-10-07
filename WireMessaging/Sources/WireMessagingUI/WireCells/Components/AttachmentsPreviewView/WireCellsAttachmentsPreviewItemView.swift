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
        WireCellsDocumentAttachmentPreview(
            headerIcon: Image(viewModel.icon),
            headerText: viewModel.headerText,
            labelText: viewModel.fileName,
            progress: viewModel.progress,
            isError: viewModel.isError,
        )
        .frame(height: 74)
        .frame(idealWidth: 288)
        .onTapGesture(perform: `open`)
        .quickLookPreview($viewModel.viewingURL)
    }

    private func open() {
        Task { await viewModel.open() }
    }

}

// MARK: - Preview

@MainActor
private func makeViewModel() -> WireCellsAttachmentsPreviewItemViewModel {
    let localAssetRepository = MockWireCellsLocalAssetRepositoryProtocol()
    localAssetRepository.observeAssetNodeID_MockValue = AnyPublisher(Just(nil))

    let fileCache = MockFileCache()
    fileCache.fileURLForKey_MockValue = URL(filePath: "something")

    return WireCellsAttachmentsPreviewItemViewModel(
        item: WireCellsAttachmentsPreviewViewItem(
            nodeID: UUID(),
            fileIcon: .document,
            fileName: "Some file",
            fileExtension: "pdf",
            fileSize: 100,
            isDeleted: false
        ),
        getAssetUseCase: WireCellsGetAssetUseCase(
            localAssetRepository: localAssetRepository,
            fileCache: fileCache
        ),
        localAssetRepository: localAssetRepository,
        lastOpenRequest: WireCellsLastOpenRequest()
    )
}

#Preview {
    WireCellsAttachmentsPreviewItemView(viewModel: makeViewModel())
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
}
