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

/// Wrapper to execute
class TransactionExecutor<Result>: CoreCryptoCommand {
    let block: (_ context: CoreCryptoContext) async throws -> Result?
    var result: Result?

    init(
        _ block: @escaping (_ context: CoreCryptoContext) async throws -> Result?
    ) {
        self.block = block
    }

    func execute(context: CoreCryptoContext) async throws {
        result = try await block(context)
    }
}

extension CoreCryptoProtocol {
    /// note: here we could return Result instead of Result? but to solve [WPB-16231]
    /// this is the only way right now, once CC don't throw these errors we can adapt this
    func transaction<Result>(
        _ block: @escaping (_ context: CoreCryptoContext) async throws -> Result?
    ) async throws -> Result? {
        let transactionExecutor = TransactionExecutor<Result>(block)
        try await transaction(command: transactionExecutor)
        return transactionExecutor.result
    }
}
