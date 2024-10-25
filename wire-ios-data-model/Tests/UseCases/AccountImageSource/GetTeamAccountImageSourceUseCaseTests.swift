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

import WireDataModel
import WireDataModelSupport
import XCTest

final class GetTeamAccountImageSourceUseCaseTests: XCTestCase {

//    private var mockAccountImageGenerator: MockAccountImageGenerator!
//    private var mockUser: MockUser!
//    private var mockAccount: MockAccount!
    private var coreDataStack: CoreDataStack!
    private var sut: GetTeamAccountImageSourceUseCase!

    @MainActor
    override func setUp() async throws {
        coreDataStack = try await CoreDataStackHelper().createStack()

//        mockAccountImageGenerator = .init()
        sut = .init()
//        mockUser = .init()
//        mockAccount = .init()
    }

    override func tearDown() {
//        mockAccount = nil
//        mockUser = nil
        sut = nil
//        mockAccountImageGenerator = nil
    }
/*
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
        mockAccountImageGenerator.resultImage = try XCTUnwrap(.init(data: expectedData))
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
        mockAccountImageGenerator.resultImage = try XCTUnwrap(.init(data: expectedData))

        // When
        let actualData = try await sut.invoke(user: mockUser, account: mockAccount).pngData()

        // Then
        XCTAssertEqual(mockAccountImageGenerator.createImage_Invocations.count, 1)
        XCTAssertEqual(mockAccountImageGenerator.createImage_Invocations.first?.initials, "W")
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
 */

    // MARK: - Helper

    private func imageData(from solidColor: UIColor) throws -> Data {
        var image = UIImage.from(solidColor: solidColor)
        let data = try XCTUnwrap(image.pngData())
        // do another iteration so that the byte-comparission succeeds
        image = try XCTUnwrap(.init(data: data))
        return try XCTUnwrap(image.pngData())
    }
}
