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
        // given
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier = UUID()

        // when
        sut.didFail(toRegisterClient: tooManyClientsError()! as NSError)

        // then
        XCTAssertEqual(sut.currentPhase, ZMClientRegistrationPhase.fetchingClients)
    }

    func testThatItNeedsToRegisterMLSClient_WhenNoClientIsAlreadyRegisteredAndAllowed() {
        // given
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier = UUID()
        DeveloperFlag.storage = .random()!
        DeveloperFlag.enableMLSSupport.enable(true)
        BackendInfo.storage = .random()!
        BackendInfo.apiVersion = .v5

        // then
        XCTAssertTrue(sut.needsToRegisterMLSCLient)
    }

    func testThatItDoesntNeedsToRegisterMLSClient_WhenClientIsAlreadyRegistered() {
        // given
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier = UUID()
        let selfClient = createSelfClient()
        selfClient.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "someKey")
        selfClient.needsToUploadMLSPublicKeys = false
        DeveloperFlag.storage = .random()!
        DeveloperFlag.enableMLSSupport.enable(true)
        BackendInfo.storage = .random()!
        BackendInfo.apiVersion = .v5

        // then
        XCTAssertFalse(sut.needsToRegisterMLSCLient)
    }

    func testThatItDoesntNeedsToRegisterMLSClient_WhenNotAllowed() {
        // given
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier = UUID()
        DeveloperFlag.enableMLSSupport.enable(false)
        BackendInfo.apiVersion = .v5

        // then
        XCTAssertFalse(sut.needsToRegisterMLSCLient)
    }
}
