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

final class CreateScheduledMeetingFormViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    // MARK: - Empty State

    @MainActor
    func testEmptyStateColorSchemeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            CreateMeetingFormView(viewModel: makeViewModel())
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
    func testEmptyStateDynamicTypeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            CreateMeetingFormView(viewModel: makeViewModel())
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

    private func makeViewModel() -> CreateMeetingFormViewModel {
        let viewModel = CreateMeetingFormViewModel(
            mode: .scheduled,
            memberRepository: MemberRepositoryProtocolMock()
        )
        viewModel.startDate = try! Date.ISO8601FormatStyle().parse("2026-06-11T18:15:00+02:00")
        viewModel.endDate = viewModel.startDate.addingTimeInterval(60 * 30) // 30 minutes
        return viewModel
    }

}
