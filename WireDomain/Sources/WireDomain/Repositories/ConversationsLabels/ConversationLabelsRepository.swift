//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import CoreData
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// Facilitates access to conversation labels related domain objects.
public protocol ConversationLabelsRepositoryProtocol {

    /// Pulls conversation labels from the server and stores locally

    func pullConversationLabels() async throws

    /// Updates conversation labels locally
    /// - parameters:
    ///     - conversationLabels: The conversation labels to update locally.

    func updateConversationLabels(
        _ conversationLabels: [ConversationLabel]
    ) async throws
}

public class ConversationLabelsRepository: ConversationLabelsRepositoryProtocol {

    // MARK: - Properties

    private let userPropertiesAPI: any UserPropertiesAPI
    private let context: NSManagedObjectContext
    private let logger = WireLogger(tag: "conversation-labels")

    // MARK: - Object lifecycle

    init(
        userPropertiesAPI: any UserPropertiesAPI,
        context: NSManagedObjectContext
    ) {
        self.userPropertiesAPI = userPropertiesAPI
        self.context = context
    }

    // MARK: - Public

    /// Retrieve from backend and store conversation labels locally

    public func pullConversationLabels() async throws {
        let conversationLabels = try await userPropertiesAPI.getLabels()
        await storeLabelsLocally(conversationLabels)
        try await deleteOldLabelsLocally(excludedLabels: conversationLabels)
    }

    public func updateConversationLabels(
        _ conversationLabels: [ConversationLabel]
    ) async throws {
        await storeLabelsLocally(conversationLabels)
        try await deleteOldLabelsLocally(excludedLabels: conversationLabels)
    }

    // MARK: - Private

    private func storeLabelsLocally(
        _ conversationLabels: [ConversationLabel]
    ) async {
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for conversationLabel in conversationLabels {
                taskGroup.addTask { [self] in
                    try await storeLabelLocally(conversationLabel)
                }
            }

            /// Iterates through the group child tasks results and logs the error if any.
            while let result = await taskGroup.nextResult() {
                switch result {
                case .success:
                    continue
                case .failure(let error):
                    let repoError = error as? ConversationLabelsRepositoryError
                    if case .failedToStoreLabelLocally(let label) = repoError {
                        logger.error("Failed to store conversation label with id \(label.id): \(error)")
                    } else {
                        logger.error("Failed to store conversation with error: \(error)")
                    }

                    continue
                }
            }
        }
    }

    /// Save label and related conversations objects to local storage.
    /// - Parameter conversationLabel: conversation label from WireAPI

    private func storeLabelLocally(
        _ conversationLabel: ConversationLabel
    ) async throws {
        try await context.perform { [context] in
            var created = false
            let label: Label? = if conversationLabel.type == Label.Kind.favorite.rawValue {
                Label.fetchFavoriteLabel(in: context)
            } else {
                Label.fetchOrCreate(remoteIdentifier: conversationLabel.id, create: true, in: context, created: &created)
            }

            guard let label else {
                throw ConversationLabelsRepositoryError.failedToStoreLabelLocally(conversationLabel)
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
                throw ConversationLabelsRepositoryError.failedToStoreLabelLocally(conversationLabel)
            }
        }
    }

    /// Delete old `folder` labels and related conversations objects from local storage.
    /// - Parameter excludedLabels: remote labels that should be excluded from deletion.
    /// - Only old labels of type `folder` are deleted, `favorite` labels always remain in the local storage.

    private func deleteOldLabelsLocally(
        excludedLabels remoteLabels: [ConversationLabel]
    ) async throws {
        try await context.perform { [self] in
            let uuids = remoteLabels.map { $0.id.uuidData as NSData }
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
