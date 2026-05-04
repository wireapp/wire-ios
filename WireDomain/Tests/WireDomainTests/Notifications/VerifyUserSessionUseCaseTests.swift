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

import WireDataModel
import WireDataModelSupport
import WireNetworkSupport
import WireTestingPackage
import XCTest

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class VerifyUserSessionUseCaseTests: XCTestCase {
    private var sut: VerifyUserSessionUseCase!
    private var journal: Journal!
    private var cookieStorage: MockCookieStorageProtocol!
    private var stack: MockCoreDataStackProtocol!

    override func setUp() async throws {
        journal = Journal(
            userID: UUID(),
            storage: UserDefaults.temporary()
        )
        stack = MockCoreDataStackProtocol()
        cookieStorage = MockCookieStorageProtocol()

        sut = VerifyUserSessionUseCase(
            journal: journal,
            cookieStorage: cookieStorage,
            coreData: stack
        )

        journal[.isSyncV2Enabled] = true
    }

    override func tearDown() async throws {
        sut = nil
        journal = nil
        cookieStorage = nil
        stack = nil
    }

    func testVerify_It_Invokes_Fetch_Cookies_And_Setup_Core_Data_Properly() async throws {

        // Mock

        stack.storesExists = true
        stack.needsMigration = false
        stack.load_MockMethod = {}
        let validCookie = try XCTUnwrap(Scaffolding.validCookie)
        cookieStorage.fetchCookies_MockValue = [validCookie]

        // When
        try await sut.invoke()

        // Then
        XCTAssertEqual(cookieStorage.fetchCookies_Invocations.count, 1)

    }

    func testVerify_It_Throws_User_SyncV2IsNotEnabled_Error() async throws {

        // Given
        journal[.isSyncV2Enabled] = false

        // Then
        await XCTAssertThrowsErrorAsync(VerifyUserSessionUseCase.Failure.syncV2IsNotEnabled) { [self] in
            // When
            try await sut.invoke()
        }

    }

    func testVerify_It_Throws_User_Unauthenticated_Error() async throws {

        // Mock
        cookieStorage.fetchCookies_MockValue = [.init()]

        // Then
        await XCTAssertThrowsErrorAsync(VerifyUserSessionUseCase.Failure.userUnauthenticated) { [self] in
            // When
            try await sut.invoke()
        }

    }

    func testVerify_It_Throws_User_Unauthenticated_Error_When_Cookie_Expired() async throws {

        // Mock
        let expiredCookie = try XCTUnwrap(Scaffolding.expiredCookie)
        cookieStorage.fetchCookies_MockValue = [expiredCookie]

        // Then
        await XCTAssertThrowsErrorAsync(VerifyUserSessionUseCase.Failure.userUnauthenticated) { [self] in
            // When
            try await sut.invoke()
        }

    }

    func testVerify_It_Throws_User_Unauthenticated_Error_When_No_Cookies_Found() async throws {

        // Mock
        cookieStorage.fetchCookies_MockValue = []

        // Then
        await XCTAssertThrowsErrorAsync(VerifyUserSessionUseCase.Failure.userUnauthenticated) { [self] in
            // When
            try await sut.invoke()
        }

    }

    func testStartSyncingEvents_It_Throws_Core_Data_Missing_Shared_Container() async throws {
        // Mock
        let validCookie = try XCTUnwrap(Scaffolding.validCookie)
        cookieStorage.fetchCookies_MockValue = [validCookie]
        stack.storesExists = false

        // Then
        await XCTAssertThrowsErrorAsync(VerifyUserSessionUseCase.Failure.coreDataMissingSharedContainer) { [self] in
            // When
            try await sut.invoke()
        }
    }

    func testStartSyncingEvents_It_Throws_Core_Data_Migration_Required() async throws {
        // Mock
        stack.storesExists = true
        stack.needsMigration = true
        let validCookie = try XCTUnwrap(Scaffolding.validCookie)
        cookieStorage.fetchCookies_MockValue = [validCookie]

        // Then
        await XCTAssertThrowsErrorAsync(VerifyUserSessionUseCase.Failure.coreDataMigrationRequired) { [self] in
            // When
            try await sut.invoke()
        }
    }

    private enum Scaffolding {
        static let userID = UUID.mockID1
        static let validCookie = HTTPCookie(properties: [
            .name: "zuid",
            .path: "some path",
            .value: "some value",
            .domain: "some domain",
            .expires: Date.distantFuture
        ])

        static let expiredCookie = HTTPCookie(properties: [
            .name: "zuid",
            .path: "some path",
            .value: "some value",
            .domain: "some domain",
            .expires: Date.distantPast
        ])
    }

}

extension VerifyUserSessionUseCase.Failure: Equatable {
    public static func == (
        lhs: WireDomain.VerifyUserSessionUseCase.Failure,
        rhs: WireDomain.VerifyUserSessionUseCase.Failure
    ) -> Bool {
        switch (lhs, rhs) {
        case (.coreDataMissingSharedContainer, .coreDataMissingSharedContainer):
            true
        case (.coreDataMigrationRequired, .coreDataMigrationRequired):
            true
        case (.userUnauthenticated, .userUnauthenticated):
            true
        case (.unableToLoadStores, .unableToLoadStores):
            true
        case (.syncV2IsNotEnabled, .syncV2IsNotEnabled):
            true
        default:
            false
        }
    }
}
