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

import SwiftUI
import WireMessagingDomain
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class ConversationSharedDriveOptionsViewSnapshotTests: XCTestCase {
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testSharedDriveOptionsView_Editor() {
        let participants: [WireDriveParticipant] = [
            WireDriveParticipant(
                handle: "johndoe",
                displayName: "John Doe",
                role: .editor,
                isSelfUser: true,
                id: UUID().uuidString,
                userType: .member,
                iconData: .init(initials: "JD", color: .brown, image: nil)
            )
        ]

        let sut = makeView(participants)

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    func testSharedDriveOptionsView_Verifications_Badges() {
        let participants: [WireDriveParticipant] = [
            WireDriveParticipant(
                handle: "johndoe",
                displayName: "John Doe",
                role: .viewer,
                isSelfUser: true,
                id: UUID().uuidString,
                userType: .member,
                verificationBadges: [.e2EICertified, .proteusVerified],
                iconData: .init(initials: "JD", color: .brown, image: nil)
            )
        ]

        let sut = makeView(participants)

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    func testSharedDriveOptionsView_UserTypeBadge() {
        [WireDriveParticipant.UserType.external, .guest, .federated].forEach {
            let participants: [WireDriveParticipant] = [
                WireDriveParticipant(
                    handle: "johndoe",
                    displayName: "John Doe",
                    role: .editor,
                    isSelfUser: false,
                    id: UUID().uuidString,
                    userType: $0,
                    verificationBadges: [],
                    iconData: .init(initials: "JD", color: .brown, image: nil)
                )
            ]

            let sut = makeView(participants)

            snapshotHelper.verifyLightAndDark(matching: sut, named: "\($0).")
        }
    }

    @MainActor
    func testSharedDriveOptionsView_AllBadgesAndStatus() {
        let participants: [WireDriveParticipant] = [
            WireDriveParticipant(
                handle: "johndoe",
                displayName: "John Doe",
                role: .editor,
                isSelfUser: false,
                id: UUID().uuidString,
                userType: .guest,
                verificationBadges: [.e2EICertified],
                iconData: .init(initials: "JD", color: .brown, image: nil)
            )
        ]

        let sut = makeView(participants)

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    func testSharedDriveOptionsView_No_Avatar_Icon() {
        let participants: [WireDriveParticipant] = [
            WireDriveParticipant(
                handle: "johndoe",
                displayName: "John Doe",
                role: .editor,
                isSelfUser: false,
                id: UUID().uuidString,
                userType: .member,
                verificationBadges: [],
            )
        ]

        let sut = makeView(participants)

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    func testSharedDriveOptionsView_Long_Display_Name() {
        let participants: [WireDriveParticipant] = [
            WireDriveParticipant(
                handle: "johndoe",
                displayName: "John Doe (oOo for three weeks)",
                role: .editor,
                isSelfUser: false,
                id: UUID().uuidString,
                userType: .member,
                verificationBadges: [],
                iconData: .init(initials: "JD", color: .brown, image: nil)
            )
        ]

        let sut = makeView(participants)

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    func testSharedDriveOptionsView_UserBlocked() {
        let participants: [WireDriveParticipant] = [
            WireDriveParticipant(
                handle: "johndoe",
                displayName: "John Doe (oOo for three weeks)",
                role: .editor,
                isSelfUser: false,
                id: UUID().uuidString,
                userType: .member,
                verificationBadges: [],
                state: .blocked,
                iconData: .init(initials: "JD", color: .brown, image: nil)
            )
        ]

        let sut = makeView(participants)

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    func testSharedDriveOptionsView_UserPendingApproval() {
        let participants: [WireDriveParticipant] = [
            WireDriveParticipant(
                handle: "johndoe",
                displayName: "John Doe (oOo for three weeks)",
                role: .editor,
                isSelfUser: false,
                id: UUID().uuidString,
                userType: .member,
                verificationBadges: [],
                state: .pendingApproval,
                iconData: .init(initials: "JD", color: .brown, image: nil)
            )
        ]

        let sut = makeView(participants)

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    private func makeView(_ participants: [WireDriveParticipant]) -> some View {
        let viewModel = ConversationSharedDriveOptionsViewModel(participants: participants)

        return NavigationStack {
            ConversationSharedDriveOptionsView(viewModel: viewModel, onClose: {})
        }.frame(width: 375, height: 667)
    }

}
