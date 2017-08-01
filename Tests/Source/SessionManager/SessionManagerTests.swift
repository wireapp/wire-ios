//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireTesting
@testable import WireSyncEngine


class MockStoreProviderFactory: StoreProviderFactory {

    let mockProvider: LocalStoreProviderProtocol

    init(provider: LocalStoreProviderProtocol) {
        self.mockProvider = provider
        super.init()
    }

    override func provider(for account: Account?) -> LocalStoreProviderProtocol {
        return mockProvider
    }

}

class MockLocalStoreProvider: NSObject, LocalStoreProviderProtocol {

    var userIdentifier: UUID?
    var storeExists = true
    var createStackCalled = false
    var contextDirectory: ManagedObjectContextDirectory?

    func createStorageStack(migration: (() -> Void)?, completion: @escaping (LocalStoreProviderProtocol) -> Void) {
        createStackCalled = true
        completion(self)
    }

    var appGroupIdentifier: String
    var cachesURL: URL?
    var sharedContainerDirectory: URL?

    override init() {
        userIdentifier = .create()
        appGroupIdentifier = "group." + Bundle.main.bundleIdentifier!
        sharedContainerDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        cachesURL = sharedContainerDirectory
    }

}

class SessionManagerTestDelegate: SessionManagerDelegate {
    var unauthenticatedSession : UnauthenticatedSession?
    func sessionManagerCreated(unauthenticatedSession : UnauthenticatedSession) {
        self.unauthenticatedSession = unauthenticatedSession
    }
    
    var userSession : ZMUserSession?
    func sessionManagerCreated(userSession : ZMUserSession) {
        self.userSession = userSession
    }
    
    var startedMigrationCalled = false
    func sessionManagerWillStartMigratingLocalStore() {
        startedMigrationCalled = true
    }
}

class SessionManagerTests: IntegrationTest {
    
    var storeProvider: MockLocalStoreProvider!
    var delegate: SessionManagerTestDelegate!
    
    override func setUp() {
        super.setUp()
        storeProvider = MockLocalStoreProvider()
        delegate = SessionManagerTestDelegate()
    }
    
    func createManager() -> SessionManager? {
        guard let mediaManager = mediaManager, let application = application, let transportSession = transportSession else { return nil }

        let unauthenticatedSessionFactory = MockUnauthenticatedSessionFactory(transportSession: transportSession as! UnauthenticatedTransportSessionProtocol)
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            apnsEnvironment: apnsEnvironment,
            application: application,
            mediaManager: mediaManager,
            transportSession: transportSession
        )

        return SessionManager(
            appVersion: "0.0.0",
            authenticatedSessionFactory: authenticatedSessionFactory,
            unauthenticatedSessionFactory: unauthenticatedSessionFactory,
            storeProviderFactory: MockStoreProviderFactory(provider: storeProvider),
            delegate: delegate,
            application: application,
            launchOptions: [:]
        )
    }
    
    override func tearDown() {
        storeProvider = nil
        delegate = nil
        super.tearDown()
    }
    
    func testThatItCreatesUnauthenticatedSessionAndNotifiesDelegateIfStoreIsNotAvailable() {
        // given
        storeProvider.storeExists = false
        
        // when
        _ = createManager()
        
        // then
        XCTAssertNil(delegate.userSession)
        XCTAssertNotNil(delegate.unauthenticatedSession)
    }
    
    func testThatItCreatesUserSessionAndNotifiesDelegateIfStoreIsAvailable() {
        // given
        guard let manager = storeProvider.sharedContainerDirectory.map(AccountManager.init) else { return XCTFail() }
        let account = Account(userName: "", userIdentifier: .create())
        account.cookieStorage().authenticationCookieData = NSData.secureRandomData(ofLength: 16)
        manager.addAndSelect(account)
        storeProvider.storeExists = true

        // when
        _ = createManager()
        
        // then
        XCTAssertNotNil(delegate.userSession)
        XCTAssertNil(delegate.unauthenticatedSession)
    }
}
