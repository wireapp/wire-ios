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

import WireAnalyticsSupport
import XCTest

@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class EnableAnalyticsUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var sut: EnableAnalyticsUseCase<MockEnableAnalyticsUseCaseUserSession>!
    private var mockAnalyticsManagerProvider: MockAnalyticsManagerProviding!
    private var mockAnalyticsManager: MockAnalyticsManagerProtocol!
    private var sessionConfiguration: AnalyticsSessionConfiguration!
    private var userProfile: AnalyticsUserProfile!
    private var mockUserSession: MockEnableAnalyticsUseCaseUserSession!

    // MARK: - setUp

    override func setUp() {

        sessionConfiguration = .init(countlyKey: "", host: .init(fileURLWithPath: "/"))
        userProfile = .init(analyticsIdentifier: "")
        mockAnalyticsManager = MockAnalyticsManagerProtocol()
        mockAnalyticsManagerProvider = MockAnalyticsManagerProviding()
        mockAnalyticsManagerProvider.analyticsManager = mockAnalyticsManager
        mockUserSession = .init()

        sut = .init(
            sessionManager: mockAnalyticsManagerProvider,
            analyticsSessionConfiguration: sessionConfiguration,
            analyticsUserProfile: userProfile,
            userSession: mockUserSession
        )
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockAnalyticsManagerProvider = nil
        mockAnalyticsManager = nil
        sessionConfiguration = nil
        userProfile = nil
    }

    // MARK: - Unit Tests

    func testTODO() {
        XCTFail("TODO: write tests")
    }
}
