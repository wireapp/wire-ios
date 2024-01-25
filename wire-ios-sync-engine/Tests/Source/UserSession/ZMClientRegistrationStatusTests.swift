//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import XCTest
@testable import WireSyncEngine

extension ZMClientRegistrationStatusTests {
    func testThatItReturns_FetchingClients_WhenReceivingAnErrorWithTooManyClients() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()

            // when
            sut.didFail(toRegisterClient: tooManyClientsError()! as NSError)

            // then
            XCTAssertEqual(sut.currentPhase, ZMClientRegistrationPhase.fetchingClients)
        }
    }

    func testThatItDoesNotNeedToRegisterMLSClient_WhenNoClientIsAlreadyRegisteredAndAllowed() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            DeveloperFlag.storage = .temporary()
            DeveloperFlag.enableMLSSupport.enable(true)
            BackendInfo.storage = .temporary()
            BackendInfo.apiVersion = .v5

            // then
            XCTAssertFalse(sut.needsToRegisterMLSCLient)
        }
    }

    func testThatItNeeddToRegisterMLSClient_WhenClientIsRegisteredAndAllowed() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()

            let selfClient =  UserClient.insertNewObject(in: self.syncMOC)
            selfClient.remoteIdentifier = UUID.create().transportString()
            sut.didRegisterProteusClient(selfClient)

            DeveloperFlag.storage = .temporary()
            DeveloperFlag.enableMLSSupport.enable(true)
            BackendInfo.storage = .temporary()
            BackendInfo.apiVersion = .v5

            // then
            XCTAssertTrue(sut.needsToRegisterMLSCLient)
        }
    }

    func testThatItDoesntNeedsToRegisterMLSClient_WhenClientIsAlreadyRegistered() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            let selfClient = createSelfClient()
            selfClient.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "someKey")
            selfClient.needsToUploadMLSPublicKeys = false
            DeveloperFlag.storage = .temporary()
            DeveloperFlag.enableMLSSupport.enable(true)
            BackendInfo.storage = .temporary()
            BackendInfo.apiVersion = .v5

            // then
            XCTAssertFalse(sut.needsToRegisterMLSCLient)
        }
    }

    func testThatItDoesntNeedsToRegisterMLSClient_WhenNotAllowed() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            DeveloperFlag.enableMLSSupport.enable(false)
            BackendInfo.apiVersion = .v5

            // then
            XCTAssertFalse(sut.needsToRegisterMLSCLient)
        }
    }

    func testThatItReturnsWaitsForPrekeys_WhenItNeedsToRegisterAClient() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"

            // then
            XCTAssertEqual(self.sut.currentPhase, .waitingForPrekeys)
        }
    }

    func testThatItReturnsGeneratesPrekeys_AfterPrekeyGenerationAsBegun() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"

            // when
            sut.willGeneratePrekeys()

            // then
            XCTAssertEqual(self.sut.currentPhase, .generatingPrekeys)
        }
    }

    func testThatItReturnsWaitingForE2EIStatus_IfMLSIsEnabledAfterRegisteringProteusClient() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"
            let selfUserClient = createSelfClient()
            selfUserClient.remoteIdentifier = "clientID"

            DeveloperFlag.storage = .temporary()
            DeveloperFlag.enableMLSSupport.enable(true)
            BackendInfo.storage = .temporary()
            BackendInfo.apiVersion = .v5

            // when
            sut.didRegisterProteusClient(selfUserClient)

            // then
            XCTAssertEqual(self.sut.currentPhase, .waitingForE2EIStatus)
        }
    }

    func testThatItReturnsWaitingRegisteringMLSClient_IfE2EIdentityIsNotRequired() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"
            let selfUserClient = createSelfClient()
            selfUserClient.remoteIdentifier = "clientID"

            DeveloperFlag.storage = .temporary()
            DeveloperFlag.enableMLSSupport.enable(true)
            BackendInfo.storage = .temporary()
            BackendInfo.apiVersion = .v5

            // when
            sut.didCheckIfEndToEndIdentityIsRequired(false)

            // then
            XCTAssertEqual(self.sut.currentPhase, .registeringMLSClient)
        }
    }

    func testThatItReturnsWaitingForE2EIEnrollment_IfE2EIdentityIsRequired() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"
            let selfUserClient = createSelfClient()
            selfUserClient.remoteIdentifier = "clientID"

            DeveloperFlag.storage = .temporary()
            DeveloperFlag.enableMLSSupport.enable(true)
            BackendInfo.storage = .temporary()
            BackendInfo.apiVersion = .v5

            // when
            sut.didCheckIfEndToEndIdentityIsRequired(true)

            // then
            XCTAssertEqual(self.sut.currentPhase, .waitingForE2EIEnrollment)
        }
    }

    func testThatItReturnsRegistered_IfMLSIsDisabledAfterRegisteringProteusClient() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"
            let selfUserClient = createSelfClient()
            selfUserClient.remoteIdentifier = "clientID"

            // when
            sut.didRegisterProteusClient(selfUserClient)

            // then
            XCTAssertEqual(self.sut.currentPhase, .registered)
        }
    }

    func testThatItReturnsUnregistered_AfterPrekeyGenerationIsCompleted() {
        syncMOC.performAndWait {
            // given
            let prekey = IdPrekeyTuple(id: 1, prekey: "prekey1")
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"
            sut.willGeneratePrekeys()

            // when
            sut.didGeneratePrekeys([prekey], lastResortPrekey: prekey)

            // then
            XCTAssertEqual(self.sut.currentPhase, .unregistered)
        }
    }

    func testThatItReturnsRegistered_AfterClientHasBeenCreated() {
        syncMOC.performAndWait {
            // given
            let prekey = IdPrekeyTuple(id: 1, prekey: "prekey1")
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"
            sut.willGeneratePrekeys()
            sut.didGeneratePrekeys([prekey], lastResortPrekey: prekey)

            // when
            let selfClient =  UserClient.insertNewObject(in: self.syncMOC)
            selfClient.remoteIdentifier = UUID.create().transportString()
            sut.didRegisterProteusClient(selfClient)

            // then
            XCTAssertEqual(self.sut.currentPhase, .registered)
        }
    }
}
