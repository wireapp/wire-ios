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
import WireTestingPackage
import XCTest
@testable import WireCallingDomain
@testable import WireCallingDomainSupport
@testable import WireCallingUI

final class MeetingsViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    // MARK: - Next Tab Empty State

    @MainActor
    func testEmptyNextTabColorSchemeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            MeetingsView(viewModel: createEmptyViewModel())
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
    func testEmptyNextTabDynamicTypeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            MeetingsView(viewModel: createEmptyViewModel())
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

    // MARK: - Past Tab Empty State

    @MainActor
    func testEmptyPastTabColorSchemeVariants() {
        let screenBounds = UIScreen.main.bounds
        let viewModel = createEmptyViewModel()
        viewModel.selectedTab = .past

        let view = NavigationStack {
            MeetingsView(viewModel: viewModel)
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
    func testEmptyPastTabDynamicTypeVariants() {
        let screenBounds = UIScreen.main.bounds
        let viewModel = createEmptyViewModel()
        viewModel.selectedTab = .past

        let view = NavigationStack {
            MeetingsView(viewModel: viewModel)
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

    private func createEmptyViewModel() -> MeetingsViewModel {
        let mockRepository = MockMeetingsRepositoryProtocol()
        mockRepository.fetchOngoingMeetingsAt_MockValue = []
        mockRepository.hasUpcomingMeetingsAfter_MockValue = false

        let pastMeetingsUseCase = MockFetchPastMeetingsUseCaseProtocol()
        pastMeetingsUseCase.invoke_MockValue = []

        let upcomingMeetingsUseCase = MockFetchUpcomingMeetingsUseCaseProtocol()
        upcomingMeetingsUseCase.invokeLimitToTwoDaysPageSizeOffset_MockValue = PaginatedGroupedMeetings(
            groups: [],
            hasMore: false,
            nextOffset: 0
        )

        return MeetingsViewModel(
            repository: mockRepository,
            currentDateProvider: .system,
            formatter: MeetingsFormatter(),
            pastMeetingsUseCase: pastMeetingsUseCase,
            upcomingMeetingsUseCase: upcomingMeetingsUseCase
        )
    }
}
