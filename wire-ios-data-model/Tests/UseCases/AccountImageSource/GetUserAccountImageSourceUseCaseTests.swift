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

@testable import WireDataModel

final class GetUserAccountImageSourceUseCaseTests: XCTestCase {

//    private var mockAccountImageGenerator: MockAccountImageGenerator!
//    private var mockInitialsProvider: MockInitialsProvider!
//    private var mockAccount: MockAccount!
    private var coreDataStack: CoreDataStack!
    private var sut: GetUserAccountImageSourceUseCase!

    @MainActor
    override func setUp() async throws {
        coreDataStack = try await CoreDataStackHelper().createStack()
        sut = .init()
    }

    override func tearDown() {
        sut = nil
    }

    func testAccountImage() async throws {
        // Given
        let accountImageData = try imageData(from: .brown)
        coreDataStack.account.imageData = accountImageData
        let user = await coreDataStack.viewContext.perform { [self] in
            ZMUser.selfUser(in: coreDataStack.viewContext)
        }

        // When
        let accountImageSource = try await sut.invoke(
            user: user,
            userContext: user.managedObjectContext,
            account: coreDataStack.account
        )

        // Then
        guard case .image(let accountImage) = accountImageSource, accountImage.pngData() == accountImageData else {
            return XCTFail("Expected account image to match actual image")
        }
    }

    func testUserInitials() async throws {
        // Given
        let user = await coreDataStack.viewContext.perform { [self] in
            let user = ZMUser.selfUser(in: coreDataStack.viewContext)
            user.name = " Wire\tUser \t\n"
            return user
        }

        // When
        let accountImageSource = try await sut.invoke(
            user: user,
            userContext: user.managedObjectContext,
            account: coreDataStack.account
        )

        // Then
        XCTAssertEqual(accountImageSource, .text("WU"))
    }

    func testAccountName() async throws {
        // Given
        coreDataStack.account.userName = "Wire\tUser \t\n"
        let user = await coreDataStack.viewContext.perform { [self] in
            ZMUser.selfUser(in: coreDataStack.viewContext)
        }

        // When
        let accountImageSource = try await sut.invoke(
            user: user,
            userContext: nil,
            account: coreDataStack.account
        )

        // Then
        XCTAssertEqual(accountImageSource, .text("WU"))
    }

    func testNoSource() async throws {
        // Given
        let user = await coreDataStack.viewContext.perform { [self] in
            ZMUser.selfUser(in: coreDataStack.viewContext)
        }

        do {
            // When
            let accountImageSource = try await sut.invoke(
                user: user,
                userContext: user.managedObjectContext,
                account: coreDataStack.account
            )
            XCTFail("Unexpected success")
        } catch GetUserAccountImageSourceUseCase.Error.invalidImageSource {
            // Then
        }
    }

    // MARK: - Helper

    private func imageData(from solidColor: UIColor) throws -> Data {
        var image = UIImage.from(solidColor: solidColor)
        let data = try XCTUnwrap(image.pngData())
        // do another iteration so that the byte-comparission succeeds
        image = try XCTUnwrap(.init(data: data))
        return try XCTUnwrap(image.pngData())
    }
}
