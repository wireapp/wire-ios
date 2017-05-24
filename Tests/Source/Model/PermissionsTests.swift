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


import WireTesting
@testable import WireDataModel


class PermissionsTests: BaseZMClientMessageTests {

    private let allPermissions: Permissions = [
        .createConversation,
        .deleteConversation,
        .addTeamMember,
        .removeTeamMember,
        .addConversationMember,
        .removeConversationMember,
        .getMemberPermissions,
        .getTeamConversations,
        .getBilling,
        .setBilling,
        .setTeamData,
        .deleteTeam
    ]

    func testThatDefaultValueDoesNotHaveAnyPermissions() {
        // given
        let sut = Permissions(rawValue: 0)

        // then
        XCTAssertFalse(sut.contains(.createConversation))
        XCTAssertFalse(sut.contains(.deleteConversation))
        XCTAssertFalse(sut.contains(.addTeamMember))
        XCTAssertFalse(sut.contains(.removeTeamMember))
        XCTAssertFalse(sut.contains(.addConversationMember))
        XCTAssertFalse(sut.contains(.removeConversationMember))
        XCTAssertFalse(sut.contains(.getMemberPermissions))
        XCTAssertFalse(sut.contains(.getTeamConversations))
        XCTAssertFalse(sut.contains(.getBilling))
        XCTAssertFalse(sut.contains(.setBilling))
        XCTAssertFalse(sut.contains(.setTeamData))
        XCTAssertFalse(sut.contains(.deleteTeam))
    }

    func testMemberPermissions() {
        XCTAssertEqual(Permissions.member, [.createConversation, .deleteConversation, .addConversationMember, .removeConversationMember, .getMemberPermissions, .getTeamConversations])
    }

    func testAdminPermissions() {
        // given
        let adminPermissions: Permissions = [
            .createConversation,
            .deleteConversation,
            .addConversationMember,
            .removeConversationMember,
            .getMemberPermissions,
            .getTeamConversations,
            .addTeamMember,
            .removeTeamMember,
            .setTeamData
        ]

        // then
        XCTAssertEqual(Permissions.admin, adminPermissions)
    }

    func testOwnerPermissions() {
        XCTAssertEqual(Permissions.owner, allPermissions)
    }

    // MARK: - Transport Data

    func testThatItCreatesPermissionsFromPayload() {
        XCTAssertEqual(Permissions(rawValue: 5), [.createConversation, .addTeamMember])
        XCTAssertEqual(Permissions(rawValue: 1587), .member)
        XCTAssertEqual(Permissions(rawValue: 1855), .admin)
        XCTAssertEqual(Permissions(rawValue: 4095), .owner)
    }

    func testThatItCreatesEmptyPermissionsFromEmptyPayload() {
        XCTAssertEqual(Permissions(rawValue: 0), [])
    }

    // MARK: - Objective-C Interoperability

    func testThatItCreatesTheCorrectSwiftPermissions() {
        XCTAssertEqual(PermissionsObjC.member.permissions, .member)
        XCTAssertEqual(PermissionsObjC.admin.permissions, .admin)
        XCTAssertEqual(PermissionsObjC.owner.permissions, .owner)
    }

    func testThatItSetsObjectiveCPermissions() {
        // given
        let member = Member.insertNewObject(in: uiMOC)

        // when
        member.setPermissionsObjC(.admin)

        // then
        XCTAssertEqual(member.permissions, .admin)
    }

}
