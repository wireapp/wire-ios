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

public class CoreCryptoMocksEnvelope {

    // MARK: - Public attributes

    public var coreCryptoContext: MockCoreCryptoContextProtocol
    public var coreCrypto: MockCoreCryptoProtocol
    public var coreCryptoProvider: MockCoreCryptoProviderProtocol

    // MARK: - Private attributes

    private var transactionContinuations: [CheckedContinuation<Void, Never>] = []

    // MARK: - Init

    public init() {
        self.coreCryptoContext = MockCoreCryptoContextProtocol()
        self.coreCrypto = MockCoreCryptoProtocol()
        self.coreCryptoProvider = MockCoreCryptoProviderProtocol()

        coreCryptoProvider.coreCrypto_MockValue = coreCrypto
        coreCrypto.mockTransaction(context: coreCryptoContext)
    }

    // MARK: - Public interface

    public func setCompleteTransactionByDefault(_ completeTransactionByDefault: Bool) {
        coreCrypto.transaction_MockMethod = { [coreCryptoContext] block in
            let result = try await block(coreCryptoContext)

            if !completeTransactionByDefault {
                await withCheckedContinuation { continuation in
                    self.transactionContinuations.append(continuation)
                }
            }

            return result
        }
    }

    public func waitUntilTransactionIsPending() async throws {
        while transactionContinuations.isEmpty {
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    public func completeAllTransactions() {
        transactionContinuations.forEach {
            $0.resume()
        }
    }

}
