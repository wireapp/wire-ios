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

@testable import WireFoundation

struct LeadingTrailingDebouncerTests {

    @MainActor
    @Test(arguments: [UUID(), UUID?.none])
    func single(id: UUID?) async throws {
        let sut = LeadingTrailingDebouncer(cooldownTime: 0.2)

        var result = [Int]()

        sut.call(id: nil) { result += [0] }
        try await Task.sleep(for: .seconds(3))

        #expect(result == [0])
    }

    @MainActor
    @Test(arguments: [UUID(), UUID?.none])
    func firstAndLast(id: UUID?) async throws {
        let sut = LeadingTrailingDebouncer(cooldownTime: 0.2)

        var result = [Int]()

        sut.call(id: id) { result += [0] }
        sut.call(id: id) { result += [1] }
        sut.call(id: id) { result += [2] }
        sut.call(id: id) { result += [3] }
        sut.call(id: id) { result += [4] }
        try await Task.sleep(for: .seconds(0.3))

        #expect(result == [0, 4])
    }

    @MainActor
    @Test(arguments: [UUID(), UUID?.none])
    func skip1(id: UUID?) async throws {
        let sut = LeadingTrailingDebouncer(cooldownTime: 0.2)

        var result = [Int]()

        sut.call(id: id) { result += [0] }
        sut.call(id: id) { result += [1] }
        try await Task.sleep(for: .seconds(0.05))
        sut.call(id: id) { result += [2] }
        try await Task.sleep(for: .seconds(0.3))
        sut.call(id: id) { result += [3] }
        sut.call(id: id) { result += [4] }
        try await Task.sleep(for: .seconds(0.3))

        #expect(result == [0, 2, 3, 4])
    }

}
