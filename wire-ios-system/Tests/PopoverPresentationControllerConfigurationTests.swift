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

import XCTest
@testable import WireSystem

final class PopoverPresentationControllerConfigurationTests: XCTestCase {
    private typealias SUT = PopoverPresentationControllerConfiguration

    @MainActor
    func testConfiguringBarButtonItem() throws {
        if UIDevice.current.userInterfaceIdiom == .phone {
            throw XCTSkip("not relevant")
        }

        // Given
        let barButtonItem = UIBarButtonItem(systemItem: .refresh)
        let configuration = SUT.barButtonItem(barButtonItem)
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

        // When
        alertController.configurePopoverPresentationController(using: configuration)

        // Then
        let popoverPresentationController = try XCTUnwrap(alertController.popoverPresentationController)
        XCTAssertNil(popoverPresentationController.sourceView)
        XCTAssertEqual(popoverPresentationController.sourceRect, CGRect.null)
        XCTAssertTrue(popoverPresentationController.barButtonItem === barButtonItem)
    }

    @MainActor
    func testConfiguringSourceView() throws {
        if UIDevice.current.userInterfaceIdiom == .phone {
            throw XCTSkip("not relevant")
        }

        // Given
        let sourceView = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))
        let sourceRect = CGRect(x: 2, y: 2, width: 6, height: 6)
        let configuration = SUT.sourceView(sourceView: sourceView, sourceRect: sourceRect)
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

        // When
        alertController.configurePopoverPresentationController(using: configuration)

        // Then
        let popoverPresentationController = try XCTUnwrap(alertController.popoverPresentationController)
        XCTAssertTrue(popoverPresentationController.sourceView === sourceView)
        XCTAssertEqual(popoverPresentationController.sourceRect, sourceRect)
        XCTAssertNil(popoverPresentationController.barButtonItem)
    }

    @MainActor
    func testConfiguringSourceViewxx() throws {
        if UIDevice.current.userInterfaceIdiom == .phone {
            throw XCTSkip("not relevant")
        }

        // Given
        let sourceView = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))
        let anchorView = UIView(frame: .init(x: 2, y: 2, width: 6, height: 6))
        sourceView.addSubview(anchorView)
        let configuration = try XCTUnwrap(SUT.superviewAndFrame(of: anchorView, insetBy: (dx: 1, dy: 1)))
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

        // When
        alertController.configurePopoverPresentationController(using: configuration)

        // Then
        let popoverPresentationController = try XCTUnwrap(alertController.popoverPresentationController)
        XCTAssertTrue(popoverPresentationController.sourceView === sourceView)
        XCTAssertEqual(popoverPresentationController.sourceRect, .init(x: 3, y: 3, width: 4, height: 4))
        XCTAssertNil(popoverPresentationController.barButtonItem)
    }
}
