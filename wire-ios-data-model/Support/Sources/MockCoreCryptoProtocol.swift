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

import WireCoreCrypto

public extension MockCoreCryptoProtocol {
    
    func mockTransaction(context: CoreCryptoContextProtocol) {
        transaction_MockMethod = { block in
            return try await block(context)
        }
    }
}

public class MockCoreCryptoProtocol: CoreCryptoProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - historyClient

    public static var historyClient_Invocations: [WireCoreCryptoUniffi.HistorySecret] = []
    public static var historyClient_MockError: Error?
    public static var historyClient_MockMethod: (
        (WireCoreCryptoUniffi.HistorySecret) async throws
            -> MockCoreCryptoProtocol
    )?
    public static var historyClient_MockValue: MockCoreCryptoProtocol?

    public static func historyClient(_ historySecret: WireCoreCryptoUniffi.HistorySecret) async throws -> Self {
        historyClient_Invocations.append(historySecret)

        if let error = historyClient_MockError {
            throw error
        }
        if let mockMethod = historyClient_MockMethod {
            guard let result = try await mockMethod(historySecret) as? Self else {
                fatalError("Mock method did not return correct type")
            }
            return result
        }

        if let mockValue = historyClient_MockValue {
            guard let result = mockValue as? Self else {
                fatalError("Mock value is not of expected type")
            }
            return result
        }
        fatalError("no mock for `historyClient`")
    }

    // MARK: - transaction<Result>

    public typealias transaction_MethodType<Result> =
        ((_ context: any WireCoreCryptoUniffi.CoreCryptoContextProtocol) async throws -> Result) async throws -> Result

    public var transaction_Invocations: [
        (_ context: any WireCoreCryptoUniffi.CoreCryptoContextProtocol) async throws
            -> Any
    ] = []
    public var transaction_MockError: Error?
    public var transaction_MockMethod: transaction_MethodType<Any>?
    public var transaction_MockValue: Any?

    public func transaction<Result>(_ block: @escaping (
        _ context: any WireCoreCryptoUniffi
            .CoreCryptoContextProtocol
    ) async throws -> Result) async throws -> Result {
        transaction_Invocations.append(block)

        if let error = transaction_MockError {
            throw error
        }

        if let mock = transaction_MockMethod {
            return try await mock(block) as! Result
        } else if let mock = transaction_MockValue {
            return mock as! Result
        } else {
            fatalError("no mock for `transaction`")
        }
    }

    // MARK: - provideTransport

    public var provideTransportTransport_Invocations: [any WireCoreCryptoUniffi.MlsTransport] = []
    public var provideTransportTransport_MockError: Error?
    public var provideTransportTransport_MockMethod: ((any WireCoreCryptoUniffi.MlsTransport) async throws -> Void)?

    public func provideTransport(transport: any WireCoreCryptoUniffi.MlsTransport) async throws {
        provideTransportTransport_Invocations.append(transport)

        if let error = provideTransportTransport_MockError {
            throw error
        }

        guard let mock = provideTransportTransport_MockMethod else {
            fatalError("no mock for `provideTransportTransport`")
        }

        try await mock(transport)
    }

    // MARK: - registerEpochObserver

    public var registerEpochObserver_Invocations: [any WireCoreCryptoUniffi.EpochObserver] = []
    public var registerEpochObserver_MockError: Error?
    public var registerEpochObserver_MockMethod: ((any WireCoreCryptoUniffi.EpochObserver) async throws -> Void)?

    public func registerEpochObserver(_ epochObserver: any WireCoreCryptoUniffi.EpochObserver) async throws {
        registerEpochObserver_Invocations.append(epochObserver)

        if let error = registerEpochObserver_MockError {
            throw error
        }

        guard let mock = registerEpochObserver_MockMethod else {
            fatalError("no mock for `registerEpochObserver`")
        }

        try await mock(epochObserver)
    }

    // MARK: - registerHistoryObserver

    public var registerHistoryObserver_Invocations: [any WireCoreCryptoUniffi.HistoryObserver] = []
    public var registerHistoryObserver_MockError: Error?
    public var registerHistoryObserver_MockMethod: ((any WireCoreCryptoUniffi.HistoryObserver) async throws -> Void)?

    public func registerHistoryObserver(_ historyObserver: any WireCoreCryptoUniffi.HistoryObserver) async throws {
        registerHistoryObserver_Invocations.append(historyObserver)

        if let error = registerHistoryObserver_MockError {
            throw error
        }

        guard let mock = registerHistoryObserver_MockMethod else {
            fatalError("no mock for `registerHistoryObserver`")
        }

        try await mock(historyObserver)
    }

    // MARK: - isHistorySharingEnabled

    public var isHistorySharingEnabledConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var isHistorySharingEnabledConversationId_MockError: Error?
    public var isHistorySharingEnabledConversationId_MockMethod: (
        (WireCoreCryptoUniffi.ConversationId) async throws
            -> Bool
    )?
    public var isHistorySharingEnabledConversationId_MockValue: Bool?

    public func isHistorySharingEnabled(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> Bool {
        isHistorySharingEnabledConversationId_Invocations.append(conversationId)

        if let error = isHistorySharingEnabledConversationId_MockError {
            throw error
        }

        if let mock = isHistorySharingEnabledConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = isHistorySharingEnabledConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `isHistorySharingEnabledConversationId`")
        }
    }

    // MARK: - setLogger

    public static var setLogger_Invocations: [any WireCoreCryptoUniffi.CoreCryptoLogger] = []
    public static var setLogger_MockMethod: ((any WireCoreCryptoUniffi.CoreCryptoLogger) -> Void)?

    public static func setLogger(_ logger: any WireCoreCryptoUniffi.CoreCryptoLogger) {
        setLogger_Invocations.append(logger)

        guard let mock = setLogger_MockMethod else {
            fatalError("no mock for `setLogger`")
        }

        mock(logger)
    }

    // MARK: - setMaxLogLevel

    public static var setMaxLogLevel_Invocations: [WireCoreCryptoUniffi.CoreCryptoLogLevel] = []
    public static var setMaxLogLevel_MockMethod: ((WireCoreCryptoUniffi.CoreCryptoLogLevel) -> Void)?

    public static func setMaxLogLevel(_ level: WireCoreCryptoUniffi.CoreCryptoLogLevel) {
        setMaxLogLevel_Invocations.append(level)

        guard let mock = setMaxLogLevel_MockMethod else {
            fatalError("no mock for `setMaxLogLevel`")
        }

        mock(level)
    }

    // MARK: - version

    public static var version_Invocations: [Void] = []
    public static var version_MockMethod: (() -> String)?
    public static var version_MockValue: String?

    public static func version() -> String {
        version_Invocations.append(())

        if let mock = version_MockMethod {
            return mock()
        } else if let mock = version_MockValue {
            return mock
        } else {
            fatalError("no mock for `version`")
        }
    }

    // MARK: - buildMetadata

    public static var buildMetadata_Invocations: [Void] = []
    public static var buildMetadata_MockMethod: (() -> WireCoreCryptoUniffi.BuildMetadata)?
    public static var buildMetadata_MockValue: WireCoreCryptoUniffi.BuildMetadata?

    public static func buildMetadata() -> WireCoreCryptoUniffi.BuildMetadata {
        buildMetadata_Invocations.append(())

        if let mock = buildMetadata_MockMethod {
            return mock()
        } else if let mock = buildMetadata_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildMetadata`")
        }
    }

}
