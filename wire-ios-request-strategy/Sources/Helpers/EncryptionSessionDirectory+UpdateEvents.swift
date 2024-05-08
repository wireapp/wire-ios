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

import Foundation
import WireCryptobox
import WireSystem

private let zmLog = ZMSLog(tag: "cryptobox")

extension EncryptionSessionsDirectory {

    func decryptData(
        _ encryptedData: Data,
        for sessionID: EncryptionSessionIdentifier
    ) throws -> (didCreateNewSession: Bool, decryptedData: Data) {
        if self.hasSession(for: sessionID) {
            let decryptedData = try decrypt(encryptedData, from: sessionID)
            return (didCreateNewSession: false, decryptedData: decryptedData)
        } else {
            let decryptedData = try createClientSessionAndReturnPlaintext(for: sessionID, prekeyMessage: encryptedData)
            return (didCreateNewSession: true, decryptedData: decryptedData)
        }
    }

}
