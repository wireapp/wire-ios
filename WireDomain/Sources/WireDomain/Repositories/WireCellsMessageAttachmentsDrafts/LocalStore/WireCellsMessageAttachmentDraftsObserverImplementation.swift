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
import WireCellsAPI
import WireDataModel

public final actor WireCellsMessageAttachmentDraftsObserverImplementation: NSObject, NSFetchedResultsControllerDelegate,
    FetchedResultsControllerObserver {

    private var currentValues: [WireCellsAPI.WireCellsMessageAttachmentDraft] = []
    private var continuations: [UUID: AsyncStream<[WireCellsAPI.WireCellsMessageAttachmentDraft]>.Continuation] = [:]
    private let fetchedResultsController: NSFetchedResultsController<WireCellsMessageAttachmentDraftEntity>

    init(
        fetchedResultsController: NSFetchedResultsController<WireCellsMessageAttachmentDraftEntity>,
        initialValues: [WireCellsAPI.WireCellsMessageAttachmentDraft]
    ) async throws {

        self.fetchedResultsController = fetchedResultsController
        self.currentValues = initialValues
        super.init()

        fetchedResultsController.delegate = self

        send(newValues: initialValues)
    }

    public nonisolated func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        guard let entities = controller.fetchedObjects as? [WireCellsMessageAttachmentDraftEntity] else { return }
        let mappedEntities = entities.map { $0.toModel() }
        Task { await send(newValues: mappedEntities) }
    }

    public func observe() -> AsyncStream<[WireCellsAPI.WireCellsMessageAttachmentDraft]> {
        let id = UUID()
        return AsyncStream<[WireCellsAPI.WireCellsMessageAttachmentDraft]> { continuation in
            continuations[id] = continuation

            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in await self?.removeContinuation(for: id) }
            }
        }
    }

    // MARK: - Private methods

    private func send(newValues: [WireCellsMessageAttachmentDraft]) {
        currentValues = newValues.map(\.self)
        for continuation in continuations.values {
            continuation.yield(currentValues)
        }
    }

    private func removeContinuation(for id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
