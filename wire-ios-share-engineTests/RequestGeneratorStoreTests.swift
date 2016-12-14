//
//  RequestGeneratorStoreTests.swift
//  wire-ios-share-engine
//
//  Created by Florian Morel on 12/14/16.
//  Copyright © 2016 com.wire. All rights reserved.
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
    
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
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
