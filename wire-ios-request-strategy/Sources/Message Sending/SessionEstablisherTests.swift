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

import WireRequestStrategySupport
import XCTest

final class SessionEstablisherTests: MessagingTestBase {
    struct Arrangement {
        // MARK: Lifecycle

        init(coreDataStack: CoreDataStack) {
            self.coreDataStack = coreDataStack

            apiProvider.prekeyAPIApiVersion_MockValue = prekeyApi
        }

        // MARK: Internal

        enum Scaffolding {
            static let clientID = QualifiedClientID(userID: UUID(), domain: "example.com", clientID: "client123")
            static let prekey = Payload.Prekey(key: "prekey123", id: nil)
            static let prekeyByQualifiedUserID =
                [clientID.domain: [clientID.userID.transportString(): [clientID.clientID: prekey]]]
        }

        let selfUserId = UUID()
        let apiProvider = MockAPIProviderInterface()
        let prekeyApi = MockPrekeyAPI()
        let processor = MockPrekeyPayloadProcessorInterface()
        let coreDataStack: CoreDataStack

        func withFetchPrekeyAPI(returning result: Result<Payload.PrekeyByQualifiedUserID, NetworkError>)
            -> Arrangement {
            switch result {
            case let .success(payload):
                prekeyApi.fetchPrekeysFor_MockValue = payload
            case let .failure(error):
                prekeyApi.fetchPrekeysFor_MockError = error
            }
            return self
        }

        func withEstablishSessionsSucceeding() -> Arrangement {
            processor.establishSessionsFromWithContext_MockMethod = { _, _, _ in }
            return self
        }

        func arrange() -> (Arrangement, SessionEstablisher) {
            (self, SessionEstablisher(
                context: coreDataStack.syncContext,
                apiProvider: apiProvider,
                processor: processor
            ))
        }
    }

    func testThatNetworkErrorsArePropagated_whenEstablishingSession() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 500, transportSessionError: nil, apiVersion: 0)
        let networkError = NetworkError.errorDecodingResponse(response)
        let clientID = Arrangement.Scaffolding.clientID
        let (_, sessionEstablisher) = Arrangement(coreDataStack: coreDataStack)
            .withFetchPrekeyAPI(returning: .failure(.errorDecodingResponse(response)))
            .arrange()

        // then
        await assertItThrows(error: networkError) {
            try await sessionEstablisher.establishSession(with: [clientID], apiVersion: .v0)
        }
    }

    func testThatErrorIsPropagated_whenSelfClientHasNotBeenCreated() async throws {
        // given
        await syncMOC.perform { [self] in
            // reset user client associated with the self user
            syncMOC.setPersistentStoreMetadata(nil as String?, key: ZMPersistedClientIdKey)
        }
        let clientID = Arrangement.Scaffolding.clientID
        let (_, sessionEstablisher) = Arrangement(coreDataStack: coreDataStack)
            .arrange()

        // then
        await assertItThrows(error: SessionEstablisherError.missingSelfClient) {
            try await sessionEstablisher.establishSession(with: [clientID], apiVersion: .v0)
        }
    }

    func testThatPrekeysAreFetched_whenEstablishingSession() async throws {
        // given
        let clientID = Arrangement.Scaffolding.clientID
        let (arrangement, sessionEstablisher) = Arrangement(coreDataStack: coreDataStack)
            .withFetchPrekeyAPI(returning: .success(Arrangement.Scaffolding.prekeyByQualifiedUserID))
            .withEstablishSessionsSucceeding()
            .arrange()

        // when
        try await sessionEstablisher.establishSession(with: [clientID], apiVersion: .v0)

        // then
        XCTAssertEqual([[clientID]], arrangement.prekeyApi.fetchPrekeysFor_Invocations)
    }

    func testThatPrekeysAreFetchedInBatches_whenEstablishingSession() async throws {
        // given

        let clientIDs = (0 ..< 29).map { index in
            let clientID = Arrangement.Scaffolding.clientID
            return QualifiedClientID(userID: clientID.userID, domain: clientID.domain, clientID: "client\(index)")
        }
        let (arrangement, sessionEstablisher) = Arrangement(coreDataStack: coreDataStack)
            .withFetchPrekeyAPI(returning: .success(Arrangement.Scaffolding.prekeyByQualifiedUserID))
            .withEstablishSessionsSucceeding()
            .arrange()

        // when
        try await sessionEstablisher.establishSession(with: Set(clientIDs), apiVersion: .v0)

        // then
        XCTAssertEqual(2, arrangement.prekeyApi.fetchPrekeysFor_Invocations.count)
    }

    func testThatSessionsAreEstablished_whenEstablishingSessions() async throws {
        // given
        let (arrangement, sessionEstablisher) = Arrangement(coreDataStack: coreDataStack)
            .withFetchPrekeyAPI(returning: .success(Arrangement.Scaffolding.prekeyByQualifiedUserID))
            .withEstablishSessionsSucceeding()
            .arrange()

        // when
        try await sessionEstablisher.establishSession(with: [Arrangement.Scaffolding.clientID], apiVersion: .v0)

        // then
        XCTAssertEqual(1, arrangement.processor.establishSessionsFromWithContext_Invocations.count)
    }
}
