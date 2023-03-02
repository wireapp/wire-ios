//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireDataModel
// TODO: move to a common support files framework? this is a duplicate Fake from SyncEngyne
// used by tests to fake errors on genrating pre keys
class SpyUserClientKeyStore: UserClientKeysStore {

    var failToGeneratePreKeys: Bool = false
    var failToGenerateLastPreKey: Bool = false

    var lastGeneratedKeys: [(id: UInt16, prekey: String)] = []
    var lastGeneratedLastPrekey: String?

    override public func generateMoreKeys(_ count: UInt16, start: UInt16) throws -> [(id: UInt16, prekey: String)] {

        if self.failToGeneratePreKeys {
            let error = NSError(domain: "cryptobox.error", code: 0, userInfo: ["reason": "using fake store with simulated fail"])
            throw error
        } else {
            let keys = try! super.generateMoreKeys(count, start: start)
            lastGeneratedKeys = keys
            return keys
        }
    }

    override public func lastPreKey() throws -> String {
        if self.failToGenerateLastPreKey {
            let error = NSError(domain: "cryptobox.error", code: 0, userInfo: ["reason": "using fake store with simulated fail"])
            throw error
        } else {
            lastGeneratedLastPrekey = try! super.lastPreKey()
            return lastGeneratedLastPrekey!
        }
    }

    var accessEncryptionContextCount = 0

    override var encryptionContext: EncryptionContext {
        get {
            accessEncryptionContextCount += 1
            return super.encryptionContext
        }
        set {
            super.encryptionContext = newValue
        }
    }

}
