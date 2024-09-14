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

@testable import Wire

// Precision of matching snapshots. Lower this value to fix issue with difference with Intel and Apple Silicon
private let precision: Float = 0.90
private let perceptualPrecision: Float = 0.98

// MARK: - snapshoting all iPhone sizes

extension XCTestCase {

    func verifyInWidths(matching value: UIView,
                        widths: Set<CGFloat>,
                        snapshotBackgroundColor: UIColor,
                        configuration: ((UIView) -> Swift.Void)? = nil,
                        named name: String? = nil,
                        file: StaticString = #file,
                        testName: String = #function,
                        line: UInt = #line) {
        let container = containerView(with: value,
                                      snapshotBackgroundColor: snapshotBackgroundColor)
        let widthConstraint = container.addWidthConstraint(width: 300)

        for width in widths {
            widthConstraint.constant = width

            configuration?(container)

            verifyWithWidthInName(matching: container,
                                  width: width,
                                  named: name,
                                  file: file,
                                  testName: testName,
                                  line: line)
        }
    }

    private func verifyWithWidthInName(matching value: UIView,
                                       width: CGFloat,
                                       named name: String? = nil,
                                       file: StaticString = #file,
                                       testName: String = #function,
                                       line: UInt = #line) {
        let nameWithProperty: String
        if let name {
            nameWithProperty = "\(name)-\(width)"
        } else {
            nameWithProperty = "\(width)"
        }

        verify(
            matching: value,
            named: nameWithProperty,
            file: file,
            testName: testName,
            line: line
        )
    }

    func verifyInAllPhoneWidths(matching value: UIView,
                                snapshotBackgroundColor: UIColor? = nil,
                                configuration: ((UIView) -> Swift.Void)? = nil,
                                named name: String? = nil,
                                file: StaticString = #file,
                                testName: String = #function,
                                line: UInt = #line) {
        verifyInWidths(matching: value,
                       widths: phoneWidths(),
                       snapshotBackgroundColor: snapshotBackgroundColor ?? (ColorScheme.default.variant == .light ? .white : .black),
                       configuration: configuration,
                       named: name,
                       file: file,
                       testName: testName,
                       line: line)
    }

}

extension XCTestCase {

    func snapshotDirectory(file: StaticString = #file) -> String {
        let fileName = "\(file)"
        let path = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]! + "/" + URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        return path
    }

    /// verify for a UIAlertController
    func verify(matching value: UIAlertController,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) throws {
        throw XCTSkip("UIAlertController is not fully supported, please rewrite your test")

        // Reset default tint color to keep constant snapshot result
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = value.view.tintColor

        // Prevent showing cursor
        value.setEditing(false, animated: false)

        // workaround for UIAlertController with actionSheet style crashes for invalid size
        if value.preferredStyle == .actionSheet {
            presentViewController(value)
        }

        let failure = verifySnapshot(of: value,
                                     as: .image(precision: precision, perceptualPrecision: perceptualPrecision),
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file, testName: testName, line: line)

        XCTAssertNil(failure, file: file, line: line)

        // workaround for UIAlertController with actionSheet style crashes for invalid size
        if value.preferredStyle == .actionSheet {
            dismissViewController(value)
        }
    }

    @available(*, deprecated, message: "Use methods from SnapshotHelper_ instead.")
    func verify(matching value: UIView,
                named name: String? = nil,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) {

        let failure = verifySnapshot(matching: value,
                                     as: .image(precision: precision, perceptualPrecision: perceptualPrecision),
                                     named: name,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file,
                                     testName: testName,
                                     line: line)

        XCTAssertNil(failure, file: file, line: line)
    }

}

extension Snapshotting where Value == UIAlertController, Format == UIImage {

    /// A snapshot strategy for comparing UIAlertController views based on pixel equality.
    /// Compare UIAlertController.view to prevert the view is resized to fix the default UIViewController.view's size
    static var image: Snapshotting<UIAlertController, UIImage> {
        return Snapshotting<UIView, UIImage>.image(precision: 1, size: nil).pullback { $0.view }
    }
}

extension UIView {
    func addWidthConstraint(width: CGFloat) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false

        let widthConstraint = widthAnchor.constraint(equalToConstant: width)

        NSLayoutConstraint.activate([widthConstraint])

        layoutIfNeeded()

        return widthConstraint
    }
}

extension XCTestCase {

    // MARK: - verify in different width helper
    func containerView(with view: UIView, snapshotBackgroundColor: UIColor?) -> UIView {
        let container = UIView(frame: view.bounds)
        container.backgroundColor = snapshotBackgroundColor
        container.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.fitIn(view: container)
        return container
    }

    func setColorScheme(_ variant: ColorSchemeVariant) {
        ColorScheme.default.variant = variant
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }

    // MARK: - UIAlertController hack
    func presentViewController(_ controller: UIViewController,
                               completion: Completion? = nil) {
        let window = UIWindow(frame: CGRect(origin: .zero, size: XCTestCase.DeviceSizeIPhone6))

        let container = UIViewController()
        container.loadViewIfNeeded()

        window.rootViewController = container
        window.makeKeyAndVisible()

        controller.loadViewIfNeeded()
        controller.view.layoutIfNeeded()

        container.present(controller, animated: false, completion: completion)
    }

    func dismissViewController(_ controller: UIViewController,
                               completion: Completion? = nil) {
        controller.dismiss(animated: false, completion: completion)
    }

    // MARK: - verify a UIViewController with a set of widths. The SUT is created in the closure instead of reusing

    func verifyInAllPhoneWidths(createSut: () -> UIView,
                                snapshotBackgroundColor: UIColor? = nil,
                                named name: String? = nil,
                                file: StaticString = #file,
                                testName: String = #function,
                                line: UInt = #line) {
        verifyInWidths(createSut: createSut,
                       widths: phoneWidths(),
                       snapshotBackgroundColor: snapshotBackgroundColor ?? (ColorScheme.default.variant == .light ? .white : .black),
                       named: name,
                       file: file,
                       testName: testName,
                       line: line)
    }

    func verifyInAllPhoneWidths(createSut: () -> UIViewController,
                                snapshotBackgroundColor: UIColor? = nil,
                                named name: String? = nil,
                                file: StaticString = #file,
                                testName: String = #function,
                                line: UInt = #line) {
        verifyInWidths(createSut: createSut,
                       widths: phoneWidths(),
                       snapshotBackgroundColor: snapshotBackgroundColor ?? (ColorScheme.default.variant == .light ? .white : .black),
                       named: name,
                       file: file,
                       testName: testName,
                       line: line)
    }

    func verifyInWidths(createSut: () -> UIView,
                        widths: Set<CGFloat>,
                        snapshotBackgroundColor: UIColor,
                        named name: String? = nil,
                        file: StaticString = #file,
                        testName: String = #function,
                        line: UInt = #line) {

        for width in widths {
            verifyInWidth(createSut: createSut,
                          width: width,
                          snapshotBackgroundColor: snapshotBackgroundColor,
                          named: name,
                          file: file,
                          testName: testName,
                          line: line)
        }
    }

    func verifyInWidths(createSut: () -> UIViewController,
                        widths: Set<CGFloat>,
                        snapshotBackgroundColor: UIColor,
                        named name: String? = nil,
                        file: StaticString = #file,
                        testName: String = #function,
                        line: UInt = #line) {

        for width in widths {
            verifyInWidth(createSut: createSut,
                          width: width,
                          snapshotBackgroundColor: snapshotBackgroundColor,
                          named: name,
                          file: file,
                          testName: testName,
                          line: line)
        }
    }

    func verifyInWidth(createSut: () -> UIView,
                       width: CGFloat,
                       snapshotBackgroundColor: UIColor,
                       named name: String? = nil,
                       file: StaticString = #file,
                       testName: String = #function,
                       line: UInt = #line) {
        let sut = createSut()
        let container = containerView(with: sut,
                                      snapshotBackgroundColor: snapshotBackgroundColor)
        _ = container.addWidthConstraint(width: width)

        if ColorScheme.default.variant == .light {
            container.overrideUserInterfaceStyle = .light
        } else {
            container.overrideUserInterfaceStyle = .dark
        }

        verifyWithWidthInName(matching: container,
                              width: width,
                              named: name,
                              file: file,
                              testName: testName,
                              line: line)
    }

    func verifyInWidth(createSut: () -> UIViewController,
                       width: CGFloat,
                       snapshotBackgroundColor: UIColor,
                       named name: String? = nil,
                       file: StaticString = #file,
                       testName: String = #function,
                       line: UInt = #line) {

        verifyInWidth(createSut: {
            createSut().view
        },
                      width: width,
                      snapshotBackgroundColor: snapshotBackgroundColor,
                      named: name,
                      file: file,
                      testName: testName,
                      line: line)
    }
}
