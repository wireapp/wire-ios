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
import WireFoundation
import WireFoundationSupport
import WireTestingPackage
import XCTest

@testable import WireCallingDomain
@testable import WireCallingDomainSupport
@testable import WireCallingUI

final class EditMeetingFormViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    // MARK: - Pre-filled Form

    @MainActor
    func testPrefilledFormColorSchemeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            MeetingFormView(viewModel: makeViewModel())
        }
        .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testPrefilledFormDynamicTypeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            MeetingFormView(viewModel: makeViewModel())
        }
        .frame(width: screenBounds.width, height: screenBounds.height)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

    // MARK: - Helpers

    @MainActor
    private func makeViewModel() -> MeetingFormViewModel {
        let dateProviderMock = CurrentDateProvidingMock()
        dateProviderMock.now = try! Date.ISO8601FormatStyle().parse("2026-06-11T18:15:00+02:00")

        let start = try! Date.ISO8601FormatStyle().parse("2026-06-12T10:00:00+02:00")
        let meeting = Meeting(
            id: QualifiedID(id: UUID(), domain: "example.com"),
            title: "Design review",
            start: start,
            end: start.addingTimeInterval(.oneHour),
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 1),
            members: [
                MeetingMember(
                    qualifiedID: QualifiedID(id: UUID(), domain: "example.com"),
                    name: "Katie Armstrong",
                    handle: "katie"
                ),
                MeetingMember(
                    qualifiedID: QualifiedID(id: UUID(), domain: "example.com"),
                    name: "Marco Weissnat",
                    handle: "marco"
                )
            ],
            conversationID: QualifiedID(id: UUID(), domain: "example.com"),
            creatorID: QualifiedID(id: UUID(), domain: "example.com")
        )

        return MeetingFormViewModel(
            mode: .edit(meeting),
            searchMembersUseCase: SearchMembersUseCaseProtocolMock(),
            createMeetingUseCase: CreateMeetingUseCaseProtocolMock(),
            updateMeetingUseCase: UpdateMeetingUseCaseProtocolMock(),
            currentDateProvider: dateProviderMock
        )
    }

}
