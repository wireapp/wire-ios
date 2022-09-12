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

    var mockReturnValueForFetchBackendPublicKeys: BackendMLSPublicKeys?

    func fetchBackendPublicKeys(in context: NotificationContext) async throws -> BackendMLSPublicKeys {
        return mockReturnValueForFetchBackendPublicKeys ?? BackendMLSPublicKeys()
    }

    var mockCountUncliamedKeyPackagesResult: Swift.Result<CountSelfMLSKeyPackagesAction.Result, CountSelfMLSKeyPackagesAction.Failure>?

    func countUnclaimedKeyPackages(
        clientID: String,
        context: NotificationContext,
        resultHandler: @escaping CountSelfMLSKeyPackagesAction.ResultHandler
    ) {
        resultHandler(mockCountUncliamedKeyPackagesResult ?? .failure(.unknown(status: 999)))
    }

    var mockUploadKeyPackagesResult: Swift.Result<UploadSelfMLSKeyPackagesAction.Result, UploadSelfMLSKeyPackagesAction.Failure>?

    func uploadKeyPackages(
        clientID: String,
        keyPackages: [String],
        context: NotificationContext,
        resultHandler: @escaping UploadSelfMLSKeyPackagesAction.ResultHandler
    ) {
        resultHandler(mockUploadKeyPackagesResult ?? .failure(.unknown(status: 999)))
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

    typealias SendWelcomeMessageMock = (Data) -> Void
    var sendWelcomeMessageMocks = [SendWelcomeMessageMock]()

    func sendWelcomeMessage(
        _ welcomeMessage: Data,
        in context: NotificationContext
    ) async throws {
        guard let mock = sendWelcomeMessageMocks.first else { throw MockError.unmockedMethodInvoked }
        sendWelcomeMessageMocks.removeFirst()
        return mock(welcomeMessage)
    }

}
