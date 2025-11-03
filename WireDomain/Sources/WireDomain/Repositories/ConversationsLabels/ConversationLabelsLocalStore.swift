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

import WireDataModel
import WireLogging

public final class ConversationLabelsLocalStore: ConversationLabelsLocalStoreProtocol {

    // MARK: - Error

    enum Failure: Error {
        case failedToStoreLabelLocally(UUID)
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let logger = WireLogger(tag: "conversation-labels")

    // MARK: - Object lifecycle

    init(
        context: NSManagedObjectContext
    ) {
        self.context = context
    }

    // MARK: - Public

    public func setLabels(
        _ labels: [ConversationLabelInfo]
    ) async throws {
        for label in labels {
            try await storeLabel(label)
        }

        try await deleteOldLabelsLocally(excludedLabels: labels)
    }

    private func storeLabel(
        _ conversationLabel: ConversationLabelInfo
    ) async throws {
        try await context.perform { [context] in
            var created = false
            let label: Label? = if conversationLabel.type == Label.Kind.favorite.rawValue {
                Label.fetchFavoriteLabel(in: context)
            } else {
                Label.fetchOrCreate(
                    remoteIdentifier: conversationLabel.id,
                    create: true,
                    in: context,
                    created: &created
                )
            }

            guard let label else {
                throw Failure.failedToStoreLabelLocally(conversationLabel.id)
            }

            label.name = conversationLabel.name
            label.kind = Label.Kind(rawValue: conversationLabel.type) ?? .folder

            let conversations = ZMConversation.fetchObjects(
                withRemoteIdentifiers: Set(conversationLabel.conversationIDs),
                in: context
            ) as? Set<ZMConversation> ?? Set()

            label.conversations = conversations
            label.modifiedKeys = nil

            do {
                try context.save()
            } catch {
                throw Failure.failedToStoreLabelLocally(conversationLabel.id)
            }
        }
    }

    private func deleteOldLabelsLocally(
        excludedLabels: [ConversationLabelInfo]
    ) async throws {
        try await context.perform { [self] in
            let uuids = excludedLabels.map { $0.id.uuidData as NSData }
            let predicateFormat = "type == \(Label.Kind.folder.rawValue) AND NOT remoteIdentifier_data IN %@"

            let predicate = NSPredicate(
                format: predicateFormat,
                uuids as CVarArg
            )

            let fetchRequest: NSFetchRequest<NSFetchRequestResult>
            fetchRequest = NSFetchRequest(entityName: Label.entityName())
            fetchRequest.predicate = predicate

            /// Since batch operations bypass the context processing,
            /// relationships rules are often ignored (e.g delete rule)
            /// Nevertheless, CoreData automatically handles two specific scenarios:
            /// `Cascade` delete rule and `Nullify` delete rule on an optional property
            /// Since `conversations` is nullify and optional, we can safely perform a batch delete.

            let deleteRequest = NSBatchDeleteRequest(
                fetchRequest: fetchRequest
            )

            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let batchDelete = try context.execute(deleteRequest) as? NSBatchDeleteResult

                guard let deleteResult = batchDelete?.result as? [NSManagedObjectID] else {
                    throw ConversationLabelsRepositoryError.failedToDeleteStoredLabels
                }

                let deletedObjects: [AnyHashable: Any] = [
                    NSDeletedObjectsKey: deleteResult
                ]

                /// Since `NSBatchDeleteRequest` only operates at the SQL level (in the persistent store itself),
                /// we need to manually update our in-memory objects after execution.

                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: deletedObjects,
                    into: [context]
                )

            } catch {
                logger.error("Failed to delete old labels: \(error)")
                throw error
            }
        }
    }

}
