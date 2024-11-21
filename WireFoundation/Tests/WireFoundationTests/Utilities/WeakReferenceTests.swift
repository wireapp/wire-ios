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

import SwiftUI
import WireTestingPackage
import XCTest

@testable import WireFoundation

final class WeakReferenceTests: XCTestCase {

    private var object: NSObject!
    private var sut: WeakReference<NSObject>!

    override func setUp() {
        object = .init()
        sut = .init(reference: object)
    }

    override func tearDown() {
        sut = nil
        object = nil
    }

    func testInitialization() {
        XCTAssertNotNil(sut.reference)
        XCTAssert(sut.reference === object)
    }

    func testObjectIsNotRetained() async {
        // When
        object = nil
        await Task.yield()

        // Then
        XCTAssertNil(sut.reference)
    }

    @MainActor
    func testStoringInArray() async {
        // Given
        var objects = (0 ... 4)
            .map { _ in NSObject() }
        let weakReferences = objects
            .map { WeakReference($0) }

        // When
        objects.removeAll()
        await Task.yield()

        // Then
        let nonNilReferences = weakReferences.compactMap(\.reference)
        XCTAssertTrue(nonNilReferences.isEmpty)
    }
}
