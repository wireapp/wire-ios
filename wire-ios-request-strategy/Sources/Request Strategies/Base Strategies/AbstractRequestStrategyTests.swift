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

protocol TestableAbstractRequestStrategy: AnyObject {

    var mutableConfiguration: ZMStrategyConfigurationOption { get set }

}

// TODO: check what's the difference here between Objc and normal
class TestRequestStrategyObjc: ZMAbstractRequestStrategy, TestableAbstractRequestStrategy {

    internal var mutableConfiguration: ZMStrategyConfigurationOption = []

    override func nextRequestIfAllowed(for apiVersion: APIVersion) async -> ZMTransportRequest? {
        return ZMTransportRequest(getFromPath: "dummy/request", apiVersion: APIVersion.v0.rawValue)
    }

    override var configuration: ZMStrategyConfigurationOption {
        return mutableConfiguration
    }

}

class TestRequestStrategy: AbstractRequestStrategy, TestableAbstractRequestStrategy {

    internal var mutableConfiguration: ZMStrategyConfigurationOption = []

    override func nextRequestIfAllowed(for apiVersion: APIVersion) async -> ZMTransportRequest? {
        return ZMTransportRequest(getFromPath: "dummy/request", apiVersion: APIVersion.v0.rawValue)
    }

    override var configuration: ZMStrategyConfigurationOption {
        get { return mutableConfiguration }
        set { mutableConfiguration = newValue }
    }

}

class AbstractRequestStrategyTests: MessagingTestBase {

    let mockApplicationStatus = MockApplicationStatus()

    func checkAllPermutations(on sut: RequestStrategy & TestableAbstractRequestStrategy) async {
        await checkRequirementsDependingOn_SynchronizationState(on: sut)
        await checkRequirementsDependingOn_OperationState(on: sut)
    }

    func checkRequirementsDependingOn_SynchronizationState(on sut: RequestStrategy & TestableAbstractRequestStrategy) async {

        // online

        await assertPass(withConfiguration: [.allowsRequestsWhileOnline],
                   operationState: .foreground,
                   synchronizationState: .online,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsWhileOnline],
                   operationState: .foreground,
                   synchronizationState: .slowSyncing,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsWhileOnline],
                   operationState: .foreground,
                   synchronizationState: .quickSyncing,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsWhileOnline],
                   operationState: .foreground,
                   synchronizationState: .unauthenticated,
                   sut: sut)

        // slow sync

        await assertPass(withConfiguration: [.allowsRequestsDuringSlowSync],
                   operationState: .foreground,
                   synchronizationState: .slowSyncing,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsDuringSlowSync],
                   operationState: .foreground,
                   synchronizationState: .online,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsDuringSlowSync],
                   operationState: .foreground,
                   synchronizationState: .unauthenticated,
                   sut: sut)

        // waiting for websocket

        await assertPass(withConfiguration: [.allowsRequestsWhileWaitingForWebsocket],
                   operationState: .foreground,
                   synchronizationState: .establishingWebsocket,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsWhileWaitingForWebsocket],
                   operationState: .foreground,
                   synchronizationState: .quickSyncing,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsWhileWaitingForWebsocket],
                   operationState: .foreground,
                   synchronizationState: .online,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsWhileWaitingForWebsocket],
                   operationState: .foreground,
                   synchronizationState: .unauthenticated,
                   sut: sut)

        // quick sync

        await assertPass(withConfiguration: [.allowsRequestsDuringQuickSync],
                   operationState: .foreground,
                   synchronizationState: .quickSyncing,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsDuringQuickSync],
                   operationState: .foreground,
                   synchronizationState: .establishingWebsocket,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsDuringQuickSync],
                   operationState: .foreground,
                   synchronizationState: .slowSyncing,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsDuringQuickSync],
                   operationState: .foreground,
                   synchronizationState: .online,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsDuringQuickSync],
                   operationState: .foreground,
                   synchronizationState: .unauthenticated,
                   sut: sut)

        // unauthenticated

        await assertPass(withConfiguration: [.allowsRequestsWhileUnauthenticated],
                   operationState: .foreground,
                   synchronizationState: .unauthenticated,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsWhileUnauthenticated],
                   operationState: .foreground,
                   synchronizationState: .online,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsWhileUnauthenticated],
                   operationState: .foreground,
                   synchronizationState: .slowSyncing,
                   sut: sut)

        await assertFail(withConfiguration: [.allowsRequestsWhileUnauthenticated],
                   operationState: .foreground,
                   synchronizationState: .quickSyncing,
                   sut: sut)
    }

    func checkRequirementsDependingOn_OperationState(on sut: RequestStrategy & TestableAbstractRequestStrategy) async {
        await assertPass(withConfiguration: [.allowsRequestsWhileOnline, .allowsRequestsWhileInBackground],
                   operationState: .background,
                   synchronizationState: .online,
                   sut: sut)

        await assertPass(withConfiguration: [.allowsRequestsDuringQuickSync, .allowsRequestsWhileInBackground],
                   operationState: .background,
                   synchronizationState: .quickSyncing,
                   sut: sut)

        await assertPass(withConfiguration: [.allowsRequestsWhileUnauthenticated, .allowsRequestsWhileInBackground],
                   operationState: .background,
                   synchronizationState: .unauthenticated,
                   sut: sut)
    }

    func assertPass(withConfiguration configuration: ZMStrategyConfigurationOption,
                    operationState: OperationState,
                    synchronizationState: SynchronizationState,
                    sut: RequestStrategy & TestableAbstractRequestStrategy,
                    file: StaticString = #file,
                    line: UInt = #line) async {

        // given
        sut.mutableConfiguration = configuration
        mockApplicationStatus.mockOperationState = operationState
        mockApplicationStatus.mockSynchronizationState = synchronizationState

        // then
        let result = await sut.nextRequest(for: .v0)
        XCTAssertNotNil(result, "expected \(configuration) to pass", file: file, line: line)
    }

    func assertFail(withConfiguration configuration: ZMStrategyConfigurationOption,
                    operationState: OperationState,
                    synchronizationState: SynchronizationState,
                    sut: RequestStrategy & TestableAbstractRequestStrategy,
                    file: StaticString = #file,
                    line: UInt = #line) async {

        // given
        sut.mutableConfiguration = configuration
        mockApplicationStatus.mockOperationState = operationState
        mockApplicationStatus.mockSynchronizationState = synchronizationState

        // then
        let result = await sut.nextRequest(for: .v0)
        XCTAssertNil(result, "expected \(configuration) to fail", file: file, line: line)
    }

    func testAbstractRequestStrategy() async {
        await checkAllPermutations(on: TestRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus))
    }

    func testAbstractRequestStrategyObjC() async {
        await checkAllPermutations(on: TestRequestStrategyObjc(managedObjectContext: syncMOC, applicationStatus: mockApplicationStatus))
    }

}
