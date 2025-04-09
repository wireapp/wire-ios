//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAPISupport
import WireDataModel
import WireDataModelSupport
import WireTestingPackage
import XCTest
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class VerifyUserSessionUseCaseTests: XCTestCase {
    private var sut: VerifyUserSessionUseCase!
    private var cookieStorage: MockCookieStorageProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var stack: MockCoreDataStackProtocol!

    override func setUp() async throws {
        stack = MockCoreDataStackProtocol()
        cookieStorage = MockCookieStorageProtocol()
        userLocalStore = MockUserLocalStoreProtocol()

        sut = VerifyUserSessionUseCase(
            userID: Scaffolding.userID,
            cookieStorage: cookieStorage,
            coreData: stack
        )
    }

    override func tearDown() async throws {
        sut = nil
        cookieStorage = nil
        stack = nil
        userLocalStore = nil
    }

    func testVerify_It_Invokes_Methods_And_Call_Completion_Block() async throws {

        // Mock

        let validCookie = try XCTUnwrap(Scaffolding.validCookie)
        cookieStorage.fetchCookies_MockValue = [validCookie]

        var completionCalledCount = 0

        let completion: () async throws -> Void = {
            completionCalledCount += 1
        }

        // When
        try await sut.invoke()

        // Then
        XCTAssertEqual(completionCalledCount, 1)
        XCTAssertEqual(cookieStorage.fetchCookies_Invocations.count, 1)

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

    func testStartSyncingEvents_It_Throws_Core_Data_Missing_Shared_Container() async throws {
        // Mock
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
        default:
            false
        }
    }
}
