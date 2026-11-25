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

import Testing
import WireDataModelSupport
import WireMockTransport
import WireNetworkSupport
import WireSystem

@testable import WireSyncEngine

struct SearchUsersUseCaseTests {

    private let coreDataHelper = CoreDataStackHelper()
    private let modelHelper = ModelHelper()

    @Test @MainActor // `MockTransportSession` must be created on the main thread
    func refreshesIncompleteMetadataOnlyOnFirstSearch() async throws {
        // Given
        let stack = try await coreDataHelper.createStack()
        await stack.syncContext.perform { [modelHelper] in
            modelHelper.createSelfUser(in: stack.syncContext)
            stack.syncContext.saveOrRollback()
        }

        let usersActionCounter = Counter()
        let conversationsActionCounter = Counter()
        let searchDirectory = SearchDirectory(
            contextProvider: stack,
            transportSession: MockTransportSession(dispatchGroup: ZMSDispatchGroup(label: "SearchUsersUseCaseTests")),
            searchUsersCache: SearchUsersCache(),
            refreshUsersMissingMetadataAction: .counting(with: usersActionCounter),
            refreshConversationsMissingMetadataAction: .counting(with: conversationsActionCounter),
            apiVersion: nil,
            searchAPI: MockSearchAPI(),
            teamsAPI: MockTeamsAPI(),
            usersAPI: MockUsersAPI()
        )
        let sut = SearchUsersUseCase(
            context: stack.syncContext,
            searchDirectory: searchDirectory,
            isFederationUsageAllowed: false,
            isMLSEnabled: false
        )

        // When searching on each keystroke
        for query in ["", "a", "ab"] {
            _ = await sut.invoke(query: query, options: .contacts, messageProtocol: nil)
        }

        // Then
        #expect(usersActionCounter.count == 1)
        #expect(conversationsActionCounter.count == 1)
    }

}

private final class Counter {
    var count = 0
}

private extension RecurringAction {

    static func counting(with counter: Counter) -> Self {
        .init(
            id: .randomAlphanumerical(length: 16),
            shouldRunEveryLaunch: false,
            interval: .infinity
        ) {
            counter.count += 1
        }
    }

}
