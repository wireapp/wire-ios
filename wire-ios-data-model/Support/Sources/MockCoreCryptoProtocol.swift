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

public class MockCoreCryptoProtocol: WireCoreCrypto.CoreCryptoProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - transaction<Result>
    
    public typealias transaction_MethodType<Result> = (( (_ context: any WireCoreCryptoUniffi.CoreCryptoContextProtocol) async throws -> Result) async throws -> Void)

    public var transaction_Invocations: [(_ context: any WireCoreCryptoUniffi.CoreCryptoContextProtocol) async throws -> Any] = []
    public var transaction_MockError: Error?
    public var transaction_MockMethod: transaction_MethodType<Any>?
    public var transaction_MockValue: Any?

    public func transaction<Result>(_ block: @escaping (_ context: any WireCoreCryptoUniffi.CoreCryptoContextProtocol) async throws -> Result) async throws -> Result {
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

    // MARK: - setLogger

    public static var setLogger_Invocations: [any WireCoreCryptoUniffi.CoreCryptoLogger] = []
    public static var setLogger_MockMethod: ((any WireCoreCryptoUniffi.CoreCryptoLogger) -> Void)?

    static public func setLogger(_ logger: any WireCoreCryptoUniffi.CoreCryptoLogger) {
        setLogger_Invocations.append(logger)

        guard let mock = setLogger_MockMethod else {
            fatalError("no mock for `setLogger`")
        }

        mock(logger)
    }

    // MARK: - setMaxLogLevel

    public static var setMaxLogLevel_Invocations: [WireCoreCryptoUniffi.CoreCryptoLogLevel] = []
    public static var setMaxLogLevel_MockMethod: ((WireCoreCryptoUniffi.CoreCryptoLogLevel) -> Void)?

    static public func setMaxLogLevel(_ level: WireCoreCryptoUniffi.CoreCryptoLogLevel) {
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

    static public func version() -> String {
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

    static public func buildMetadata() -> WireCoreCryptoUniffi.BuildMetadata {
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
