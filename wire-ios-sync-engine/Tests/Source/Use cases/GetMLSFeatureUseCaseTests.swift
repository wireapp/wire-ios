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

import WireDataModelSupport
import XCTest
@testable import WireSyncEngine

final class GetMLSFeatureUseCaseTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()

        mockRepository = MockFeatureRepositoryInterface()
        mockRepository.fetchMLS_MockValue = .init(status: .enabled, config: .init())
    }

    func testInvoke() {
        // given
        let useCase = makeUseCase()

        // when
        let feature = useCase.invoke()

        // then
        XCTAssertEqual(feature.status, .enabled)
    }

    func testInvokeAsync() async {
        // given
        let useCase = makeUseCase()

        // when
        let feature = await useCase.invoke()

        // then
        XCTAssertEqual(feature.status, .enabled)
    }

    // MARK: Private

    private var mockRepository: MockFeatureRepositoryInterface!

    // MARK: Helper

    private func makeUseCase() -> GetMLSFeatureUseCase {
        GetMLSFeatureUseCase(featureRepository: mockRepository)
    }
}
