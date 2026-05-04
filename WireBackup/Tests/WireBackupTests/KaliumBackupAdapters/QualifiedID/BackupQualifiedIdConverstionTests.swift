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
import KaliumBackup
import Testing
import WireFoundation

@testable import WireBackup

struct BackupQualifiedIdConverstionTests {

    @Test(arguments: [
        QualifiedID(id: UUID(), domain: ""),
        QualifiedID(id: UUID(), domain: "some@domain")
    ])
    func testConversion(qualifiedID: QualifiedID) async throws {
        // When
        let convertedQualifiedID = QualifiedID(BackupQualifiedId(qualifiedID))

        // Then
        #expect(convertedQualifiedID == qualifiedID)
    }

}
