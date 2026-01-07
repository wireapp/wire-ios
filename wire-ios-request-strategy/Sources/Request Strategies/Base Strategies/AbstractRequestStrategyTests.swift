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

import Foundation
import XCTest

@testable import WireRequestStrategy

protocol TestableAbstractRequestStrategy: AnyObject {

    var mutableConfiguration: ZMStrategyConfigurationOption { get set }

}

class TestRequestStrategyObjc: ZMAbstractRequestStrategy, TestableAbstractRequestStrategy {

    var mutableConfiguration: ZMStrategyConfigurationOption = []

    override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        ZMTransportRequest(getFromPath: "dummy/request", apiVersion: APIVersion.v0.rawValue)
    }

    override var configuration: ZMStrategyConfigurationOption {
        mutableConfiguration
    }

}

class TestRequestStrategy: AbstractRequestStrategy, TestableAbstractRequestStrategy {

    var mutableConfiguration: ZMStrategyConfigurationOption = []

    override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        ZMTransportRequest(getFromPath: "dummy/request", apiVersion: APIVersion.v0.rawValue)
    }

    override var configuration: ZMStrategyConfigurationOption {
        get { mutableConfiguration }
        set { mutableConfiguration = newValue }
    }

}

class AbstractRequestStrategyTests: MessagingTestBase {

    let mockApplicationStatus = MockApplicationStatus()

    func checkAllPermutations(on sut: RequestStrategy & TestableAbstractRequestStrategy) {
        checkRequirementsDependingOn_SynchronizationState(on: sut)
        checkRequirementsDependingOn_OperationState(on: sut)
    }

    func checkRequirementsDependingOn_SynchronizationState(on sut: RequestStrategy & TestableAbstractRequestStrategy) {

        // online

        assertPass(
            withConfiguration: [.allowsRequestsWhileOnline],
            operationState: .foreground,
            synchronizationState: .online,
            sut: sut
        )

        assertFail(
            withConfiguration: [.allowsRequestsWhileOnline],
            operationState: .foreground,
            synchronizationState: .unauthenticated,
            sut: sut
        )

        assertFail(
            withConfiguration: [.allowsRequestsDuringSlowSync],
            operationState: .foreground,
            synchronizationState: .online,
            sut: sut
        )

        assertFail(
            withConfiguration: [.allowsRequestsDuringSlowSync],
            operationState: .foreground,
            synchronizationState: .unauthenticated,
            sut: sut
        )

        assertFail(
            withConfiguration: [.allowsRequestsWhileWaitingForWebsocket],
            operationState: .foreground,
            synchronizationState: .online,
            sut: sut
        )

        assertFail(
            withConfiguration: [.allowsRequestsWhileWaitingForWebsocket],
            operationState: .foreground,
            synchronizationState: .unauthenticated,
            sut: sut
        )

        assertFail(
            withConfiguration: [.allowsRequestsDuringQuickSync],
            operationState: .foreground,
            synchronizationState: .online,
            sut: sut
        )

        assertFail(
            withConfiguration: [.allowsRequestsDuringQuickSync],
            operationState: .foreground,
            synchronizationState: .unauthenticated,
            sut: sut
        )

        // unauthenticated

        assertPass(
            withConfiguration: [.allowsRequestsWhileUnauthenticated],
            operationState: .foreground,
            synchronizationState: .unauthenticated,
            sut: sut
        )

        assertFail(
            withConfiguration: [.allowsRequestsWhileUnauthenticated],
            operationState: .foreground,
            synchronizationState: .online,
            sut: sut
        )
    }

    func checkRequirementsDependingOn_OperationState(on sut: RequestStrategy & TestableAbstractRequestStrategy) {
        assertPass(
            withConfiguration: [.allowsRequestsWhileOnline, .allowsRequestsWhileInBackground],
            operationState: .background,
            synchronizationState: .online,
            sut: sut
        )

        assertPass(
            withConfiguration: [.allowsRequestsWhileUnauthenticated, .allowsRequestsWhileInBackground],
            operationState: .background,
            synchronizationState: .unauthenticated,
            sut: sut
        )
    }

    func assertPass(
        withConfiguration configuration: ZMStrategyConfigurationOption,
        operationState: OperationState,
        synchronizationState: SynchronizationState,
        sut: RequestStrategy & TestableAbstractRequestStrategy,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {

        // given
        sut.mutableConfiguration = configuration
        mockApplicationStatus.mockOperationState = operationState
        mockApplicationStatus.mockSynchronizationState = synchronizationState

        // then
        XCTAssertNotNil(sut.nextRequest(for: .v0), "expected \(configuration) to pass", file: file, line: line)
    }

    func assertFail(
        withConfiguration configuration: ZMStrategyConfigurationOption,
        operationState: OperationState,
        synchronizationState: SynchronizationState,
        sut: RequestStrategy & TestableAbstractRequestStrategy,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {

        // given
        sut.mutableConfiguration = configuration
        mockApplicationStatus.mockOperationState = operationState
        mockApplicationStatus.mockSynchronizationState = synchronizationState

        // then
        XCTAssertNil(sut.nextRequest(for: .v0), "expected \(configuration) to fail", file: file, line: line)
    }

    func testAbstractRequestStrategy() {
        checkAllPermutations(on: TestRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus
        ))
    }

    func testAbstractRequestStrategyObjC() {
        checkAllPermutations(on: TestRequestStrategyObjc(
            managedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus
        ))
    }

}
