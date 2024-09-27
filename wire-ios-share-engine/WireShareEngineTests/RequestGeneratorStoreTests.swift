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

import Foundation
import WireRequestStrategy
import WireTesting
@testable import WireShareEngine

final class RequestGeneratorStoreTests: ZMTBaseTest {
    final class MockStrategy: NSObject, ZMRequestGeneratorSource, ZMContextChangeTrackerSource {
        public var requestGenerators: [ZMRequestGenerator] = []
        public var contextChangeTrackers: [ZMContextChangeTracker] = []
    }

    typealias RequestBlock = () -> ZMTransportRequest?

    final class DummyGenerator: NSObject, ZMRequestGenerator {
        let requestBlock: RequestBlock

        init(requestBlock: @escaping RequestBlock) {
            self.requestBlock = requestBlock
        }

        func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
            requestBlock()
        }
    }

    final class MockRequestStrategy: NSObject, RequestStrategy {
        let request: ZMTransportRequest

        init(request: ZMTransportRequest) {
            self.request = request
        }

        public func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
            request
        }
    }

    var mockStrategy: MockStrategy!
    var sut: RequestGeneratorStore! = nil

    override func setUp() {
        super.setUp()
        BackendInfo.apiVersion = .v0
        mockStrategy = MockStrategy()
    }

    override func tearDown() {
        mockStrategy = nil
        sut.tearDown()
        sut = nil
        super.tearDown()
    }

    func testThatItDoesNOTReturnARequestIfNoAPIVersionIsSelected() {
        // Given
        mockStrategy.requestGenerators.append(DummyGenerator(requestBlock: {
            ZMTransportRequest(path: "some path", method: .get, payload: nil, apiVersion: APIVersion.v0.rawValue)
        }))

        sut = RequestGeneratorStore(strategies: [mockStrategy])
        XCTAssertNotNil(sut.nextRequest())

        // When
        BackendInfo.apiVersion = nil

        // Then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNOTReturnARequestIfNoGeneratorsGiven() {
        sut = RequestGeneratorStore(strategies: [])
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItCallsTheGivenGenerator() {
        let expectation = customExpectation(description: "calledGenerator")
        let generator = DummyGenerator(requestBlock: {
            expectation.fulfill()
            return nil
        })

        mockStrategy.requestGenerators.append(generator)

        sut = RequestGeneratorStore(strategies: [mockStrategy])

        XCTAssertNil(sut.nextRequest())
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItReturnAProperRequest() {
        let sourceRequest = ZMTransportRequest(
            path: "some path",
            method: .get,
            payload: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        let generator = DummyGenerator(requestBlock: {
            sourceRequest
        })

        mockStrategy.requestGenerators.append(generator)

        sut = RequestGeneratorStore(strategies: [mockStrategy])

        let request = sut.nextRequest()
        XCTAssertNotNil(request)
        XCTAssertEqual(request, sourceRequest)
    }

    func testThatItReturnARequestWhenARequestGeneratorIsAddedDirectly() {
        // Given
        let sourceRequest = ZMTransportRequest(
            path: "/path",
            method: .get,
            payload: nil,
            apiVersion: APIVersion.v0.rawValue
        )
        let strategy = MockRequestStrategy(request: sourceRequest)
        sut = RequestGeneratorStore(strategies: [strategy])

        // When
        let request = sut.nextRequest()

        // Then
        XCTAssertNotNil(request)
        XCTAssertEqual(request, sourceRequest)
    }

    func testThatItReturnAProperRequestAndNoRequestAfter() {
        let sourceRequest = ZMTransportRequest(
            path: "some path",
            method: .get,
            payload: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        var requestCalled = false

        let generator = DummyGenerator(requestBlock: {
            if !requestCalled {
                requestCalled = true
                return sourceRequest
            }

            return nil
        })

        mockStrategy.requestGenerators.append(generator)

        sut = RequestGeneratorStore(strategies: [mockStrategy])

        let request = sut.nextRequest()
        XCTAssertNotNil(request)
        XCTAssertEqual(request, sourceRequest)

        let secondRequest = sut.nextRequest()
        XCTAssertNil(secondRequest)
    }

    func testThatItReturnsRequestFromMultipleGenerators() {
        let sourceRequest = ZMTransportRequest(
            path: "some path",
            method: .get,
            payload: nil,
            apiVersion: APIVersion.v0.rawValue
        )
        let sourceRequest2 = ZMTransportRequest(
            path: "some path 2",
            method: .post,
            payload: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        var requestCalled = false

        let generator = DummyGenerator(requestBlock: {
            if !requestCalled {
                requestCalled = true
                return sourceRequest
            }
            return nil
        })

        let secondGenerator = DummyGenerator(requestBlock: {
            sourceRequest2
        })

        mockStrategy.requestGenerators.append(generator)
        mockStrategy.requestGenerators.append(secondGenerator)

        sut = RequestGeneratorStore(strategies: [mockStrategy])

        let request = sut.nextRequest()
        XCTAssertNotNil(request)
        XCTAssertEqual(request, sourceRequest)

        let secondRequest = sut.nextRequest()
        XCTAssertNotNil(sourceRequest)
        XCTAssertEqual(sourceRequest2, secondRequest)
    }
}
