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

import WireTestingPackage
import XCTest
import SwiftUI

@testable import WireFoundation

final class UIImage_fromSolidColorTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(relativeTo: #file)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    func testImagesMatch() {

        let testColors: [(String, UIColor)] = [
("black", .black),
("darkGray", .darkGray),
("lightGray", .lightGray),
("white", .white),
("gray", .gray),
("red", .red),
("green", .green),
("blue", .blue),
("cyan", .cyan),
("yellow", .yellow),
("magenta", .magenta),
("orange", .orange),
("purple", .purple),
("brown", .brown),
("clear", .clear)
        ]
        for (name, color) in testColors {
            let sut = UIImage.from(solidColor: color)
            XCTAssertEqual(sut.size.width, 1)
            XCTAssertEqual(sut.size.height, 1)
            let image = Image(uiImage: sut)
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: image, named: name)
        }
    }
}
