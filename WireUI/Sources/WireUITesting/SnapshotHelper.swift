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
import SwiftUI
import XCTest

/// A helper object for verifying image snapshots.
///
/// Create variations of the snapshot behavior using the "with" methods.

struct SnapshotHelper {

    private var perceptualPrecision: Float = 0.98
    private var traits = UITraitCollection()
    private var layout: SwiftUISnapshotLayout = .sizeThatFits

    // MARK: - Create variations

    /// Create a copy of the current helper with new perceptual precision.
    ///
    /// Perceptual precision is the threshold at which two pixels are considered to be the same.
    ///
    /// - Parameter perceptualPrecision: The new perceptual precision. A value of 1 indicates exact precision, a value of 0 indicates no precision.
    /// - Returns: A copy of the current helper with the new perceptual precision.

    func withPerceptualPrecision(_ perceptualPrecision: Float) -> Self {
        var helper = self
        helper.perceptualPrecision = perceptualPrecision
        return helper
    }

    /// Create a copy of the current helper with a new layout.
    ///
    /// - Parameter layout: The desired snapshot layout.
    /// - Returns: A copy of the current helper with a new layout.

    func withLayout(_ layout: SwiftUISnapshotLayout) -> Self {
        var helper = self
        helper.layout = layout
        return helper
    }

    /// Create a copy of the current helper with a user interface style.
    ///
    /// - Parameter style: The desired user interface style.
    /// - Returns: A copy of the current helper with a new user interface style.

    func withUserInterfaceStyle(_ style: UIUserInterfaceStyle) -> Self {
        var helper = self
        helper.traits = UITraitCollection(traitsFrom: [
            helper.traits,
            UITraitCollection(userInterfaceStyle: style)
        ])
        return helper
    }

    /// Create a copy of the current helper with a preferred content size category.
    ///
    /// - Parameter category: The desired preferred content size category.
    /// - Returns: A copy of the current helper with a new preferred content size category.

    func withPreferredContentSizeCategory(_ category: UIContentSizeCategory) -> Self {
        var helper = self
        helper.traits = UITraitCollection(traitsFrom: [
            helper.traits,
            UITraitCollection(preferredContentSizeCategory: category)
        ])
        return helper
    }

    // MARK: - Verify views

    /// Verify a SwiftUI view.
    ///
    /// - Parameters:
    ///   - testName: The name of the reference image.
    ///   - file: The invoking file name.
    ///   - line: The invoking line numer.
    ///   - createView: A closure that provides the view to test.

    func verify<View: SwiftUI.View>(
        testName: String = #function,
        file: StaticString = #file,
        line: UInt = #line,
        matching createView: () -> View
    ) {
        verify(
            matching: createView(),
            testName: testName,
            file: file,
            line: line
        )
    }

    /// Verify a SwiftUI view.
    ///
    /// - Parameters:
    ///   - value: The view to test.
    ///   - testName: The name of the reference image.
    ///   - file: The invoking file name.
    ///   - line: The invoking line numer.

    func verify<View: SwiftUI.View>(
        matching value: View,
        testName: String = #function,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let failure = verifySnapshot(
            matching: value,
            as: .image(
                perceptualPrecision: perceptualPrecision,
                layout: layout,
                traits: traits
            ),
            snapshotDirectory: snapshotDirectory(file: file),
            file: file,
            testName: testName,
            line: line
        )

        XCTAssertNil(failure, file: file, line: line)
    }

    /// Verifies a `UIViewController`.
    ///
    /// - Parameters:
    ///   - value: The `UIViewController` to test.
    ///   - size: An optional `CGSize` to specify a custom size for the snapshot. Defaults to `nil`.
    ///   - name: An optional string to name the snapshot. Defaults to `nil`.
    ///   - recording: A `Bool` indicating whether to record a new reference snapshot. Defaults to `false`.
    ///   - file: The invoking file name.
    ///   - testName: The name of the reference image.
    ///   - line: The invoking line number.

    func verify(
        matching value: UIViewController,
        size: CGSize? = nil,
        named name: String? = nil,
        record recording: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let config = size.map { ViewImageConfig(safeArea: UIEdgeInsets.zero, size: $0, traits: traits) }

        let failure = verifySnapshot(
            matching: value,
            as: config.map { .image(on: $0, perceptualPrecision: perceptualPrecision, traits: traits) } ?? .image(perceptualPrecision: perceptualPrecision, traits: traits),
            named: name,
            record: recording,
            snapshotDirectory: snapshotDirectory(file: file),
            file: file,
            testName: testName,
            line: line
        )

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
            as: .image(perceptualPrecision: perceptualPrecision, traits: traits),
            named: name,
            snapshotDirectory: snapshotDirectory(file: file),
            file: file,
            testName: testName,
            line: line
        )

        XCTAssertNil(failure, file: file, line: line)
    }

    /// Verifies that a given `UIView` renders correctly across all supported Dynamic Type content size categories.
    ///
    /// - Parameters:
    ///   - value: The `UIView` instance that you want to verify.
    ///   - name: The name of the reference image.
    ///   - file: The invoking file name.
    ///   - testName: The name of the reference image.
    ///   - line: The invoking line number.

    func verifyForDynamicType(
        matching value: UIView,
        named name: String? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        [
            "extra-small": UIContentSizeCategory.extraSmall,
            "small": .small,
            "medium": .medium,
            "large": .large,
            "extra-large": .extraLarge,
            "extra-extra-large": .extraExtraLarge,
            "extra-extra-extra-large": .extraExtraExtraLarge,
            "accessibility-medium": .accessibilityMedium,
            "accessibility-large": .accessibilityLarge,
            "accessibility-extra-large": .accessibilityExtraLarge,
            "accessibility-extra-extra-large": .accessibilityExtraExtraLarge,
            "accessibility-extra-extra-extra-large": .accessibilityExtraExtraExtraLarge
        ].forEach { name, contentSize in
            let failure = verifySnapshot(
                matching: value,
                as: .image(
                    traits: .init(preferredContentSizeCategory: contentSize)
                ),
                named: name,
                snapshotDirectory: snapshotDirectory(file: file),
                file: file,
                testName: testName,
                line: line
            )

            XCTAssertNil(failure, file: file, line: line)
        }

    }

    func snapshotDirectory(file: StaticString = #file) -> String {
        let fileName = "\(file)"
        let path = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]! + "/" + URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        return path
    }

}
