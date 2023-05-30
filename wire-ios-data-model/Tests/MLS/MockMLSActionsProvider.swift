//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
@testable import WireDataModel

class MockMLSActionsProvider: MLSActionsProviderProtocol {

    enum MockError: Error {

        case unmockedMethodInvoked

    }

    typealias FetchBackendPublicKeysMock = () -> BackendMLSPublicKeys
    var fetchBackendPublicKeysMocks = [FetchBackendPublicKeysMock]()

    func fetchBackendPublicKeys(in context: NotificationContext) async throws -> BackendMLSPublicKeys {
        guard let mock = fetchBackendPublicKeysMocks.first else { throw MockError.unmockedMethodInvoked }
        fetchBackendPublicKeysMocks.removeFirst()
        return mock()
    }

    typealias CountUnclaimedKeyPackagesMock = (String) -> Int
    var countUnclaimedKeyPackagesMocks = [CountUnclaimedKeyPackagesMock]()

    func countUnclaimedKeyPackages(
        clientID: String,
        context: NotificationContext
    ) async throws -> Int {
        guard let mock = countUnclaimedKeyPackagesMocks.first else { throw MockError.unmockedMethodInvoked }
        countUnclaimedKeyPackagesMocks.removeFirst()
        return mock(clientID)
    }

    typealias UploadKeyPackagesMock = (String, [String]) -> Void
    var uploadKeyPackagesMocks = [UploadKeyPackagesMock]()

    func uploadKeyPackages(
        clientID: String,
        keyPackages: [String],
        context: NotificationContext
    ) async throws {
        guard let mock = uploadKeyPackagesMocks.first else { throw MockError.unmockedMethodInvoked }
        uploadKeyPackagesMocks.removeFirst()
        return mock(clientID, keyPackages)
    }

    typealias ClaimKeyPackagesMock = (UUID, String?, String?) -> [KeyPackage]
    var claimKeyPackagesMocks = [ClaimKeyPackagesMock]()

    func claimKeyPackages(
        userID: UUID,
        domain: String?,
        excludedSelfClientID: String?,
        in context: NotificationContext
    ) async throws -> [KeyPackage] {
        guard let mock = claimKeyPackagesMocks.first else { throw MockError.unmockedMethodInvoked }
        claimKeyPackagesMocks.removeFirst()
        return mock(userID, domain, excludedSelfClientID)
    }

    typealias SendMessageMock = (Data) -> [ZMUpdateEvent]
    var sendMessageMocks = [SendMessageMock]()

    func sendMessage(
        _ message: Data,
        in context: NotificationContext
    ) async throws -> [ZMUpdateEvent] {
        guard let mock = sendMessageMocks.first else { throw MockError.unmockedMethodInvoked }
        sendMessageMocks.removeFirst()
        return mock(message)
    }

    typealias SendCommitBundleMock = (Data) throws -> [ZMUpdateEvent]
    var sendCommitBundleMocks = [SendCommitBundleMock]()

    func sendCommitBundle(
        _ bundle: Data,
        in context: NotificationContext
    ) async throws -> [ZMUpdateEvent] {
        guard let mock = sendCommitBundleMocks.first else { throw MockError.unmockedMethodInvoked }
        sendCommitBundleMocks.removeFirst()
        return try mock(bundle)
    }

    typealias FetchPublicGroupStateMock = (UUID, String) -> Data
    var fetchPublicGroupStateMock = [FetchPublicGroupStateMock]()

    func fetchPublicGroupState(
        conversationId: UUID,
        domain: String,
        context: NotificationContext
    ) async throws -> Data {
        guard let mock = fetchPublicGroupStateMock.first else { throw MockError.unmockedMethodInvoked }
        fetchPublicGroupStateMock.removeFirst()
        return mock(conversationId, domain)
    }

}
