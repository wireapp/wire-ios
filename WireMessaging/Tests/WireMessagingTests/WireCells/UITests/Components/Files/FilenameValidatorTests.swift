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

@testable import WireMessagingUI

@MainActor
final class FilenameValidatorTests {
    private let sut: FilenameValidator

    init() {
        self.sut = FilenameValidator()
    }

    @Test
    func `When input is valid it succeeds`() async {
        // given
        let input = "filename"

        // when
        var iterator = sut.validate(input).values.makeAsyncIterator()
        let result = await iterator.next()!

        // then
        #expect((try? result.get()) != nil)
    }

    @Test
    func `When input is too long it throws error`() async {
        // given
        let input = Array(repeating: "t", count: 65).joined()

        // then
        await #expect(throws: FilenameValidator.Failure.tooLong) {
            // when
            var iterator = sut.validate(input).values.makeAsyncIterator()
            let result = await iterator.next()!
            try result.get()
        }
    }

    @Test
    func `When input has dot prefix it throws error`() async {
        // given
        let input = ".filename"

        // then
        await #expect(throws: FilenameValidator.Failure.dotPrefix) {
            // when
            var iterator = sut.validate(input).values.makeAsyncIterator()
            let result = await iterator.next()!
            try result.get()
        }
    }

    @Test
    func `When input has slash character it throws error`() async {
        // given
        let input = "filename/"

        // then
        await #expect(throws: FilenameValidator.Failure.slashCharacter) {
            // when
            var iterator = sut.validate(input).values.makeAsyncIterator()
            let result = await iterator.next()!
            try result.get()
        }
    }

    @Test
    func `When input is empty it throws error`() async {
        // given
        let input = ""

        // then
        await #expect(throws: FilenameValidator.Failure.empty) {
            // when
            var iterator = sut.validate(input).values.makeAsyncIterator()
            let result = await iterator.next()!
            try result.get()
        }
    }
}
