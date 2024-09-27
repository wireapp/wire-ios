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

import WireDataModelSupport
import WireTransport
import XCTest
@testable import WireSyncEngine

// MARK: - MockCookieStorage

final class MockCookieStorage: CookieProvider {
    var isAuthenticated = true

    var didCallDeleteKeychainItems = false

    func setRequestHeaderFieldsOn(_: NSMutableURLRequest) {}

    func deleteKeychainItems() {
        didCallDeleteKeychainItems = true
    }
}

// MARK: - ZMClientRegistrationStatusTests

final class ZMClientRegistrationStatusTests: MessagingTest {
    // MARK: Internal

    override func setUp() {
        super.setUp()

        // be sure to call this before initializing sut
        uiMOC.setPersistentStoreMetadata(nil as String?, key: ZMPersistedClientIdKey)
        mockCookieStorage = MockCookieStorage()
        mockCookieStorage.isAuthenticated = true
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockClientRegistationDelegate = MockClientRegistrationStatusDelegate()
        sut = ZMClientRegistrationStatus(
            context: syncMOC,
            cookieProvider: mockCookieStorage,
            coreCryptoProvider: mockCoreCryptoProvider
        )
        sut.registrationStatusDelegate = mockClientRegistationDelegate
    }

    override func tearDown() {
        mockClientRegistationDelegate = nil
        mockCookieStorage = nil
        sut = nil

        super.tearDown()
    }

    // MARK: Initialisation

    func testThatItRequestsE2EIEnrollment_whenRequiredOnInitialisation() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            let client  = UserClient.insertNewObject(in: self.syncMOC)
            client.user = selfUser
            client.remoteIdentifier = "identifier"
            self.syncMOC.setPersistentStoreMetadata(client.remoteIdentifier, key: ZMPersistedClientIdKey)

            enableMLS()
            enableE2EI()

            // when
            sut.determineInitialRegistrationStatus()

            // then
            XCTAssertTrue(mockClientRegistationDelegate.didCallFailRegisterSelfUserClient)
            XCTAssertEqual(
                mockClientRegistationDelegate.currentError as? NSError,
                needToToEnrollE2EIToRegisterClientError()
            )
        }
    }

    func testThatItCreatesBasicMLSClient_whenIfThereIsNoneOnInitialisation() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            let client  = UserClient.insertNewObject(in: self.syncMOC)
            client.user = selfUser
            client.remoteIdentifier = "identifier"
            selfUser.domain = "example.com"
            self.syncMOC.setPersistentStoreMetadata(client.remoteIdentifier, key: ZMPersistedClientIdKey)
            mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_MockMethod = { _ in }

            enableMLS()

            // when
            sut.determineInitialRegistrationStatus()
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(self.sut.currentPhase, .registeringMLSClient)
            XCTAssertEqual(mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_Invocations.count, 1)
        }
    }

    func testThatItInsertsANewClientIfThereIsNoneWaitingToBeSynced() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            let client  = UserClient.insertNewObject(in: self.syncMOC)
            client.user = selfUser
            client.remoteIdentifier = "identifier"

            XCTAssertEqual(selfUser.clients.count, 1)

            // when
            sut.prepareForClientRegistration()

            // then
            XCTAssertEqual(selfUser.clients.count, 2)
        }
    }

    func testThatItDoesNotInsertANewClientIfThereIsAlreadyOneWaitingToBeSynced() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            let client  = UserClient.insertNewObject(in: self.syncMOC)
            client.user = selfUser

            XCTAssertEqual(selfUser.clients.count, 1)

            // when
            sut.prepareForClientRegistration()

            // then
            XCTAssertEqual(selfUser.clients.count, 1)
        }
    }

    // MARK: State machine

    func testThatItReturns_WaitingForSelfUser_IfSelfUserDoesNotHaveRemoteID() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = nil

            // then
            XCTAssertEqual(self.sut.currentPhase, .waitingForSelfUser)
        }
    }

    func testThatItReturns_Registered_IfSelfClientIsSet() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            syncMOC.setPersistentStoreMetadata("lala", key: ZMPersistedClientIdKey)

            // then
            XCTAssertEqual(self.sut.currentPhase, .registered)
        }
    }

    func testThatItReturns_WaitingForDeletion_AfterUserSelectedClientToDelete() {
        // given
        syncMOC.performAndWait {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"
            selfUser.handle = "handle"

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "identifier"
            client.user = selfUser

            self.syncMOC.setPersistentStoreMetadata(client.remoteIdentifier, key: ZMPersistedClientIdKey)
            self.syncMOC.saveOrRollback()

            // when
            sut.didDetectCurrentClientDeletion()

            // then
            XCTAssertEqual(sut.currentPhase, .waitingForPrekeys)
            XCTAssertTrue(mockClientRegistationDelegate.didCallDeleteSelfUserClient)
        }
    }

    func testThatItResets_LocallyModifiedKeys_AfterUserSelectedClientToDelete() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "identifier"
            client.user = selfUser
            client.setLocallyModifiedKeys(Set(["numberOfKeysRemaining"]))
            self.syncMOC.setPersistentStoreMetadata(client.remoteIdentifier, key: ZMPersistedClientIdKey)

            // when
            sut.didDetectCurrentClientDeletion()

            // then
            XCTAssertFalse(client.hasLocalModifications(forKey: "numberOfKeysRemaining"))
        }
    }

    func testThatItInvalidatesSelfClientAndDeletesAndRecreatesCryptoBoxOnDidDetectCurrentClientDeletion() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"
            selfUser.handle = "handle"

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.user = selfUser
            syncMOC.saveOrRollback()

            // when
            sut.didFail(toRegisterClient: tooManyClientsError() as NSError)
            ZMClientUpdateNotification.notifyFetchingClientsCompleted(userClients: [client], context: self.uiMOC)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performAndWait {
            XCTAssertEqual(self.sut.currentPhase, .waitingForDeletion)
        }
    }

    func testThatItReturnsYESForNeedsToRegisterClientIfNoClientIdInMetadata() {
        syncMOC.performAndWait {
            self.syncMOC.setPersistentStoreMetadata(nil as String?, key: ZMPersistedClientIdKey)
            XCTAssertTrue(ZMClientRegistrationStatus.needsToRegisterClient(in: self.syncMOC))
        }
    }

    func testThatItReturnsNOForNeedsToRegisterClientIfThereIsClientIdInMetadata() {
        syncMOC.performAndWait {
            self.syncMOC.setPersistentStoreMetadata("lala", key: ZMPersistedClientIdKey)
            XCTAssertFalse(ZMClientRegistrationStatus.needsToRegisterClient(in: self.syncMOC))
        }
    }

    func testThatItNotfiesCredentialProviderWhenClientIsRegistered() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()

            // when
            sut.prepareForClientRegistration()

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = UUID().transportString()

            sut.didRegisterProteusClient(client)

            // then
            XCTAssertEqual(sut.currentPhase, .registered)
        }
    }

    func testThatItNotfiesDelegateWhenClientIsRegistered() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()

            sut.prepareForClientRegistration()

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = UUID().transportString()

            // when
            self.sut.didRegisterProteusClient(client)

            // then
            XCTAssertTrue(self.mockClientRegistationDelegate.didCallRegisterSelfUserClient)
        }
    }

    func testThatItTransitionsFrom_WaitingForEmail_To_WaitingForPrekeys_WhenSelfUserChangesWithEmailAddress() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.handle = "handle"
            selfUser.emailAddress = nil
            selfUser.phoneNumber = nil

            XCTAssertEqual(sut.currentPhase, .waitingForEmailVerfication)

            // when
            selfUser.emailAddress = "me@example.com"
            sut.didFetchSelfUser()

            // then
            XCTAssertEqual(sut.currentPhase, .waitingForPrekeys)
        }
    }

    func testThatItIsWaitingForEmailVerfication_WhenSelfUserChangesWithoutEmailAddress() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.handle = "handle"
            selfUser.emailAddress = nil
            selfUser.phoneNumber = nil

            XCTAssertEqual(sut.currentPhase, .waitingForEmailVerfication)

            // when
            selfUser.emailAddress = nil
            sut.didFetchSelfUser()

            // then
            XCTAssertEqual(sut.currentPhase, .waitingForEmailVerfication)
        }
    }

    func testThatItIsWaitingForHandle_WhenSelfUserChangesWithoutHandle() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.handle = nil
            selfUser.emailAddress = "email@example.com"
            selfUser.phoneNumber = nil

            XCTAssertEqual(sut.currentPhase, .waitingForHandle)

            // when
            sut.didFetchSelfUser()

            // then
            XCTAssertEqual(sut.currentPhase, .waitingForHandle)
        }
    }

    func testThatItResetsThePhaseToWaitingForLoginIfItNeedsPasswordToRegisterClient() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"
            selfUser.handle = "handle"
            self.sut.emailCredentials = nil
            XCTAssertEqual(sut.currentPhase, .waitingForPrekeys)

            // when
            sut.didFail(toRegisterClient: needsPasswordError())

            // then
            XCTAssertEqual(self.sut.currentPhase, .waitingForLogin)

            // and when

            // the user entered the password, we can proceed trying to register the client
            self.sut.emailCredentials = UserEmailCredentials(email: "john.doe@example.com", password: "123456789")

            // then
            XCTAssertEqual(sut.currentPhase, .waitingForPrekeys)
        }
    }

    func testThatItDoesNotRequireEmailRegistrationForTeamUser() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.handle = "handle"
            selfUser.emailAddress = nil
            selfUser.phoneNumber = nil
            selfUser.usesCompanyLogin = true

            // then
            XCTAssertEqual(sut.currentPhase, .waitingForPrekeys)
        }
    }

    // MARK: AuthenticationNotifications

    func testThatItNotifiesTheUIAboutSuccessfulRegistration() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = self.userIdentifier
            self.syncMOC.saveOrRollback()

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "yay"

            // when
            sut.didRegisterProteusClient(client)

            // then
            XCTAssertEqual(sut.currentPhase, .registered)
            XCTAssertTrue(mockClientRegistationDelegate.didCallRegisterSelfUserClient)
        }
    }

    func testThatItNotifiesTheUIIfTheRegistrationFailsWithNeedToToEnrollE2EI() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = nil
            selfUser.phoneNumber = nil
            syncMOC.saveOrRollback()

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "yay"

            enableMLS()
            enableE2EI()

            // when
            sut.didRegisterProteusClient(client)

            // then
            XCTAssertTrue(mockClientRegistationDelegate.didCallFailRegisterSelfUserClient)
            XCTAssertEqual(
                mockClientRegistationDelegate.currentError as? NSError,
                needToToEnrollE2EIToRegisterClientError()
            )
        }
    }

    func testThatItNotifiesTheUIIfTheRegistrationFailsWithMissingEmailVerification() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.handle = "handle"
            selfUser.emailAddress = nil
            selfUser.phoneNumber = nil
            self.syncMOC.saveOrRollback()

            // when
            sut.didFetchSelfUser()

            // then
            XCTAssertTrue(mockClientRegistationDelegate.didCallFailRegisterSelfUserClient)
            XCTAssertEqual(mockClientRegistationDelegate.currentError as? NSError, needToRegisterEmailError())
        }
    }

    func testThatItNotifiesTheUIIfTheRegistrationFailsWithMissingHandle() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.handle = nil
            selfUser.emailAddress = "email@example.com"
            selfUser.phoneNumber = nil
            syncMOC.saveOrRollback()

            // when
            sut.didFetchSelfUser()

            // then
            XCTAssertTrue(mockClientRegistationDelegate.didCallFailRegisterSelfUserClient)
            XCTAssertEqual(mockClientRegistationDelegate.currentError as? NSError, needToSetHandleError())
        }
    }

    func testThatItNotifiesTheUIIfTheRegistrationFailsWithMissingPasswordError() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = self.userIdentifier
            syncMOC.saveOrRollback()
            let error = NSError(
                domain: "ZMUserSession",
                code: UserSessionErrorCode.needsPasswordToRegisterClient.rawValue,
                userInfo: selfUser.loginCredentials.dictionaryRepresentation
            )

            // when
            sut.didFail(toRegisterClient: error)

            // then
            XCTAssertTrue(mockClientRegistationDelegate.didCallFailRegisterSelfUserClient)
            XCTAssertEqual(mockClientRegistationDelegate.currentError as? NSError, error)
        }
    }

    func testThatItNotifiesTheUIIfTheRegistrationFailsWithWrongCredentialsError() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = self.userIdentifier
            syncMOC.saveOrRollback()

            let error = NSError(
                domain: "ZMUserSession",
                code: UserSessionErrorCode.invalidCredentials.rawValue
            )

            // when
            sut.didFail(toRegisterClient: error)

            // then
            XCTAssertTrue(mockClientRegistationDelegate.didCallFailRegisterSelfUserClient)
            XCTAssertEqual(mockClientRegistationDelegate.currentError as? NSError, error)
        }
    }

    func testThatItDoesNotNotifiesTheUIIfTheRegistrationFailsWithTooManyClientsError() {
        syncMOC.performAndWait {
            // given
            let error = tooManyClientsError()

            // when
            sut.didFail(toRegisterClient: error)

            // then
            XCTAssertFalse(self.mockClientRegistationDelegate.didCallFailRegisterSelfUserClient)
        }
    }

    func testThatItDeletesTheCookieIfFetchingClientsFailedWithError_SelfClientIsInvalid() {
        // given
        syncMOC.performAndWait {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.user = selfUser
            client.remoteIdentifier = "identifer"
            syncMOC.setPersistentStoreMetadata(client.remoteIdentifier, key: ZMPersistedClientIdKey)
            syncMOC.saveOrRollback()
            XCTAssertNotNil(selfUser.selfClient)
        }
        let error = NSError(domain: "ClientManagement", code: ClientUpdateError.selfClientIsInvalid.rawValue)

        // when
        ZMClientUpdateNotification.notifyFetchingClientsDidFail(error: error, context: uiMOC)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performAndWait {
            XCTAssertNil(syncMOC.persistentStoreMetadata(forKey: ZMPersistedClientIdKey))
            XCTAssertTrue(mockCookieStorage.didCallDeleteKeychainItems)
        }
    }

    func testThatItReturns_FetchingClients_WhenReceivingAnErrorWithTooManyClients() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()

            // when
            sut.didFail(toRegisterClient: tooManyClientsError() as NSError)

            // then
            XCTAssertEqual(sut.currentPhase, .fetchingClients)
        }
    }

    func testThatItDoesNotNeedToRegisterMLSClient_WhenNoClientIsAlreadyRegisteredAndAllowed() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()

            enableMLS()

            // then
            XCTAssertFalse(sut.needsToRegisterMLSCLient)
        }
    }

    func testThatItNeedsToRegisterMLSClient_WhenClientIsNotRegisteredAndAllowed() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()

            let selfClient = UserClient.insertNewObject(in: self.syncMOC)
            selfClient.remoteIdentifier = UUID.create().transportString()
            sut.didRegisterProteusClient(selfClient)

            enableMLS()

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

            enableMLS()

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
            selfUser.handle = "handle"

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
            selfUser.handle = "handle"

            // when
            sut.willGeneratePrekeys()

            // then
            XCTAssertEqual(self.sut.currentPhase, .generatingPrekeys)
        }
    }

    func testThatItReturnsWaitingRegisteringMLSClient_And_InitsMLSCLient_IfE2EIdentityIsNotRequired() {
        syncMOC.performAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.emailAddress = "email@domain.com"
            selfUser.handle = "handle"
            selfUser.domain = "example.com"
            let selfUserClient = createSelfClient()
            selfUserClient.remoteIdentifier = "clientID"
            mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_MockMethod = { _ in }

            enableMLS()

            // when
            sut.didRegisterProteusClient(selfUserClient)
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(self.sut.currentPhase, .registeringMLSClient)
            XCTAssertEqual(mockCoreCryptoProvider.initialiseMLSWithBasicCredentialsMlsClientID_Invocations.count, 1)
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

            enableMLS()
            enableE2EI()

            // when
            sut.didRegisterProteusClient(selfUserClient)

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
            selfUser.handle = "handle"
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
            let selfClient = UserClient.insertNewObject(in: self.syncMOC)
            selfClient.remoteIdentifier = UUID.create().transportString()
            sut.didRegisterProteusClient(selfClient)

            // then
            XCTAssertEqual(self.sut.currentPhase, .registered)
        }
    }

    // MARK: Private

    private var sut: ZMClientRegistrationStatus!
    private var mockCookieStorage: MockCookieStorage!
    private var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var mockClientRegistationDelegate: MockClientRegistrationStatusDelegate!

    // MARK: - Helpers

    private func needsPasswordError() -> NSError {
        NSError(domain: "ZMUserSession", code: UserSessionErrorCode.needsPasswordToRegisterClient.rawValue)
    }

    private func tooManyClientsError() -> NSError {
        NSError(domain: "ZMUserSession", code: UserSessionErrorCode.canNotRegisterMoreClients.rawValue)
    }

    private func needToRegisterEmailError() -> NSError {
        NSError(domain: "ZMUserSession", code: UserSessionErrorCode.needsToRegisterEmailToRegisterClient.rawValue)
    }

    private func needToToEnrollE2EIToRegisterClientError() -> NSError {
        NSError(domain: "ZMUserSession", code: UserSessionErrorCode.needsToEnrollE2EIToRegisterClient.rawValue)
    }

    private func needToSetHandleError() -> NSError {
        NSError(domain: "ZMUserSession", code: UserSessionErrorCode.needsToHandleToRegisterClient.rawValue)
    }

    @objc
    private func enableMLS() {
        DeveloperFlag.storage = .temporary()
        DeveloperFlag.enableMLSSupport.enable(true)
        BackendInfo.apiVersion = .v5
    }

    @objc
    private func enableE2EI() {
        FeatureRepository(context: syncMOC).storeE2EI(Feature.E2EI(status: .enabled))
    }
}
