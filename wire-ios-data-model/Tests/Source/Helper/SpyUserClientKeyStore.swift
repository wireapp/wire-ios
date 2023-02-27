//
//  SpyUserKeyStore.swift
//  WireDataModelTests
//
//  Created by F on 27/02/2023.
//  Copyright © 2023 Wire Swiss GmbH. All rights reserved.
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
