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

import WireTestingPackage
import XCTest

@testable import WireSettingsUI
@testable import WireSettingsUISupport

@MainActor
final class ExportBackupViewModelTests: XCTestCase {

    private var mockCreateBackupUseCase: MockCreateBackupUseCaseProtocol!
    private var mockCleanUpBackupsUseCaseProtocol: MockCleanUpBackupsUseCaseProtocol!
    private var sut: ExportBackupViewModel!

    override func setUp() async throws {
        mockCreateBackupUseCase = .init()
        mockCleanUpBackupsUseCaseProtocol = .init()
        sut = .init(
            createBackupUseCase: mockCreateBackupUseCase,
            cleanUpBackupsUseCase: mockCleanUpBackupsUseCaseProtocol,
            logger: MockWireSettingsUILogger()
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockCleanUpBackupsUseCaseProtocol = nil
        mockCreateBackupUseCase = nil
    }

    func testInitialValues() {
        XCTAssertFalse(sut.isCreatingBackupProgressPresented)
        XCTAssertFalse(sut.isSetBackupPasswordPresented)
        XCTAssertFalse(sut.isErrorAlertPresented)
    }

    func testProgressIsReported() {
        // Given
        var continuation: AsyncThrowingStream<CreateBackupProgress, any Error>.Continuation!
        mockCreateBackupUseCase.invokePassword_MockValue = .init { continuation = $0 }

        // When / Then
        sut.start()
        XCTAssertEqual(sut.backupProgress, .ongoing(0))

        continuation.yield(.progress(0.5))
        wait(forConditionToBeTrue: self.sut.backupProgress == .ongoing(0.5), timeout: 1)

        continuation.yield(.done(URL(fileURLWithPath: "/")))
        wait(forConditionToBeTrue: self.sut.backupProgress == .ongoing(1), timeout: 1)

        continuation.finish()

//        mockCreateBackupUseCase.invokePassword_MockValue = .init { [self] continuation in
//            defer { continuation.finish() }
//
//            // When
//            sut.start()
//            continuation.yield(.progress(0.5))
//
//            // Then
//            XCTAssertEqual(sut.backupProgress, .ongoing(0.5))
//        }

//        let i = AsyncThrowingStream<Int, any Error> { continuation in
//            //
//        }.makeAsyncIterator()
//
//        i.next()
    }

    /*
    func testInvalidPassword() async throws {
        let screenBounds = UIScreen.main.bounds
        let viewModel = SetBackupPasswordViewModel(
            passwordValidator: backupPasswordValidator,
            cancelAction: {},
            setPasswordAction: { _ in }
        )
        viewModel.password = "invalid"
        let sut = SetBackupPasswordView(viewModel: viewModel)
            .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: sut, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark")
    }

    func testNonEmptyPassword() async throws {
        let screenBounds = UIScreen.main.bounds
        let viewModel = SetBackupPasswordViewModel(
            passwordValidator: backupPasswordValidator,
            cancelAction: {},
            setPasswordAction: { _ in }
        )
        viewModel.password = "G00dPassword"
        let sut = SetBackupPasswordView(viewModel: viewModel)
            .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: sut, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark")
    }

    func testColorSchemeVariants() async throws {
        let screenBounds = UIScreen.main.bounds
        let viewModel = SetBackupPasswordViewModel(
            passwordValidator: backupPasswordValidator,
            cancelAction: {},
            setPasswordAction: { _ in }
        )
        let sut = SetBackupPasswordView(viewModel: viewModel)
            .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark")
    }

    func testDynamicTypeVariants() {
        let screenBounds = UIScreen.main.bounds
        let viewModel = SetBackupPasswordViewModel(
            passwordValidator: backupPasswordValidator,
            cancelAction: {},
            setPasswordAction: { _ in }
        )
        let sut = SetBackupPasswordView(viewModel: viewModel)
            .frame(width: screenBounds.width, height: screenBounds.height)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: sut.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }
     */

}
