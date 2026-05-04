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

import WireDataModelSupport
import WireTesting
import XCTest

@testable import WireDataModel

final class GetTeamAccountImageSourceUseCaseTests: XCTestCase {

    private var coreDataStack: CoreDataStack!
    private var sut: GetTeamAccountImageSourceUseCase!

    @MainActor
    override func setUp() async throws {
        coreDataStack = try await CoreDataStackHelper().createStack()
        sut = .init()
    }

    override func tearDown() {
        sut = nil
        coreDataStack = nil
    }

    func testTeamImage() async throws {
        // Given
        let teamImageData = try imageData(from: .brown)
        let user = await coreDataStack.viewContext.perform { [self] in

            let fileAssetCache = FileAssetCache(location: FileManager.default.randomCacheURL!)
            coreDataStack.viewContext.zm_fileAssetCache = fileAssetCache

            let user = ZMUser.selfUser(in: coreDataStack.viewContext)
            let team = Team.mockTeam(context: coreDataStack.viewContext)
            team.pictureAssetId = "123-1234-abc"
            team.imageData = teamImageData
            let membership = TeamMembership.insertNewObject(in: coreDataStack.viewContext)
            membership.team = team
            membership.user = user
            return user
        }

        // When
        let teamImageSource = try await sut.invoke(
            user: user,
            userContext: user.managedObjectContext,
            account: coreDataStack.account
        )

        // Then
        guard case let .image(teamImage) = teamImageSource, teamImage.pngData() == teamImageData else {
            return XCTFail("Expected team image to match actual image")
        }
    }

    func testTeamName() async throws {
        // Given
        let user = await coreDataStack.viewContext.perform { [self] in
            let user = ZMUser.selfUser(in: coreDataStack.viewContext)
            let team = Team.mockTeam(context: coreDataStack.viewContext)
            team.name = "\tWire \n"
            let membership = TeamMembership.insertNewObject(in: coreDataStack.viewContext)
            membership.team = team
            membership.user = user
            return user
        }

        // When
        let teamImageSource = try await sut.invoke(
            user: user,
            userContext: user.managedObjectContext,
            account: coreDataStack.account
        )

        // Then
        XCTAssertEqual(teamImageSource, .text("W"))
    }

    func testAccountImage() async throws {
        // Given
        let teamImageData = try imageData(from: .brown)
        coreDataStack.account.teamImageData = teamImageData
        let user = await coreDataStack.viewContext.perform { [self] in
            ZMUser.selfUser(in: coreDataStack.viewContext)
        }

        // When
        let teamImageSource = try await sut.invoke(
            user: user,
            userContext: nil,
            account: coreDataStack.account
        )

        // Then
        guard case let .image(teamImage) = teamImageSource, teamImage.pngData() == teamImageData else {
            return XCTFail("Expected team image to match actual image")
        }
    }

    func testAccountName() async throws {
        // Given
        coreDataStack.account.teamName = "\nWire \t"
        let user = await coreDataStack.viewContext.perform { [self] in
            ZMUser.selfUser(in: coreDataStack.viewContext)
        }

        // When
        let teamImageSource = try await sut.invoke(
            user: user,
            userContext: user.managedObjectContext,
            account: coreDataStack.account
        )

        // Then
        XCTAssertEqual(teamImageSource, .text("W"))
    }

    func testNoSource() async throws {
        // Given
        let user = await coreDataStack.viewContext.perform { [self] in
            ZMUser.selfUser(in: coreDataStack.viewContext)
        }

        do {
            // When
            let teamImageSource = try await sut.invoke(
                user: user,
                userContext: user.managedObjectContext,
                account: coreDataStack.account
            )
            XCTFail("Unexpected success")
        } catch GetTeamAccountImageSourceUseCase.Error.invalidImageSource {
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
