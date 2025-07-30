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

/*// sourcery: AutoMockable*/
public protocol CoreCryptoProtocol {

    /// Instantiate a history client.
    ///
    /// This client exposes the full interface of ``Self``, but it should only be used to decrypt messages.
    /// Other use is a logic error.
    static func historyClient(_ historySecret: WireCoreCryptoUniffi.HistorySecret) async throws -> Self

    /// Starts a transaction in Core Crypto. If the closure succeeds without throwing an error, it will be committed, otherwise, every operation
    /// performed with the context will be discarded.
    ///
    /// - Parameter block: the closure to be executed within the transaction context. A ``CoreCryptoContext-swift.protocol``
    ///  is provided on which any operations should be performed.
    ///
    /// - Returns: Result value returned from the closure if any.
    ///
    func transaction<Result>(_ block: @escaping (_ context: any WireCoreCryptoUniffi.CoreCryptoContextProtocol) async throws -> Result) async throws -> Result

    /// Register a callback which will be called when performing MLS operations which require communication with the delivery service.
    ///
    func provideTransport(transport: any WireCoreCryptoUniffi.MlsTransport) async throws

    ///
    /// Register an Epoch Observer which will be notified every time a conversation's epoch changes.
    ///
    /// - Parameter epochObserver: epoch observer to register
    ///
    /// This function should be called 0 or 1 times in the lifetime of CoreCrypto,
    /// regardless of the number of transactions.
    ///
    func registerEpochObserver(_ epochObserver: any WireCoreCryptoUniffi.EpochObserver) async throws

    ///
    /// Register a History Observer which will be notified every time a new history secret is created locally.
    ///
    /// - Parameter historyObserver: history observer to register
    ///
    /// This function should be called 0 or 1 times in the lifetime of CoreCrypto,
    /// regardless of the number of transactions.
    ///
    func registerHistoryObserver(_ historyObserver: any WireCoreCryptoUniffi.HistoryObserver) async throws

    /// Check if history sharing is enabled, i.e., if any of the conversation members have a ``ClientId`` starting
    /// with the specific history client prefix.
    func isHistorySharingEnabled(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> Bool

    /// Register CoreCrypto a logger
    ///
    static func setLogger(_ logger: any WireCoreCryptoUniffi.CoreCryptoLogger)

    /// Set the log level limit for logs which should be forwarded to the registered ``CoreCryptoLogger-5nvug``
    ///
    /// The default log level is `info`.
    ///
    static func setMaxLogLevel(_ level: WireCoreCryptoUniffi.CoreCryptoLogLevel)

    /// CoreCrypto build version number
    ///
    static func version() -> String

    /// Build metadata describing under which conditions this version of CoreCrypto was build.
    ///
    static func buildMetadata() -> WireCoreCryptoUniffi.BuildMetadata
}
