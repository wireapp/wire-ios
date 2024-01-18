// Generated using Sourcery 2.1.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif


@testable import WireSyncEngine





















public class MockGetE2eIdentityCertificatesUseCaseProtocol: GetE2eIdentityCertificatesUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeConversationIdClientIds_Invocations: [(conversationId: Data, clientIds: [MLSClientID])] = []
    public var invokeConversationIdClientIds_MockError: Error?
    public var invokeConversationIdClientIds_MockMethod: ((Data, [MLSClientID]) async throws -> [E2eIdentityCertificate])?
    public var invokeConversationIdClientIds_MockValue: [E2eIdentityCertificate]?

    public func invoke(conversationId: Data, clientIds: [MLSClientID]) async throws -> [E2eIdentityCertificate] {
        invokeConversationIdClientIds_Invocations.append((conversationId: conversationId, clientIds: clientIds))

        if let error = invokeConversationIdClientIds_MockError {
            throw error
        }

        if let mock = invokeConversationIdClientIds_MockMethod {
            return try await mock(conversationId, clientIds)
        } else if let mock = invokeConversationIdClientIds_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeConversationIdClientIds`")
        }
    }

}

public class MockGetIsE2EIdentityEnabledUseCaseProtocol: GetIsE2EIdentityEnabledUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockError: Error?
    public var invoke_MockMethod: (() async throws -> Bool)?
    public var invoke_MockValue: Bool?

    public func invoke() async throws -> Bool {
        invoke_Invocations.append(())

        if let error = invoke_MockError {
            throw error
        }

        if let mock = invoke_MockMethod {
            return try await mock()
        } else if let mock = invoke_MockValue {
            return mock
        } else {
            fatalError("no mock for `invoke`")
        }
    }

}

public class MockGetUserClientFingerprintUseCaseProtocol: GetUserClientFingerprintUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeUserClient_Invocations: [UserClient] = []
    public var invokeUserClient_MockMethod: ((UserClient) async -> Data?)?
    public var invokeUserClient_MockValue: Data??

    public func invoke(userClient: UserClient) async -> Data? {
        invokeUserClient_Invocations.append(userClient)

        if let mock = invokeUserClient_MockMethod {
            return await mock(userClient)
        } else if let mock = invokeUserClient_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeUserClient`")
        }
    }

}

class MockRecurringActionServiceInterface: RecurringActionServiceInterface {

    // MARK: - Life cycle



    // MARK: - performActionsIfNeeded

    var performActionsIfNeeded_Invocations: [Void] = []
    var performActionsIfNeeded_MockMethod: (() -> Void)?

    func performActionsIfNeeded() {
        performActionsIfNeeded_Invocations.append(())

        guard let mock = performActionsIfNeeded_MockMethod else {
            fatalError("no mock for `performActionsIfNeeded`")
        }

        mock()
    }

    // MARK: - registerAction

    var registerAction_Invocations: [RecurringAction] = []
    var registerAction_MockMethod: ((RecurringAction) -> Void)?

    func registerAction(_ action: RecurringAction) {
        registerAction_Invocations.append(action)

        guard let mock = registerAction_MockMethod else {
            fatalError("no mock for `registerAction`")
        }

        mock(action)
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
