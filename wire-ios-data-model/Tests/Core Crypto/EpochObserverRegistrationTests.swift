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

import WireCoreCrypto
import XCTest

@testable import WireDataModel

final class EpochObserverRegistrationTests: XCTestCase {

    private var sut: EpochObserverRegistration!
    private var registrar: RegistrarSpy!
    private var observer: ObserverStub!

    override func setUp() {
        super.setUp()
        sut = EpochObserverRegistration()
        registrar = RegistrarSpy()
        observer = ObserverStub()
    }

    override func tearDown() {
        sut = nil
        registrar = nil
        observer = nil
        super.tearDown()
    }

    func testItDoesNotRegister_WhenMLSIsNotInitialised() async throws {
        // Given
        sut.setObserver(observer)

        // When
        try await sut.registerIfNecessary(with: registrar)

        // Then
        XCTAssertEqual(registrar.registeredObservers.count, 0)
    }

    func testItDoesNotRegister_WhenThereIsNoObserver() async throws {
        // Given
        sut.markMLSInitialised()

        // When
        try await sut.registerIfNecessary(with: registrar)

        // Then
        XCTAssertEqual(registrar.registeredObservers.count, 0)
    }

    func testItRegisters_WhenObserverIsSetBeforeMLSIsInitialised() async throws {
        // Given
        sut.setObserver(observer)
        try await sut.registerIfNecessary(with: registrar)
        XCTAssertEqual(registrar.registeredObservers.count, 0)

        // When
        sut.markMLSInitialised()
        try await sut.registerIfNecessary(with: registrar)

        // Then
        XCTAssertEqual(registrar.registeredObservers.count, 1)
        XCTAssertTrue(registrar.registeredObservers.first === observer)
    }

    func testItRegisters_WhenMLSIsInitialisedBeforeObserverIsSet() async throws {
        // Given
        sut.markMLSInitialised()
        try await sut.registerIfNecessary(with: registrar)
        XCTAssertEqual(registrar.registeredObservers.count, 0)

        // When
        sut.setObserver(observer)
        try await sut.registerIfNecessary(with: registrar)

        // Then
        XCTAssertEqual(registrar.registeredObservers.count, 1)
        XCTAssertTrue(registrar.registeredObservers.first === observer)
    }

    func testItRegistersOnlyOnce() async throws {
        // Given
        sut.setObserver(observer)
        sut.markMLSInitialised()

        // When
        try await sut.registerIfNecessary(with: registrar)
        try await sut.registerIfNecessary(with: registrar)
        try await sut.registerIfNecessary(with: registrar)

        // Then
        XCTAssertEqual(registrar.registeredObservers.count, 1)
    }

    func testItRegistersOnlyOnce_WhenCalledConcurrently() async throws {
        // Given
        registrar.delay = .milliseconds(50)
        sut.setObserver(observer)
        sut.markMLSInitialised()

        // When
        async let first: Void = sut.registerIfNecessary(with: registrar)
        async let second: Void = sut.registerIfNecessary(with: registrar)
        _ = try await (first, second)

        // Then
        XCTAssertEqual(registrar.registeredObservers.count, 1)
    }

    func testItRetries_WhenRegistrationFailed() async throws {
        // Given
        sut.setObserver(observer)
        sut.markMLSInitialised()
        registrar.error = TestError.registrationFailed

        // When
        do {
            try await sut.registerIfNecessary(with: registrar)
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? TestError, .registrationFailed)
        }

        registrar.error = nil
        try await sut.registerIfNecessary(with: registrar)

        // Then
        XCTAssertEqual(registrar.registeredObservers.count, 1)
    }

}

// MARK: - Helpers

private enum TestError: Error {
    case registrationFailed
}

private final class ObserverStub: EpochObserver {

    func epochChanged(conversationId: ConversationId, epoch: UInt64) async throws {}

}

private final class RegistrarSpy: EpochObserverRegistrar, @unchecked Sendable {

    var registeredObservers: [any EpochObserver] = []
    var error: Error?
    var delay: Duration?

    func registerEpochObserver(epochObserver: any EpochObserver) async throws {
        if let delay {
            try await Task.sleep(for: delay)
        }
        if let error {
            throw error
        }
        registeredObservers.append(epochObserver)
    }

}
