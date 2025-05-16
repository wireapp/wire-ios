//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireFoundationSupport
import WireSettingsUI
import WireSyncEngine
import XCTest

@testable import Wire

final class CompositeImportBackupUseCaseTests: XCTestCase {

    private var useCaseMock: ImportBackupUseCaseProtocolMock!
    private var legacyUseCaseMock: ImportBackupUseCaseProtocolMock!
    private var sut: CompositeImportBackupUseCase!

    override func setUp() {
        useCaseMock = ImportBackupUseCaseProtocolMock()
        legacyUseCaseMock = ImportBackupUseCaseProtocolMock()
        sut = CompositeImportBackupUseCase(
            importBackupUseCase: useCaseMock,
            legacyImportBackupUseCase: useCaseMock
        )
    }

    override func tearDown() {
        sut = nil
        legacyUseCaseMock = nil
        useCaseMock = nil
    }

    func testUseCaseIsInvoked() async throws {
        // Given
        let fileExtension = "wbu"
        let expectation = XCTestExpectation()
        useCaseMock.invokeUrlURLPasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorReturnValue =
            AsyncThrowingStream { continuation in
                expectation.fulfill()
                continuation.finish()
            }

        // When
        let filePath = "/path/to/file.\(fileExtension)"
        for try await _ in sut.invoke(url: URL(fileURLWithPath: filePath), password: "") {}

        // Then
        await fulfillment(of: [expectation])
    }

    func testLegacyUseCaseIsInvoked() async throws {
        // Given
        let fileExtensions = ["ios_wbu", "ios-wbu"]

        for fileExtension in fileExtensions {
            let expectation = XCTestExpectation()
            useCaseMock.invokeUrlURLPasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorReturnValue =
                AsyncThrowingStream { continuation in
                    expectation.fulfill()
                    continuation.finish()
                }

            // When
            let filePath = "/path/to/file.\(fileExtension)"
            for try await _ in sut.invoke(url: URL(fileURLWithPath: filePath), password: "") {}

            // Then
            await fulfillment(of: [expectation])
        }
    }

    func testUnknownFileExtensionsThrow() async throws {
        // Given
        let fileExtension = "zip"

        do {
            // When
            let filePath = "/path/to/file.\(fileExtension)"
            for try await _ in sut.invoke(url: URL(fileURLWithPath: filePath), password: "") {}
            XCTFail("Unexpected success")
        } catch ImportBackupError.invalidFileExtension {
            // Then
        }
    }

}
