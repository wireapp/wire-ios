// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import XCTest
import zmessaging
import ZMTesting
import ZMTransport

class APSSignalingKeyStoreTests: MessagingTest {
    func testThatItCreatesKeyStoreWithoutKeychain() {
        // given
        let keySize : Int = 256 / 8
        // when
        let keyStore = APSSignalingKeysStore(fromKeychain: false)

        // then
        AssertOptionalNotNil(keyStore) { keyStore in
            AssertOptionalNotNil(keyStore.verificationKey) { _ in
                AssertOptionalNotNil(keyStore.decryptionKey) { _ in
                    XCTAssertEqual(keyStore.verificationKey.length, keySize)
                    XCTAssertEqual(keyStore.decryptionKey.length, keySize)
                }
            }
        }
    }
    
    func testThatItRandomizesTheKeys() {
        // when
        let keyStore1 = APSSignalingKeysStore(fromKeychain: false)
        let keyStore2 = APSSignalingKeysStore(fromKeychain: false)
        
        // then
        AssertOptionalNotNil(keyStore1) { keyStore1 in
            AssertOptionalNotNil(keyStore2) { keyStore2 in
                XCTAssertNotEqual(keyStore1.verificationKey, keyStore2.verificationKey)
                XCTAssertNotEqual(keyStore1.decryptionKey,   keyStore2.decryptionKey)
                XCTAssertNotEqual(keyStore1.verificationKey, keyStore1.decryptionKey)
                XCTAssertNotEqual(keyStore1.verificationKey, keyStore1.decryptionKey)
            }
        }
    }
    
    func testThatItFailsToCreateKeyStoreWithKeychainIfThereIsNoData() {
        // given
        ZMKeychain.deleteAllKeychainItemsWithAccountName("APSVerificationKey")
        ZMKeychain.deleteAllKeychainItemsWithAccountName("APSDecryptionKey")

        // when
        let keyStore = APSSignalingKeysStore(fromKeychain: true)

        // then
        AssertOptionalNil(keyStore)
    }
    
    func testThatItCreatesKeyStoreWithKeychainIfThereIsData() {
        // given
        let keyStoreNew = APSSignalingKeysStore(fromKeychain: false)
        keyStoreNew?.saveToKeychain()

        // when
        let keyStoreFromKeychain = APSSignalingKeysStore(fromKeychain: true)


        // then
        AssertOptionalNotNil(keyStoreNew) { keyStoreNew in
            AssertOptionalNotNil(keyStoreFromKeychain) { keyStoreFromKeychain in
                XCTAssertEqual(keyStoreNew.verificationKey, keyStoreFromKeychain.verificationKey)
                XCTAssertEqual(keyStoreNew.decryptionKey, keyStoreFromKeychain.decryptionKey)
            }
        }
        
    }

    func testThatItOverwritesTheExistingKeychain() {
        // given
        let keyStoreNew = APSSignalingKeysStore(fromKeychain: false)
        keyStoreNew?.saveToKeychain()

        // when
        let keyStoreNew2 = APSSignalingKeysStore(fromKeychain: false)
        keyStoreNew2?.saveToKeychain()

        let keyStoreFromKeychain = APSSignalingKeysStore(fromKeychain: true)

        // then
        AssertOptionalNotNil(keyStoreNew) { keyStoreNew in
            AssertOptionalNotNil(keyStoreNew2) { keyStoreNew2 in
                AssertOptionalNotNil(keyStoreFromKeychain) { keyStoreFromKeychain in
                    XCTAssertEqual(keyStoreNew2.verificationKey, keyStoreFromKeychain.verificationKey)
                    XCTAssertEqual(keyStoreNew2.decryptionKey, keyStoreFromKeychain.decryptionKey)
                    
                    XCTAssertNotEqual(keyStoreNew.verificationKey, keyStoreFromKeychain.verificationKey)
                    XCTAssertNotEqual(keyStoreNew.decryptionKey, keyStoreFromKeychain.decryptionKey)
                }
            }
        }
    }
}
