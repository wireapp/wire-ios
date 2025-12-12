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

public import UIKit
import SwiftUI
package import WireMessagingDomain

public final class ConversationCellProvider {

    private let fetchNodeUseCase: WireCellsFetchNodeUseCase
    private let getAssetUseCase: WireCellsGetAssetUseCase
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private let lastOpenRequest: WireCellsLastOpenRequest
    private let nodeRenameNotifier: WireCellsNodeRenameNotifier
    private let insetsProvider: () -> ConversationCellInsets

    package init(
        fetchNodeUseCase: WireCellsFetchNodeUseCase,
        getAssetUseCase: WireCellsGetAssetUseCase,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        lastOpenRequest: WireCellsLastOpenRequest,
        nodeRenameNotifier: WireCellsNodeRenameNotifier,
        insetsProvider: @escaping () -> ConversationCellInsets
    ) {
        self.fetchNodeUseCase = fetchNodeUseCase
        self.getAssetUseCase = getAssetUseCase
        self.localAssetRepository = localAssetRepository
        self.lastOpenRequest = lastOpenRequest
        self.insetsProvider = insetsProvider
        self.nodeRenameNotifier = nodeRenameNotifier
    }

    @MainActor
    public func provideCell(
        for model: ConversationCellModel,
        tableView: UITableView,
        indexPath: IndexPath,
        onLongPress: @escaping (UITableViewCell) -> Void
    ) -> UITableViewCell {
        model.registerIfNeeded(in: tableView)
        let cell = tableView.dequeueReusableCell(withIdentifier: model.cellReuseIdentifier, for: indexPath)
        configureCell(cell, with: model, onLongPress: onLongPress)

        return cell
    }

    @MainActor
    private func configureCell(
        _ cell: UITableViewCell,
        with model: ConversationCellModel,
        onLongPress: @escaping (UITableViewCell) -> Void
    ) {
        switch model {

        case let .timeDivider(model):
            guard let cell = cell as? ConversationCell<TimeDividerModel> else { break }
            cell.model = model

        case let .multipartAttachments(model):
            guard let cell = cell as? MultipartAttachmentsConversationCell else { break }

            let insets = insetsProvider().insets(
                isSentBySelfUser: model.isSentBySelfUser
            )
            let viewModel = WireCellsAttachmentsPreviewViewModel(
                attachments: model.attachments,
                alignment: model.isSentBySelfUser ? .trailing : .leading,
                fetchNodeUseCase: fetchNodeUseCase,
                getAssetUseCase: getAssetUseCase,
                localAssetRepository: localAssetRepository,
                lastOpenRequest: lastOpenRequest,
                nodeRenameNotifier: nodeRenameNotifier
            )
            cell.configure(
                content: WireCellsAttachmentsPreviewView(viewModel: viewModel),
                insets: EdgeInsets(top: 0, leading: insets.leading, bottom: 0, trailing: insets.trailing),
                onLongPress: onLongPress
            )
        }
    }

}

private extension ConversationCellInsets {

    func insets(isSentBySelfUser: Bool) -> HorizontalInsets {
        isSentBySelfUser ? trailingBubble : leadingBubble
    }

}
