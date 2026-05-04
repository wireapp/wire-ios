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

import XCTest
@testable import WireMessagingDomain
@testable import WireMessagingDomainSupport
@testable import WireMessagingUI

@MainActor
final class ChannelHistoryViewModelTests: XCTestCase {

    lazy var viewModel = ChannelHistoryViewModel(
        historyDepth: "",
        teamsURL: URL(string: "https://google.com")!,
        accentColor: .red,
        useCase: useCase
    )

    lazy var useCase = MockChannelHistoryUseCaseProtocol()

    func test_selectHistoryDepth_triggersUseCaseUpdate() async {
        viewModel.channelHistoryOption = .fourWeeks
        let expectation = XCTestExpectation()
        useCase.updateHistoryDepth_MockMethod = { _ in
            expectation.fulfill()
        }

        await fulfillment(of: [expectation])
        XCTAssertEqual(
            useCase.updateHistoryDepth_Invocations.count,
            1
        )
    }

    func test_fetchData_UserIsPremium_triggersValuesUpdates() async {
        useCase.isEnterpriseUser_MockValue = true
        await viewModel.fetchData()
        XCTAssertEqual(viewModel.isEnterpriseUser, true)
        XCTAssertEqual(
            viewModel.channelHistoryAvailableOptions,
            [.off, .oneDay, .oneWeek, .fourWeeks, .unlimited, .custom]
        )
    }

    func test_fetchData_UserIsNotPremium_triggersValuesUpdates() async {
        useCase.isEnterpriseUser_MockValue = false
        await viewModel.fetchData()
        XCTAssertEqual(viewModel.isEnterpriseUser, false)
        XCTAssertEqual(viewModel.channelHistoryAvailableOptions, [.off, .oneDay])
    }
}
