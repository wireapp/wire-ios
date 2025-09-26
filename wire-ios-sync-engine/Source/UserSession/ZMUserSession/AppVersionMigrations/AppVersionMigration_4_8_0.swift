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

import GenericMessageProtocol
import WireDataModel
import WireDomain

struct AppVersionMigration_4_8_0: AppVersionMigration {

    let version: SemanticVersion = "4.8.0"
    let contextProvider: ContextProvider
    // let coreCryptoProvider: CoreCryptoProviderProtocol

    func perform() async throws {

        let context = contextProvider.syncContext
        let unknownMessages = try await context.perform {
            let fetchRequest = UnknownMessage.fetchRequest()
            let unknownMessages = try context.fetch(fetchRequest)
            return unknownMessages.map { ($0.nonce, $0.payload) }
        }

        for (messageID, payload) in unknownMessages {
            guard let messageID, let payload, let message = GenericMessage(from: payload, validate: false) else {
                continue
            }


            print(message)

            // TODO: delete/replace unknown message
        }


        //throw SomeError.some // fatalError()
    }

}

enum SomeError: Error {
    case some
}
