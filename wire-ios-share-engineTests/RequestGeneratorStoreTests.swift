//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import ZMTesting
import WireRequestStrategy
@testable import WireShareEngine

class RequestGeneratorStoreTests : ZMTBaseTest {
    
    class MockStrategy : NSObject, ZMRequestGeneratorSource, ZMContextChangeTrackerSource {
        public var requestGenerators: [ZMRequestGenerator] = []
        public var contextChangeTrackers: [ZMContextChangeTracker] = []
    }
    
    
    class DummyGenerator : NSObject, ZMRequestGenerator {
        
        typealias RequestBlock = () -> ZMTransportRequest?
        
        let requestBlock : RequestBlock
        
        init(requestBlock: @escaping RequestBlock ) {
            self.requestBlock = requestBlock
        }
        
        internal func nextRequest() -> ZMTransportRequest? {
            return requestBlock()
        }
    }
    
    
    var mockStrategy = MockStrategy()
    var sut : RequestGeneratorStore! = nil
    
    func testThatItDoesNOTReturnARequestIfNoGeneratorsGiven() {
        sut = RequestGeneratorStore(strategies:[])
        XCTAssertNil(sut.requestGenerator())
    }
    
    func testThatItCallsTheGivenGenerator() {
        
        let expectation = self.expectation(description: "calledGenerator")
        let generator = DummyGenerator(requestBlock: {
            expectation.fulfill()
            return nil
        })
        
        mockStrategy.requestGenerators.append(generator)
        
        sut = RequestGeneratorStore(strategies: [mockStrategy])
        
        XCTAssertNil(sut.requestGenerator())
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }
    
    func testThatItReturnAProperRequest() {
        
        let sourceRequest = ZMTransportRequest(path: "some path", method: .methodGET, payload: nil)
        
        let generator = DummyGenerator(requestBlock: {
            return sourceRequest
        })
        
        mockStrategy.requestGenerators.append(generator)
        
        sut = RequestGeneratorStore(strategies: [mockStrategy])
        
        let request = sut.requestGenerator()
        XCTAssertNotNil(request)
        XCTAssertEqual(request, sourceRequest)
    }
    
    func testThatItReturnAProperRequestAndNoRequestAfter() {
        
        let sourceRequest = ZMTransportRequest(path: "some path", method: .methodGET, payload: nil)
        
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
        
        let request = sut.requestGenerator()
        XCTAssertNotNil(request)
        XCTAssertEqual(request, sourceRequest)
        
        
        let secondRequest = sut.requestGenerator()
        XCTAssertNil(secondRequest)
    }
    
    func testThatItReturnsRequestFromMultipleGenerators() {
        
        let sourceRequest = ZMTransportRequest(path: "some path", method: .methodGET, payload: nil)
        let sourceRequest2 = ZMTransportRequest(path: "some path 2", method: .methodPOST, payload: nil)
        
        var requestCalled = false
        
        let generator = DummyGenerator(requestBlock: {
            if !requestCalled {
                requestCalled = true
                return sourceRequest
            }
            return nil
        })
        
        let secondGenerator = DummyGenerator(requestBlock: {
            return sourceRequest2
        })
        
        mockStrategy.requestGenerators.append(generator)
        mockStrategy.requestGenerators.append(secondGenerator)
        
        sut = RequestGeneratorStore(strategies: [mockStrategy])
        
        let request = sut.requestGenerator()
        XCTAssertNotNil(request)
        XCTAssertEqual(request, sourceRequest)
        
        let secondRequest = sut.requestGenerator()
        XCTAssertNotNil(sourceRequest)
        XCTAssertEqual(sourceRequest2, secondRequest)
    }
    
}
