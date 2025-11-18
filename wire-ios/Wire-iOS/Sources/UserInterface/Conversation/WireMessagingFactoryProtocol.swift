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

import Foundation
import SwiftUI
import UIKit
import WireFoundation
import WireMessagingAssembly
import WireMessagingDomain
import WireMessagingUI

// sourcery: AutoMockable
protocol WireMessagingFactoryProtocol {

    func makeUploadDraftUseCase(cellName: String) -> WireCellsUploadDraftUseCaseProtocol
    func makeObserveDraftsUseCase(cellName: String) -> WireCellsObserveDraftsUseCaseProtocol
    func makePublishDraftsUseCase(cellName: String) -> WireCellsPublishDraftsUseCaseProtocol
    func makeClearPublishedDraftsUseCase(cellName: String) -> WireCellsClearPublishedDraftsUseCaseProtocol
    func makeDeleteDraftUseCase(cellName: String) -> WireCellsDeleteDraftUseCaseProtocol
    func makeRetryUploadDraftUseCase(cellName: String) -> WireCellsRetryUploadDraftUseCaseProtocol
    func makeDeleteNodesUseCase() -> WireCellsDeleteNodesUseCaseProtocol
    @MainActor
    func makeFilesView(
        cellName: String,
        isCellsStatePending: Bool,
        accentColor: WireAccentColor
    ) -> UIViewController

    @MainActor
    func makeFilesBrowserView(accentColor: WireAccentColor) -> UIViewController
    
    @MainActor
    func makeAttachmentsPreviewView(
        attachments: [WireCellsMessageAttachment],
        alignment: HorizontalAlignment
    ) -> UIViewController
    func makeConversationCellProvider(
        insetsProvider: @escaping () -> ConversationCellInsets
    ) -> ConversationCellProviderProtocol

}

// sourcery: AutoMockable
protocol ConversationCellProviderProtocol {

    @MainActor
    func provideCell(
        for model: ConversationCellModel,
        tableView: UITableView,
        indexPath: IndexPath
    ) -> UITableViewCell

}

extension WireMessagingFactory: WireMessagingFactoryProtocol {

    func makeConversationCellProvider(
        insetsProvider: @escaping () -> ConversationCellInsets
    ) -> ConversationCellProviderProtocol {
        // swiftformat:disable:next redundantProperty
        let provider: ConversationCellProvider = makeConversationCellProvider(insetsProvider: insetsProvider)
        return provider
    }

}

extension ConversationCellProvider: ConversationCellProviderProtocol {}
