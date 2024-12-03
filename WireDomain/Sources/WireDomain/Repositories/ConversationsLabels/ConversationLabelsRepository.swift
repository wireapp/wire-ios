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
    private let conversationLabelsLocalStore: any ConversationLabelsLocalStoreProtocol
    private let logger = WireLogger(tag: "conversation-labels")

    // MARK: - Object lifecycle

    init(
        userPropertiesAPI: any UserPropertiesAPI,
        conversationLabelsLocalStore: any ConversationLabelsLocalStoreProtocol
    ) {
        self.userPropertiesAPI = userPropertiesAPI
        self.conversationLabelsLocalStore = conversationLabelsLocalStore
    }

    // MARK: - Public

    public func pullConversationLabels() async throws {
        let conversationLabels = try await userPropertiesAPI.getLabels()
        try await updateConversationLabels(conversationLabels)
    }

    public func updateConversationLabels(
        _ conversationLabels: [ConversationLabel]
    ) async throws {
        await storeLabelsLocally(conversationLabels)

        try await conversationLabelsLocalStore.deleteOldLabelsLocally(
            excludedLabels: conversationLabels.map { $0.toDomainModel() }
        )
    }

    // MARK: - Private

    private func storeLabelsLocally(
        _ conversationLabels: [ConversationLabel]
    ) async {
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for conversationLabel in conversationLabels {
                taskGroup.addTask { [self] in
                    try await conversationLabelsLocalStore.storeLabel(
                        conversationLabel.toDomainModel()
                    )
                }
            }

            /// Iterates through the group child tasks results and logs the error if any.
            while let result = await taskGroup.nextResult() {
                switch result {
                case .success:
                    continue
                case let .failure(error):
                    let repoError = error as? ConversationLabelsLocalStore.Failure
                    if case let .failedToStoreLabelLocally(id) = repoError {
                        logger
                            .error(
                                "Failed to store conversation label with id \(id.safeForLoggingDescription): \(error)"
                            )
                    } else {
                        logger.error("Failed to store conversation with error: \(error)")
                    }
                }
            }
        }
    }
}
