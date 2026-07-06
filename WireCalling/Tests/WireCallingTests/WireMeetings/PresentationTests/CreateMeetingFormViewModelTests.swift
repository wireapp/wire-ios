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

import SwiftUI
import Testing
import WireCallingDomain
import WireCallingDomainSupport
import WireFoundationSupport

@testable import WireCallingUI

@MainActor
struct CreateMeetingFormViewModelTests {

    private let viewModel: CreateMeetingFormViewModel

    init() {
        let dateProviderMock = CurrentDateProvidingMock()
        dateProviderMock.now = try! Date.ISO8601FormatStyle().parse("2026-07-06T14:18:00+02:00")
        self.viewModel = CreateMeetingFormViewModel(
            mode: .instant,
            memberRepository: MemberRepositoryProtocolMock(),
            createInstantMeetingUseCase: CreateInstantMeetingUseCaseProtocolMock(),
            createScheduledMeetingUseCase: CreateScheduledMeetingUseCaseProtocolMock(),
            currentDateProvider: dateProviderMock
        )
    }

    // MARK: - isNextButtonEnabled Tests

    @Test("isNextButtonEnabled is false with empty title")
    func isNextButtonEnabled_EmptyTitle() {
        // Given
        viewModel.meetingTitle = ""

        // Then
        #expect(viewModel.isNextButtonEnabled == false)
    }

    @Test("isNextButtonEnabled is false with whitespace-only title")
    func isNextButtonEnabled_WhitespaceTitle() {
        // Given
        viewModel.meetingTitle = "   "

        // Then
        #expect(viewModel.isNextButtonEnabled == false)
    }

    @Test("isNextButtonEnabled is true with valid title")
    func isNextButtonEnabled_EmptyPasswords() {
        // Given
        viewModel.meetingTitle = "Team Standup"

        // Then
        #expect(viewModel.isNextButtonEnabled == true)
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
