//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import SwiftUI
import Testing
@testable import WireCallingUI
@testable import WireReusableUIComponents

@Suite("CreateInstantMeetingViewModel Tests")
struct CreateInstantMeetingViewModelTests {

    private let mockPasswordValidator: MockPasswordValidator
    private let viewModel: CreateInstantMeetingViewModel

    init() {
        self.mockPasswordValidator = MockPasswordValidator()
        self.viewModel = CreateInstantMeetingViewModel(
            passwordValidator: mockPasswordValidator,
            isContextMenuAllowed: true
        )
    }

    // MARK: - isNextButtonEnabled Tests

    @Test("isNextButtonEnabled is false with empty title")
    func isNextButtonEnabled_EmptyTitle() {
        // Given
        viewModel.meetingTitle = ""
        viewModel.password = ""

        // Then
        #expect(viewModel.isNextButtonEnabled == false)
    }

    @Test("isNextButtonEnabled is false with whitespace-only title")
    func isNextButtonEnabled_WhitespaceTitle() {
        // Given
        viewModel.meetingTitle = "   "
        viewModel.password = ""

        // Then
        #expect(viewModel.isNextButtonEnabled == false)
    }

    @Test("isNextButtonEnabled is true with valid title and no password")
    func isNextButtonEnabled_ValidTitleNoPassword() {
        // Given
        viewModel.meetingTitle = "Team Standup"
        viewModel.password = ""

        // Then
        #expect(viewModel.isNextButtonEnabled == true)
    }

    @Test("isNextButtonEnabled is true with valid title and valid password")
    func isNextButtonEnabled_ValidTitleValidPassword() {
        // Given
        mockPasswordValidator.isPasswordValid_MockValue = true
        viewModel.meetingTitle = "Team Standup"
        viewModel.password = "ValidPass123"
        viewModel.confirmedPassword = "ValidPass123"

        // Then
        #expect(viewModel.isNextButtonEnabled == true)
    }

    @Test("isNextButtonEnabled is false with valid title but invalid password")
    func isNextButtonEnabled_ValidTitleInvalidPassword() {
        // Given
        mockPasswordValidator.isPasswordValid_MockValue = false
        viewModel.meetingTitle = "Team Standup"
        viewModel.password = "weak"

        // Then
        #expect(viewModel.isNextButtonEnabled == false)
    }

    @Test("isNextButtonEnabled is false with valid title and password but mismatched confirmation")
    func isNextButtonEnabled_MismatchedPasswords() {
        // Given
        mockPasswordValidator.isPasswordValid_MockValue = true
        viewModel.meetingTitle = "Team Standup"
        viewModel.password = "ValidPass123"
        viewModel.confirmedPassword = "DifferentPass123"

        // Then
        #expect(viewModel.isNextButtonEnabled == false)
    }

    @Test("isNextButtonEnabled is true with valid title, empty password, and empty confirmation")
    func isNextButtonEnabled_EmptyPasswords() {
        // Given
        viewModel.meetingTitle = "Team Standup"
        viewModel.password = ""
        viewModel.confirmedPassword = ""

        // Then
        #expect(viewModel.isNextButtonEnabled == true)
    }

    // MARK: - Password Validation Tests

    @Test("isPasswordValid returns true for empty password")
    func isPasswordValid_EmptyPassword() {
        // Given
        viewModel.password = ""

        // Then
        #expect(viewModel.isPasswordValid == true)
    }

    @Test("isPasswordValid returns true for valid password")
    func isPasswordValid_ValidPassword() {
        // Given
        mockPasswordValidator.isPasswordValid_MockValue = true
        viewModel.password = "ValidPass123"

        // Then
        #expect(viewModel.isPasswordValid == true)
    }

    @Test("isPasswordValid returns false for invalid password")
    func isPasswordValid_InvalidPassword() {
        // Given
        mockPasswordValidator.isPasswordValid_MockValue = false
        viewModel.password = "weak"

        // Then
        #expect(viewModel.isPasswordValid == false)
    }

    @Test("isPasswordValid calls validator with correct password")
    func isPasswordValid_CallsValidator() {
        // Given
        mockPasswordValidator.isPasswordValid_MockValue = true
        viewModel.password = "TestPassword123"

        // When
        _ = viewModel.isPasswordValid

        // Then
        #expect(mockPasswordValidator.isPasswordValid_Invocations[0] == "TestPassword123")
    }

    // MARK: - Confirmed Password Validation Tests

    @Test("isConfirmedPasswordValid returns true for empty confirmation")
    func isConfirmedPasswordValid_EmptyConfirmation() {
        // Given
        viewModel.password = "SomePassword"
        viewModel.confirmedPassword = ""

        // Then
        #expect(viewModel.isConfirmedPasswordValid == true)
    }

    @Test("isConfirmedPasswordValid returns true when passwords match")
    func isConfirmedPasswordValid_MatchingPasswords() {
        // Given
        viewModel.password = "ValidPass123"
        viewModel.confirmedPassword = "ValidPass123"

        // Then
        #expect(viewModel.isConfirmedPasswordValid == true)
    }

    @Test("isConfirmedPasswordValid returns false when passwords do not match")
    func isConfirmedPasswordValid_MismatchedPasswords() {
        // Given
        viewModel.password = "ValidPass123"
        viewModel.confirmedPassword = "DifferentPass123"

        // Then
        #expect(viewModel.isConfirmedPasswordValid == false)
    }

    @Test("isConfirmedPasswordValid is case-sensitive")
    func isConfirmedPasswordValid_CaseSensitive() {
        // Given
        viewModel.password = "Password123"
        viewModel.confirmedPassword = "password123"

        // Then
        #expect(viewModel.isConfirmedPasswordValid == false)
    }

    @Test("changing meetingTitle updates isNextButtonEnabled")
    func changingMeetingTitle_UpdatesButton() {
        // Given
        viewModel.meetingTitle = ""
        #expect(viewModel.isNextButtonEnabled == false)

        // When
        viewModel.meetingTitle = "New Meeting"

        // Then
        #expect(viewModel.isNextButtonEnabled == true)
    }

    @Test("trimming whitespace from title is handled correctly")
    func trimmingWhitespace() {
        // Given
        viewModel.meetingTitle = "  Meeting Title  "

        // Then
        #expect(viewModel.isNextButtonEnabled == true)
    }

}
