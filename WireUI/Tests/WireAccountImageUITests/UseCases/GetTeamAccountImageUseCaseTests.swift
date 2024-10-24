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

import WireFoundation
import XCTest

@testable import WireAccountImageUI
@testable import WireAccountImageUISupport

final class GetTeamAccountImageUseCaseTests: XCTestCase {

    private var mockAccountImageGenerator: MockAccountImageGeneratorProtocol!
    private var mockUser: MockUser!
    private var mockAccount: MockAccount!
    private var sut: GetTeamAccountImageUseCase<MockAccountImageGeneratorProtocol>!

    override func setUp() {
        mockAccountImageGenerator = .init()
        sut = .init(accountImageGenerator: mockAccountImageGenerator)
        mockUser = .init()
        mockAccount = .init()
    }

    override func tearDown() {
        mockAccount = nil
        mockUser = nil
        sut = nil
        mockAccountImageGenerator = nil
    }

    func testTeamImageDataMatches() async throws {
        // Given
        let expectedData = try imageData(from: .green)
        mockUser.membership?.team?.teamImageSource = .data(expectedData)

        // When
        let actualData = try await sut.invoke(user: mockUser, account: mockAccount).pngData()

        // Then
        XCTAssertEqual(expectedData, actualData)
    }

    func testTeamNameImageDataMatches() async throws {
        // Given
        let expectedData = try imageData(from: .green)
        mockAccountImageGenerator.createImageInitials_MockValue = try XCTUnwrap(.init(data: expectedData))
        mockUser.membership?.team?.teamImageSource = .text(initials: "W")

        // When
        let actualData = try await sut.invoke(user: mockUser, account: mockAccount).pngData()

        // Then
        XCTAssertEqual(expectedData, actualData)
    }

    @MainActor
    func testAccountImageDataMatches() async throws {
        // Given
        let expectedData = try imageData(from: .green)
        mockAccount.teamImageSource = .data(expectedData)

        // When
        let actualData = try await sut.invoke(user: mockUser, account: mockAccount).pngData()

        // Then
        XCTAssertEqual(expectedData, actualData)
    }

    @MainActor
    func testAccountTeamNameInitalsImageDataMatches() async throws {
        // Given
        let expectedData = try imageData(from: .green)
        mockAccount.teamName = " Wire Team "
        mockAccountImageGenerator.createImageInitials_MockValue = try XCTUnwrap(.init(data: expectedData))

        // When
        let actualData = try await sut.invoke(user: mockUser, account: mockAccount).pngData()

        // Then
        XCTAssertEqual(mockAccountImageGenerator.createImageInitials_Invocations.count, 1)
        XCTAssertEqual(mockAccountImageGenerator.createImageInitials_Invocations.first, "W")
        XCTAssertEqual(expectedData, actualData)
    }

    func testErrorIsThrown() async throws {
        // When
        do {
            _ = try await sut.invoke(user: mockUser, account: mockAccount)
            XCTFail("Unexpected success")
        } catch GetTeamAccountImageUseCase.Error.invalidImageSource {
            // Then
        }
    }

    // MARK: -

    private func imageData(from solidColor: UIColor) throws -> Data {
        var image = UIImage.from(solidColor: solidColor)
        let data = try XCTUnwrap(image.pngData())
        // do another iteration so that the byte-comparission succeeds
        image = try XCTUnwrap(.init(data: data))
        return try XCTUnwrap(image.pngData())
    }
}
