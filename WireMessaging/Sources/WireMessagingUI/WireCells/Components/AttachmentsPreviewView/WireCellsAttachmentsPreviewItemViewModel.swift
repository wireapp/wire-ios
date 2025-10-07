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
import Foundation
import WireMessagingDomain

@MainActor
final class WireCellsAttachmentsPreviewItemViewModel: ObservableObject {

    private let item: WireCellsAttachmentsPreviewViewItem
    private let getAssetUseCase: WireCellsGetAssetUseCase
    private let lastOpenRequest: WireCellsLastOpenRequest
    private var cancellables = Set<AnyCancellable>()

    let headerText: String
    let fileName: String

    @Published var viewingURL: URL?
    @Published private var asset: WireCellsLocalAsset?

    init(
        item: WireCellsAttachmentsPreviewViewItem,
        getAssetUseCase: WireCellsGetAssetUseCase,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        lastOpenRequest: WireCellsLastOpenRequest
    ) {
        self.item = item
        self.getAssetUseCase = getAssetUseCase
        self.lastOpenRequest = lastOpenRequest

        if item.isDeleted {
            self.headerText = ""
            self.fileName = L10n.Localizable.Conversation.Message.Attachment.notAvailable
        } else {
            let fileSize = (item.fileSize?.formatted(.byteCount(style: .decimal)) as String?).map { "(\($0))" }
            self.headerText = [item.fileExtension?.uppercased(), fileSize].compactMap { $0 }.joined(separator: " ")
            self.fileName = [item.fileName, item.fileExtension].compactMap { $0 }.joined(separator: ".")
        }

        localAssetRepository.observeAsset(nodeID: item.nodeID).sink { [self] asset in
            self.asset = asset
        }.store(in: &cancellables)
    }

    var icon: ImageResource {
        item.isDeleted ? .fileIconNotAvailable : item.fileIcon.resource
    }

    var progress: Double {
        switch asset?.downloadState {
        case let .downloading(progress):
            progress
        case .failed:
            1 // We show a full red progress bar on failure
        default:
            0
        }
    }

    var isError: Bool {
        switch asset?.downloadState {
        case .failed:
            true
        default:
            false
        }
    }

    func open() async {
        guard !item.isDeleted else { return }

        // FIXME: check not in progress

        lastOpenRequest.nodeID = item.nodeID

        do {
            let url = try await getAssetUseCase.invoke(nodeID: item.nodeID)
            if lastOpenRequest.nodeID == item.nodeID {
                viewingURL = url
            }
        } catch {
            // FIXME: Handle error
        }
    }

}
