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

import UIKit
import XCTest

@testable import Wire

final class AuthenticationStepViewModelTests: XCTestCase {

    func testDisplayStateForInfoValidationShowsValidationRules() {
        let sut = AuthenticationStepViewModel(initialValidation: nil, secondaryView: nil)

        let displayState = sut.displayState(for: .info("Use at least 8 characters"))

        XCTAssertEqual(displayState.validationMessage, "Use at least 8 characters")
        XCTAssertEqual(displayState.validationAccessibilityIdentifier, "validation-rules")
        XCTAssertEqual(displayState.validationMessageStyle, .info)
        XCTAssertFalse(displayState.isValidationMessageHidden)
        XCTAssertFalse(displayState.shouldAnnounceValidationMessage)
        XCTAssertNil(displayState.secondaryErrorDescription)
    }

    func testDisplayStateForVisibleErrorShowsValidationFailureAndSecondaryErrorDescription() {
        let secondaryErrorDescription = MockViewDescriptor()
        let secondaryView = MockSecondaryViewDescription(errorDescription: secondaryErrorDescription)
        let sut = AuthenticationStepViewModel(initialValidation: nil, secondaryView: secondaryView)

        let displayState = sut.displayState(for: .error(.custom("Invalid value"), showVisualFeedback: true))

        XCTAssertEqual(displayState.validationMessage, "Invalid value")
        XCTAssertEqual(displayState.validationAccessibilityIdentifier, "validation-failure")
        XCTAssertEqual(displayState.validationMessageStyle, .error)
        XCTAssertFalse(displayState.isValidationMessageHidden)
        XCTAssertTrue(displayState.shouldAnnounceValidationMessage)
        XCTAssertTrue(displayState.secondaryErrorDescription === secondaryErrorDescription as ViewDescriptor)
    }

    func testDisplayStateForHiddenErrorFallsBackToInitialValidation() {
        let sut = AuthenticationStepViewModel(
            initialValidation: .info("Initial guidance"),
            secondaryView: nil
        )

        let displayState = sut.displayState(for: .error(.custom("Invalid value"), showVisualFeedback: false))

        XCTAssertEqual(displayState.validationMessage, "Initial guidance")
        XCTAssertEqual(displayState.validationAccessibilityIdentifier, "validation-rules")
        XCTAssertEqual(displayState.validationMessageStyle, .info)
        XCTAssertFalse(displayState.isValidationMessageHidden)
        XCTAssertTrue(displayState.shouldAnnounceValidationMessage)
        XCTAssertNil(displayState.secondaryErrorDescription)
    }

    func testDisplayStateForNilValidationHidesValidationMessage() {
        let sut = AuthenticationStepViewModel(initialValidation: .info("Initial guidance"), secondaryView: nil)

        let displayState = sut.displayState(for: nil)

        XCTAssertNil(displayState.validationMessage)
        XCTAssertNil(displayState.validationAccessibilityIdentifier)
        XCTAssertNil(displayState.validationMessageStyle)
        XCTAssertTrue(displayState.isValidationMessageHidden)
        XCTAssertFalse(displayState.shouldAnnounceValidationMessage)
        XCTAssertNil(displayState.secondaryErrorDescription)
    }
}

private final class MockViewDescriptor: ViewDescriptor {
    func create() -> UIView {
        UIView()
    }
}

private final class MockSecondaryViewDescription: AuthenticationSecondaryViewDescription {
    weak var actioner: AuthenticationActioner?

    let views: [ViewDescriptor] = []
    private let errorDescription: ViewDescriptor?

    init(errorDescription: ViewDescriptor?) {
        self.errorDescription = errorDescription
    }

    func display(on error: Error) -> ViewDescriptor? {
        errorDescription
    }
}
