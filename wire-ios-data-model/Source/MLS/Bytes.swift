//
// Wire
<<<<<<<< HEAD:wire-ios/Wire-iOS Tests/StringCapitalizationTests.swift
// Copyright (C) 2023 Wire Swiss GmbH
========
// Copyright (C) 2022 Wire Swiss GmbH
>>>>>>>> feat/mls:wire-ios-data-model/Source/MLS/Bytes.swift
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

<<<<<<<< HEAD:wire-ios/Wire-iOS Tests/StringCapitalizationTests.swift
final class StringCapitalizationTests: XCTestCase {

    func testThatTheFirstLetterOfTheSentenceIsCapitalized() {
        // GIVEN
        let givenString = "hello world!"

        // WHEN
        let result = givenString.capitalizingFirstCharacterOnly

        // THEN
        XCTAssertEqual(result, "Hello world!")
========
public typealias Bytes = [UInt8]

public extension Bytes {

    var data: Data {
        return .init(self)
    }

    var base64EncodedString: String {
        return data.base64EncodedString()
    }

    init?(base64Encoded: String) {
        guard let bytes = Data(base64Encoded: base64Encoded)?.bytes else {
            return nil
        }
        self = bytes
    }

}

public extension Data {

    var bytes: Bytes {
        return .init(self)
>>>>>>>> feat/mls:wire-ios-data-model/Source/MLS/Bytes.swift
    }

}
