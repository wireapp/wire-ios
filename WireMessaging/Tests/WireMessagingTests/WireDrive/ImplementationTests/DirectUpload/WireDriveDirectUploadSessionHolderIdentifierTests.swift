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

import Foundation
import Testing

@testable import WireMessagingAssembly

struct WireDriveDirectUploadSessionHolderIdentifierTests {

    @Test
    func make_scopesTheIdentifierToTheUser() {
        // Given
        let userID = UUID(uuidString: "6F9619FF-8B86-D011-B42D-00CF4FC964FF")!

        // When
        let identifier = WireDriveDirectUploadSessionHolder.Identifier.make(userID: userID)

        // Then
        #expect(identifier == "com.wire.drive.upload-6f9619ff-8b86-d011-b42d-00cf4fc964ff")
    }

    @Test
    func make_producesDistinctIdentifiersPerUser() {
        #expect(
            WireDriveDirectUploadSessionHolder.Identifier.make(userID: UUID())
                != WireDriveDirectUploadSessionHolder.Identifier.make(userID: UUID())
        )
    }

    @Test
    func isDriveUploadSession_recognisesOwnIdentifiers() {
        let identifier = WireDriveDirectUploadSessionHolder.Identifier.make(userID: UUID())
        #expect(WireDriveDirectUploadSessionHolder.Identifier.isDriveUploadSession(identifier))
    }

    @Test(arguments: [
        "com.wire.backgroundsession",
        "background-session",
        "com.wire.drive.uploads-not-ours",
        ""
    ])
    func isDriveUploadSession_rejectsOtherIdentifiers(_ identifier: String) {
        #expect(!WireDriveDirectUploadSessionHolder.Identifier.isDriveUploadSession(identifier))
    }

    @Test
    func userID_roundTrips() throws {
        // Given
        let userID = UUID()

        // When
        let identifier = WireDriveDirectUploadSessionHolder.Identifier.make(userID: userID)

        // Then
        #expect(WireDriveDirectUploadSessionHolder.Identifier.userID(from: identifier) == userID)
    }

    @Test
    func userID_isNilForForeignIdentifiers() {
        #expect(WireDriveDirectUploadSessionHolder.Identifier.userID(from: "background-session") == nil)
        #expect(WireDriveDirectUploadSessionHolder.Identifier.userID(from: "com.wire.drive.upload-nonsense") == nil)
    }
}
