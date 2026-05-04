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
@testable import WireDomain

struct SemanticVersionTests {

    @Test("It initialized with sensible defaults", arguments: [
        ("0", "0.0.0"),
        ("0.0", "0.0.0"),
        ("0.0.0", "0.0.0"),
        ("0.0.0.0", "0.0.0"),
        ("-1.0.0", "0.0.0"),
        ("a.b.c", "0.0.0"),
        ("1", "1.0.0"),
        ("1.2", "1.2.0")
    ])
    func itInitializesWithSensibleDefaults(
        string: String,
        expectedVersion: SemanticVersion
    ) {
        #expect(SemanticVersion(stringLiteral: string) == expectedVersion)
    }

    @Test("Lower versions are ordered before higher ones", arguments: [
        ("1.1.1", "2.2.2"),
        ("1.1.1", "1.2.2"),
        ("1.1.1", "1.1.2")
    ])
    func lowerVersionsAreOrderedBeforeHigherOnes(
        lhs: SemanticVersion,
        rhs: SemanticVersion
    ) {
        #expect(lhs < rhs)
    }

}
