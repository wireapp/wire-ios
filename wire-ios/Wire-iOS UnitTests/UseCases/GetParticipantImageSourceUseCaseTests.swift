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
@testable import Wire

final class GetParticipantImageSourceUseCaseTests: XCTestCase {

    let repository = MockGetParticipantImageSourceRepositoryProtocol()
    var sut: GetParticipantImageSourceUseCase!

    override func setUp() async throws {
        try await super.setUp()
        repository.invokeUser_MockValue = .some(nil)
        sut = GetParticipantImageSourceUseCase(repository: repository)
    }

    func testReturnInitials() async {
        let user = MockUserType()
        user.initials = "DS"
        let source = await sut.invoke(user: user)
        guard case let .text(initials) = source else {
            return XCTFail("Expected .text case, but got \(String(describing: source))")
        }

        XCTAssertEqual(initials, "DS")
    }

    func testReturnEmptyIfNoInitials() async {
        let user = MockUserType()
        user.initials = nil

        let source = await sut.invoke(user: user)
        guard case let .text(initials) = source else {
            return XCTFail("Expected .text case, but got \(String(describing: source))")
        }

        XCTAssertEqual(initials, "")
    }

    func testReturnImage() async {
        let user = MockUserType()
        user.initials = "JS"
        repository.invokeUser_MockValue = UIImage()
        let source = await sut.invoke(user: user)
        guard case .image = source else {
            return XCTFail("Expected .image case, but got \(String(describing: source))")
        }
    }

}
