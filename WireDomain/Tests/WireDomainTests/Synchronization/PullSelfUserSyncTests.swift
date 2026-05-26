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

import WireNetworkSupport
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class PullSelfUserSyncTests: XCTestCase {

    private var sut: PullSelfUserSync!
    private var api: MockSelfUserAPI!
    private var store: MockUserLocalStoreProtocol!

    override func setUp() async throws {
        api = MockSelfUserAPI()
        store = MockUserLocalStoreProtocol()
        sut = PullSelfUserSync(api: api, store: store)
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getSelfUser_MockValue = Scaffolding.remoteSelfUser
        store.persistUserUserInfo_MockMethod = { _ in }

        // When
        let result = try await sut.pull()

        // Then
        XCTAssertEqual(api.getSelfUser_Invocations.count, 1)

        let storeInvocations = store.persistUserUserInfo_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0], Scaffolding.localSelfUser)

        XCTAssertEqual(result.id, Scaffolding.remoteSelfUser.qualifiedID.id)
        XCTAssertEqual(result.domain, Scaffolding.remoteSelfUser.qualifiedID.domain)
        XCTAssertEqual(result.teamID, Scaffolding.remoteSelfUser.teamID)
    }

    func testSelfUserMapping_usesCompanyLogin_isTrue_whenSSOSubjectIsPopulated() {
        // Given
        let selfUser = Scaffolding.selfUser(
            ssoID: SSOID(scimExternalId: nil, subject: "external-subject-id", tenant: "idp.example.com")
        )

        // When
        let info = selfUser.toDomainModel()

        // Then
        XCTAssertTrue(info.usesCompanyLogin)
    }

    func testSelfUserMapping_usesCompanyLogin_isFalse_whenSSOSubjectIsBlank() {
        // Given: SCIM-managed details but no IdP federation → still password-based login
        let selfUser = Scaffolding.selfUser(
            ssoID: SSOID(scimExternalId: "scim-1", subject: "", tenant: nil)
        )

        // When
        let info = selfUser.toDomainModel()

        // Then
        XCTAssertFalse(info.usesCompanyLogin)
    }

    func testSelfUserMapping_usesCompanyLogin_isFalse_whenSSOSubjectIsNil() {
        // Given
        let selfUser = Scaffolding.selfUser(
            ssoID: SSOID(scimExternalId: nil, subject: nil, tenant: nil)
        )

        // When
        let info = selfUser.toDomainModel()

        // Then
        XCTAssertFalse(info.usesCompanyLogin)
    }

    func testSelfUserMapping_usesCompanyLogin_isFalse_whenSSOIDIsNil() {
        // Given
        let selfUser = Scaffolding.selfUser(ssoID: nil)

        // When
        let info = selfUser.toDomainModel()

        // Then
        XCTAssertFalse(info.usesCompanyLogin)
    }

}

private enum Scaffolding {

    static let qualifiedID = UserID(
        id: UUID(),
        domain: "example.com"
    )

    static let remoteSelfUser = SelfUser(
        id: qualifiedID.id,
        qualifiedID: qualifiedID,
        ssoID: nil,
        name: "username",
        handle: "username",
        teamID: UUID(),
        phone: "",
        accentID: 1,
        managedBy: .wire,
        assets: [],
        deleted: false,
        email: "username@wire.com",
        expiresAt: .now,
        app: nil,
        service: nil,
        supportedProtocols: [.mls]
    )

    static var localSelfUser: NewUserInfo {
        remoteSelfUser.toDomainModel()
    }

    static func selfUser(ssoID: SSOID?) -> SelfUser {
        SelfUser(
            id: qualifiedID.id,
            qualifiedID: qualifiedID,
            ssoID: ssoID,
            name: "username",
            handle: "username",
            teamID: UUID(),
            phone: "",
            accentID: 1,
            managedBy: .wire,
            assets: [],
            deleted: false,
            email: "username@wire.com",
            expiresAt: .now,
            app: nil,
            service: nil,
            supportedProtocols: [.mls]
        )
    }

}
