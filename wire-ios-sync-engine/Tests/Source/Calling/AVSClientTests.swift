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

import Foundation
@testable import WireSyncEngine
import XCTest

class AVSClientTests: XCTestCase {

    func testThatItSupportsAVSIdentifier() {
        // Given
        let avsIdentifier = AVSIdentifier(identifier: UUID(), domain: "wire.com")

        // When
        let sut = AVSClient(userId: avsIdentifier, clientId: UUID().uuidString)

        // Then
        XCTAssertEqual(sut.userId, avsIdentifier.serialized)
        XCTAssertEqual(sut.avsIdentifier, avsIdentifier)
    }

    func testThatItSupportsAVSIdentifer_WhenCreatedFromAVSCallMember() {
        // Given
        let avsIdentifier = AVSIdentifier(identifier: UUID(), domain: "wire.com")

        let member = AVSCallMember(member: AVSParticipantsChange.Member(
            userid: avsIdentifier.serialized,
            clientid: UUID().uuidString,
            aestab: .established,
            vrecv: .started,
            muted: .muted
        ))

        // When
        let sut = member.client

        // Then
        XCTAssertEqual(sut.userId, avsIdentifier.serialized)
        XCTAssertEqual(sut.avsIdentifier, avsIdentifier)
    }

    func testThatItSupportsAVSIdentifer_WhenCreatedFromActiveSpeaker() {
        // Given
        let avsIdentifier = AVSIdentifier(identifier: UUID(), domain: "wire.com")

        let activeSpeaker = AVSActiveSpeakersChange.ActiveSpeaker(
            userId: avsIdentifier.serialized,
            clientId: UUID().uuidString,
            audioLevel: 0,
            audioLevelNow: 0
        )

        // When
        let sut = activeSpeaker.client

        // Then
        XCTAssertEqual(sut.userId, avsIdentifier.serialized)
        XCTAssertEqual(sut.avsIdentifier, avsIdentifier)
    }

}
