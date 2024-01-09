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

import Foundation
import WireDataModel

final class DeveloperDebugActionsViewModel: ObservableObject {

    @Published var buttons: [DeveloperDebugActionsDisplayModel.ButtonItem] = []

    private let selfClient: UserClient?

    init(selfClient: UserClient?) {
        self.selfClient = selfClient

        // self is initialized

        buttons = [
//            .init(title: "Send debug logs", action: sendDebugLogs)),
//            .init(title: "Perform quick sync", action: performQuickSync)),
//            .init(title: "Break next quick sync", action: breakNextQuickSync)),
            .init(title: "Update Conversation to mixed protocol", action: updateConversationProtocolToMixed),
            .init(title: "Update Conversation to MLS protocol", action: updateConversationProtocolToMLS)
        ]
    }

    // MARK: - Protocol Change

    private func updateConversationProtocolToMixed() {
        updateConversationProtocol(to: .mixed)
    }

    private func updateConversationProtocolToMLS() {
        updateConversationProtocol(to: .mls)
    }

    private func updateConversationProtocol(to messageProtocol: MessageProtocol) {
        guard
            let selfClient = selfClient,
            let context = selfClient.managedObjectContext
        else { return }

        Task {
            guard let qualifiedID = await context.perform({ selfClient.user?.conversations.first?.qualifiedID }) else {
                assertionFailure("no conversation found to update protocol change")
                return
            }

            var action = UpdateConversationProtocolAction(
                qualifiedID: qualifiedID,
                messageProtocol: messageProtocol
            )

            do {
                try await action.perform(in: context.notificationContext)
            } catch {
                assertionFailure("action failed: \(error)!")
            }
        }
    }
}
