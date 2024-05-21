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

import SnapshotTesting
import UIKit
import XCTest

extension SnapshotHelper {

    ///    Verifiy a`UIViewController`.
    ///
    ///     - Parameters:
    ///        - value: The `UIViewController` to test.
    ///        - customSize: An optional `CGSize` to specify a custom size for the snapshot. Defaults to `nil`.
    ///        - name: An optional string to name the snapshot. Defaults to `nil`.
    ///        - recording: A `Bool` indicating whether to record a new reference snapshot. Defaults to `false`.
    ///        - file: The invoking file name.
    ///        - testName: The name of the reference image.
    ///        - line: The invoking line number.

    func verify(
        matching value: UIViewController,
        customSize: CGSize? = nil,
        named name: String? = nil,
        record recording: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {

        var config: ViewImageConfig?
        if let customSize {
            config = ViewImageConfig(safeArea: UIEdgeInsets.zero,
                                     size: customSize,
                                     traits: UITraitCollection())
        }

        let failure = verifySnapshot(matching: value,
                                     as: config == nil ? .image(perceptualPrecision: perceptualPrecision) : .image(on: config!, perceptualPrecision: perceptualPrecision),
                                     named: name,
                                     record: recording,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file,
                                     testName: testName,
                                     line: line)

        XCTAssertNil(failure, file: file, line: line)
    }

    ///    Verifiy a`UIView`.
    ///
    ///     - Parameters:
    ///        - value: The `UIView` to test.
    ///        - name: An optional string to name the snapshot. Defaults to `nil`.
    ///        - file: The invoking file name.
    ///        - testName: The name of the reference image.
    ///        - line: The invoking line number.

    func verify(
        matching value: UIView,
        named name: String? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {

        let failure = verifySnapshot(
            matching: value,
            as: .image(perceptualPrecision: perceptualPrecision),
            named: name,
            snapshotDirectory: snapshotDirectory(file: file),
            file: file,
            testName: testName,
            line: line
        )

        XCTAssertNil(failure, file: file, line: line)
    }

}
