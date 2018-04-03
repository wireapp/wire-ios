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
import XCTest

@testable import WireRequestStrategy


protocol TestableAbstractRequestStrategy : class {
    
    var mutableConfiguration : ZMStrategyConfigurationOption { get set }
    
}


class TestRequestStrategyObjc : ZMAbstractRequestStrategy, TestableAbstractRequestStrategy {
    
    internal var mutableConfiguration: ZMStrategyConfigurationOption = []

    override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return ZMTransportRequest(getFromPath: "dummy/request")
    }
    
    override var configuration: ZMStrategyConfigurationOption {
        get {
            return mutableConfiguration
        }
    }
    
}


class TestRequestStrategy : AbstractRequestStrategy, TestableAbstractRequestStrategy {
    
    internal var mutableConfiguration: ZMStrategyConfigurationOption = []
    
    override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return ZMTransportRequest(getFromPath: "dummy/request")
    }
    
    override var configuration: ZMStrategyConfigurationOption {
        get {
            return mutableConfiguration
        }
        set {
            mutableConfiguration = configuration
        }
    }
    
}


class AbstractRequestStrategyTests : MessagingTestBase {
    
    let mockApplicationStatus = MockApplicationStatus()
    
    func checkAllPermutations(on sut : RequestStrategy & TestableAbstractRequestStrategy) {
        
        assertPass(withConfiguration: [.allowsRequestsDuringEventProcessing], operationState: .foreground, synchronizationState: .eventProcessing, sut: sut)
        assertPass(withConfiguration: [.allowsRequestsDuringSync], operationState: .foreground, synchronizationState: .synchronizing, sut: sut)
        assertPass(withConfiguration: [.allowsRequestsWhileUnauthenticated], operationState: .foreground, synchronizationState: .unauthenticated, sut: sut)
        
        assertFail(withConfiguration: [.allowsRequestsDuringEventProcessing], operationState: .foreground, synchronizationState: .synchronizing, sut: sut)
        assertFail(withConfiguration: [.allowsRequestsDuringEventProcessing], operationState: .foreground, synchronizationState: .unauthenticated, sut: sut)
        
        assertFail(withConfiguration: [.allowsRequestsDuringSync], operationState: .foreground, synchronizationState: .eventProcessing, sut: sut)
        assertFail(withConfiguration: [.allowsRequestsDuringSync], operationState: .foreground, synchronizationState: .unauthenticated, sut: sut)
        
        assertFail(withConfiguration: [.allowsRequestsWhileUnauthenticated], operationState: .foreground, synchronizationState: .eventProcessing, sut: sut)
        assertFail(withConfiguration: [.allowsRequestsWhileUnauthenticated], operationState: .foreground, synchronizationState: .synchronizing, sut: sut)
        
        assertPass(withConfiguration: [.allowsRequestsDuringEventProcessing, .allowsRequestsWhileInBackground], operationState: .background, synchronizationState: .eventProcessing, sut: sut)
        assertPass(withConfiguration: [.allowsRequestsDuringSync, .allowsRequestsWhileInBackground], operationState: .background, synchronizationState: .synchronizing, sut: sut)
        assertPass(withConfiguration: [.allowsRequestsWhileUnauthenticated, .allowsRequestsWhileInBackground], operationState: .background, synchronizationState: .unauthenticated, sut: sut)
    }
    
    func assertPass(withConfiguration configuration: ZMStrategyConfigurationOption, operationState: OperationState, synchronizationState: SynchronizationState, sut: RequestStrategy & TestableAbstractRequestStrategy) {
        
        // given
        sut.mutableConfiguration = configuration
        mockApplicationStatus.mockOperationState = operationState
        mockApplicationStatus.mockSynchronizationState = synchronizationState
        
        // then
        XCTAssertNotNil(sut.nextRequest(), "expected \(configuration) to pass")
    }
    
    func assertFail(withConfiguration configuration: ZMStrategyConfigurationOption, operationState: OperationState, synchronizationState: SynchronizationState, sut: RequestStrategy & TestableAbstractRequestStrategy) {
        
        // given
        sut.mutableConfiguration = configuration
        mockApplicationStatus.mockOperationState = operationState
        mockApplicationStatus.mockSynchronizationState = synchronizationState
        
        // then
        XCTAssertNil(sut.nextRequest(), "expected \(configuration) to fail")
    }
    
    func testAbstractRequestStrategy() {
        checkAllPermutations(on: TestRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus))
    }
    
    func testAbstractRequestStrategyObjC() {
        checkAllPermutations(on: TestRequestStrategyObjc(managedObjectContext: syncMOC, applicationStatus: mockApplicationStatus))
    }
    
}
