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

extension SnapshotHelper {

    ///  This function tests a `UIViewController` instance under dark and light themes to ensure that it appears correctly in both modes.
    ///
    /// - Parameters:
    ///   - createSut: A closure that creates and returns the view controsller to be tested.
    ///   - file: The invoking file name.
    ///   - testName: The name of the reference image.
    ///   - line: The invoking line number.
    ///
    /// - Note: This function calls `verifyInDarkScheme` and `verifyInLightScheme` internally to perform the validations for dark and light themes respectively.

    func verifyInAllColorSchemes(
        createSut: () -> UIViewController,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {

        verifyInDarkScheme(
            createSut: createSut,
            name: "DarkTheme",
            file: file,
            testName: testName,
            line: line
        )

        verifyInLightScheme(
            createSut: createSut,
            name: "LightTheme",
            file: file,
            testName: testName,
            line: line
        )
    }

    /// Verifies the appearance of a view controller in dark mode.
    ///
    /// - Parameters:
    ///   - createSut: A closure that creates and returns the view controller to be tested.
    ///   - name: An optional string to name the snapshot. Defaults to `nil`.
    ///   - file: The invoking file name.
    ///   - testName: The name of the reference image.
    ///   - line: The invoking line number.

    func verifyInDarkScheme(
        createSut: () -> UIViewController,
        name: String? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {

        self
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: createSut(),
                named: name,
                file: file,
                testName: testName,
                line: line
            )
    }

    /// Verifies the appearance of a view controller in light mode.
    ///
    /// - Parameters:
    ///   - createSut: A closure that creates and returns the view controller to be tested.
    ///   - name: An optional string to name the snapshot. Defaults to `nil`.
    ///   - file: The invoking file name.
    ///   - testName: The name of the reference image.
    ///   - line: The invoking line number.

    func verifyInLightScheme(
        createSut: () -> UIViewController,
        name: String? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {

        self
            .withUserInterfaceStyle(.light)
            .verify(
                matching: createSut(),
                named: name,
                file: file,
                testName: testName,
                line: line
            )
    }

    /// Verifies the appearance of a view under dark and light themes to ensure that it appears correctly in both modes.
    ///
    /// - Parameters:
    ///   - matching: The view to test..
    ///   - name: An optional string to name the snapshot. Defaults to `nil`.
    ///   - file: The invoking file name.
    ///   - testName: The name of the reference image.
    ///   - line: The invoking line number.

    func verifyViewInAllColorSchemes(
        matching: UIView,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {

        self
            .withUserInterfaceStyle(.light)
            .verify(
                matching: matching,
                named: "LightTheme",
                file: file,
                testName: testName,
                line: line
            )

        self
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: matching,
                named: "DarkTheme",
                file: file,
                testName: testName,
                line: line
            )
    }

    /// Verifies the appearance of a view in dark mode.
    ///
    /// - Parameters:
    ///   - createSut: A closure that creates and returns the view  to be tested.
    ///   - name: An optional string to name the snapshot. Defaults to `nil`.
    ///   - file: The invoking file name.
    ///   - testName: The name of the reference image.
    ///   - line: The invoking line number.

    func verifyViewInDarkScheme(
        createSut: () -> UIView,
        name: String? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let sut = createSut()
        sut.overrideUserInterfaceStyle = .dark
        verify(
            matching: createSut(),
            named: name,
            file: file,
            testName: testName,
            line: line
        )
    }

}
