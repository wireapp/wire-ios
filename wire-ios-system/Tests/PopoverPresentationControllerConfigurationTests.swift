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
    func testConfiguringBarButtonItem() {

        // Given
        let barButtonItem = UIBarButtonItem(systemItem: .refresh)
        let configuration = SUT.barButtonItem(barButtonItem)
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)

        // When
        alertController.configurePopoverPresentationController(using: configuration)

        // Then
        XCTAssertNotNil(alertController.popoverPresentationController)
        XCTAssertNil(alertController.popoverPresentationController?.sourceView)
        XCTAssertNil(alertController.popoverPresentationController?.sourceRect)
        if #available(iOS 16.0, *) {
            XCTAssertNil(alertController.popoverPresentationController?.sourceItem)
        }
        XCTAssertTrue(alertController.popoverPresentationController?.barButtonItem === barButtonItem)
    }

    // TODO: test nil controller
}
