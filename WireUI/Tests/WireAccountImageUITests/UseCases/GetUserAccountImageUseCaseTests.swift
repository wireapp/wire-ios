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

final class GetUserAccountImageUseCaseTests: XCTestCase {

    private var mockInitialsProvider: MockInitialsProvider!
    @MainActor
    private var mockAccount: MockAccount!
    private var sut: GetUserAccountImageUseCase<MockInitialsProvider>!

    @MainActor
    override func setUp() async throws {
        mockInitialsProvider = .init()
        sut = .init(initalsProvider: mockInitialsProvider)
        mockAccount = .init()
    }

    @MainActor
    override func tearDown() async throws {
        mockAccount = nil
        sut = nil
    }

    @MainActor
    func testUserImageDataMatches() async throws {
        // Given
        let expectedData = try imageData(from: .green)
        mockAccount.imageData = expectedData

        // When
        let actualData = try await sut.invoke(account: mockAccount)?.pngData()

        // Then
        XCTAssertEqual(expectedData, actualData)
    }

//    @MainActor
//    func testInitalsImageDataMatches() async throws {
//        // Given
//        let expectedData = try imageData(from: .green)
//        mockInitialsProvider.initialsResult = "W"
//        mockAccountImageGenerator.createImageInitials_MockValue = try XCTUnwrap(.init(data: expectedData))
//
//        // When
//        let actualData = try await sut.invoke(account: mockAccount)?.pngData()
//
//        // Then
//        XCTAssertEqual(expectedData, actualData)
//    }

    @MainActor
    func testErrorIsThrown() async throws {
        // When
        do {
            _ = try await sut.invoke(account: mockAccount)
            XCTFail("Unexpected success")
        } catch GetUserAccountImageUseCase.Error.invalidImageSource {
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
