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
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import Foundation
import XCTest
@testable import Cryptobox


class EncryptionSessionsDirectoryTests : XCTestCase {
    
    var contextAlice : EncryptionContext!
    var contextBob : EncryptionContext!
    var statusAlice : EncryptionSessionsDirectory!
    var statusBob : EncryptionSessionsDirectory!
    
    override func setUp() {
        self.contextAlice = createEncryptionContext()
        self.contextBob = createEncryptionContext()
        self.recreateStatuses()
    }
    
    override func tearDown() {
        statusAlice = nil
        statusBob = nil
        contextAlice = nil
        contextBob = nil
    }
    
}

// MARK: - Session creation and encoding/decoding
extension EncryptionSessionsDirectoryTests {
    func testThatItCanDecodeAfterInitializingWithAValidKey() {
        
        // GIVEN
        let plainText = "foo".data(using: String.Encoding.utf8)!
        
        // WHEN
        do {
            try statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: statusBob.generatePrekey(2))
        } catch {
            XCTFail()
            return
        }
        
        // THEN
        let prekeyMessage = try! statusAlice.encrypt(plainText, recipientIdentifier: Person.Bob.identifier)
        let decoded = try! statusBob.createClientSessionAndReturnPlaintext(Person.Alice.identifier, prekeyMessage: prekeyMessage)
        XCTAssertEqual(decoded, plainText)
    }
    
    func testThatItCanCallCreateSessionWithTheSameKeyMultipleTimes() {
        
        // GIVEN
        let plainText = "foo".data(using: String.Encoding.utf8)!
        let prekey = try! statusBob.generatePrekey(34)
        do {
            try statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: prekey)
        } catch {
            XCTFail()
            return
        }
        
        // WHEN
        do {
            try statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: prekey)
        } catch {
            XCTFail()
            return
        }
        
        // THEN
        let prekeyMessage = try! statusAlice.encrypt(plainText, recipientIdentifier: Person.Bob.identifier)
        let decoded = try! statusBob.createClientSessionAndReturnPlaintext(Person.Alice.identifier, prekeyMessage: prekeyMessage)
        XCTAssertEqual(decoded, plainText)
        
    }
    
    func testThatItCanNotCreateANewSessionWithAnInvalidKey() {
     
        // GIVEN
        
        // WHEN
        do {
            _ = try statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: "aabb")
            XCTFail("should have failed to use prekey")
        }
        catch let err as CryptoboxError {
            XCTAssertEqual(err, CryptoboxError.decodeError)
        } catch {
            XCTFail("should have thrown a CBoxResult")
        }
    }
    
    func testThatItCanNotDecodePrekeyMessagesWithTheWrongKey() {
        
        // GIVEN
        
        // WHEN
        do {
            _ = try statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: hardcodedPrekey)
        }
        catch {
            XCTFail()
            return
        }
        
        // THEN
        XCTAssertFalse(checkThatAMessageCanBeSent(.Alice))
        
    }
}

// MARK: - Prekeys
extension EncryptionSessionsDirectoryTests {

    func testThatItGeneratesAPrekey() {
        
        // GIVEN
        let prekeyId : UInt16 = 12
        
        // WHEN
        let prekey = try! statusAlice.generatePrekey(prekeyId)
        
        // THEN
        var prekeyRetrievedId : UInt16 = 0
        let prekeyData = Data(base64Encoded: prekey, options: [])!
        let result = prekeyData.withUnsafeBytes { (prekeyDataPointer: UnsafePointer<UInt8>) -> CBoxResult in  cbox_is_prekey(prekeyDataPointer, prekeyData.count, &prekeyRetrievedId) }
        XCTAssertEqual(result, CBOX_SUCCESS)
        XCTAssertEqual(prekeyRetrievedId, prekeyId)
        
    }
    
    func testThatItGeneratesLastPrekey() {
        
        // GIVEN
        let prekeyId : UInt16 = CBOX_LAST_PREKEY_ID
        
        // WHEN
        let prekey = try! statusAlice.generateLastPrekey()
        
        // THEN
        var prekeyRetrievedId : UInt16 = 0
        let prekeyData = Data(base64Encoded: prekey, options: [])!
        let result = prekeyData.withUnsafeBytes { (prekeyDataPointer: UnsafePointer<UInt8>) -> CBoxResult in  cbox_is_prekey(prekeyDataPointer, prekeyData.count, &prekeyRetrievedId) }
        XCTAssertEqual(result, CBOX_SUCCESS)
        XCTAssertEqual(prekeyRetrievedId, prekeyId)
        
    }
    
    func testThatItGeneratesARangeOfPrekeys() {
        
        // GIVEN
        let rangeStart = 3
        let rangeLength = 10
        let prekeyIds : CountableRange<UInt16> = UInt16(rangeStart)..<UInt16(rangeStart+rangeLength)
        
        // WHEN
        var prekeys : [(id: UInt16, prekey: String)] = []
        prekeys = try! statusAlice.generatePrekeys(prekeyIds)
        
        // THEN
        XCTAssertEqual(prekeyIds.count, rangeLength)
        for i in 0..<rangeLength {
            let (id, prekey) = prekeys[i]
            let prekeyData = Data(base64Encoded: prekey, options: [])!
            var prekeyRetrievedId : UInt16 = 0
            let result = prekeyData.withUnsafeBytes { (prekeyDataPointer: UnsafePointer<UInt8>) -> CBoxResult in  cbox_is_prekey(prekeyDataPointer, prekeyData.count, &prekeyRetrievedId) }
            XCTAssertEqual(result, CBOX_SUCCESS)
            XCTAssertEqual(Int(prekeyRetrievedId), i+rangeStart)
            XCTAssertEqual(prekeyRetrievedId, id)
        }
    }
}

// MARK: - Local fingerprint
extension EncryptionSessionsDirectoryTests {
    
    func testThatItReturnsTheLocalFingerprint() {
        
        // GIVEN

        // WHEN
        let fingerprint = statusAlice.localFingerprint
        
        // THEN
        // check it's consistent
        XCTAssertEqual(statusAlice.localFingerprint, fingerprint)
    }

    func testThatASessionHasAMatchingRemoteFingerprint() {
        
        // GIVEN
        
        // WHEN
        establishSessionBetweenAliceAndBob()
        
        // THEN
        let aliceLocalFingerprint = statusAlice.localFingerprint
        let bobLocalFingerprint = statusBob.localFingerprint
        let aliceRemoteFingerprint = statusBob.fingerprintForClient(Person.Alice.identifier)
        let bobRemoteFingerprint = statusAlice.fingerprintForClient(Person.Bob.identifier)
        XCTAssertEqual(aliceLocalFingerprint, aliceRemoteFingerprint)
        XCTAssertEqual(bobLocalFingerprint, bobRemoteFingerprint)
        XCTAssertNotNil(aliceLocalFingerprint)
        XCTAssertNotNil(bobLocalFingerprint)
    }
    
    func testThatAClientWithoutSessionHasNoRemoteFingerprint() {
        
        // GIVEN
        // WHEN
        // THEN
        XCTAssertNil(statusAlice.fingerprintForClient("aa228899"))
    }
}

// MARK: - Deletion
extension EncryptionSessionsDirectoryTests {
    
    func testThatItDeletesASession() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        
        // WHEN
        statusAlice.delete(Person.Bob.identifier)
        
        // THEN
        let cypherText = try? statusAlice.encrypt("foo".data(using: String.Encoding.utf8)!, recipientIdentifier: Person.Bob.identifier)
        XCTAssertNil(cypherText)
    }
    
    func testThatItCanDeleteASessionThatDoesNotExist() {
        
        // GIVEN
        
        // WHEN
        statusAlice.delete(hardcodedClientId)
        
        // THEN
        // no crash
    }
}

// MARK: - Session cache management
extension EncryptionSessionsDirectoryTests {
    
    func testThatCreatedSessionsAreNotSavedImmediately() {
        
        // GIVEN
        
        // WHEN
        try! statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: statusBob.generatePrekey(1))
        
        // THEN
        let statusAliceCopy = EncryptionSessionsDirectory(generatingContext: contextAlice)
        statusAliceCopy.debug_disableContextValidityCheck = true
        let cypher = try? statusAliceCopy.encrypt("foo".data(using: String.Encoding.utf8)!, recipientIdentifier: Person.Bob.identifier)
        XCTAssertNil(cypher)
    }

    func testThatNewlyCreatedSessionsAreSavedWhenReleasingTheStatus() {
        
        // GIVEN
        let plainText = "foo".data(using: String.Encoding.utf8)!
        try! statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: statusBob.generatePrekey(1))
        
        // WHEN
        statusAlice = nil
        
        // THEN
        let statusAliceCopy = EncryptionSessionsDirectory(generatingContext: contextAlice)
        statusAliceCopy.debug_disableContextValidityCheck = true
        let prekeyMessage = try! statusAliceCopy.encrypt(plainText, recipientIdentifier: Person.Bob.identifier)
        let decoded = try! statusBob.createClientSessionAndReturnPlaintext(Person.Alice.identifier, prekeyMessage: prekeyMessage)
        XCTAssertEqual(plainText, decoded)
    }
    
    func testThatNewlyCreatedSessionsAreNotSavedWhenDiscarding() {
        
        // GIVEN
        try! statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: statusBob.generatePrekey(1))
        
        // WHEN
        statusAlice.discardCache()
        statusAlice = nil
        
        // THEN
        let statusAliceCopy = EncryptionSessionsDirectory(generatingContext: contextAlice)
        statusAliceCopy.debug_disableContextValidityCheck = true
        let cypher = try? statusAliceCopy.encrypt("foo".data(using: String.Encoding.utf8)!, recipientIdentifier: Person.Bob.identifier)
        XCTAssertNil(cypher)
    }
    
    func testThatModifiedSessionsAreNotSavedWhenDiscarding() {
        
        // GIVEN
        let plainText = "foo".data(using: String.Encoding.utf8)!
        try! statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: statusBob.generatePrekey(1))
        let prekeyMessage = try! statusAlice.encrypt(plainText, recipientIdentifier: Person.Bob.identifier)
        _ = try! statusBob.createClientSessionAndReturnPlaintext(Person.Alice.identifier, prekeyMessage: prekeyMessage)
        self.recreateStatuses() // force save
        
        // WHEN
        let cypherText = try! statusAlice.encrypt(plainText, recipientIdentifier: Person.Bob.identifier)
        _ = try! statusBob.decrypt(cypherText, senderIdentifier: Person.Alice.identifier)
        statusBob.discardCache()
        statusBob = nil
        
        // THEN
        let statusBobCopy = EncryptionSessionsDirectory(generatingContext: contextBob)
        statusBobCopy.debug_disableContextValidityCheck = true
        let decoded = try! statusBobCopy.decrypt(cypherText, senderIdentifier: Person.Alice.identifier)
        XCTAssertEqual(decoded, plainText)
    }
    
    func testThatItCanNotDecodeAfterDiscardingCache() {
        
        // GIVEN
        try! statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: statusBob.generatePrekey(34))
        
        // WHEN
        statusAlice.discardCache()
        
        // THEN
        XCTAssertFalse(checkThatAMessageCanBeSent(.Alice))
    }
    
    func testThatItDecodeFutureMessageAfterDiscardingCacheOnTheReceivingSide() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        checkThatAMessageCanBeSent(.Alice, saveReceiverCache: false)
        
        // WHEN
        statusBob.discardCache()
        
        // THEN
        XCTAssertNotNil(checkThatAMessageCanBeSent(.Alice))
    }
    
    func testThatItCanNotDecodeDuplicatedMessageIfTheCacheIsNotDiscarded() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        let plainText = "foo".data(using: String.Encoding.utf8)!
        let cypherText = try! statusAlice.encrypt(plainText, recipientIdentifier: Person.Bob.identifier)
        _ = try! statusBob.decrypt(cypherText, senderIdentifier: Person.Alice.identifier)
        
        // WHEN
        do {
            _ = try statusBob.decrypt(cypherText, senderIdentifier: Person.Alice.identifier)
            XCTFail("Should have failed")
            return
        } catch let err as CryptoboxError where err == .duplicateMessage {
            // pass
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testThatItCanNotDecodeDuplicatedMessageIfTheCacheIsNotDiscardedAndReportsTheCorrectErrorInObjC() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        let plainText = "foo".data(using: String.Encoding.utf8)!
        let cypherText = try! statusAlice.encrypt(plainText, recipientIdentifier: Person.Bob.identifier)
        _ = try! statusBob.decrypt(cypherText, senderIdentifier: Person.Alice.identifier)
        
        // WHEN
        do {
            _ = try statusBob.decrypt(cypherText, senderIdentifier: Person.Alice.identifier)
            XCTFail("Should have failed")
            return
        } catch {
            let matcher = ObjCInteroperabilityMatcher()
            let correctObjCError = matcher.returnsCorrectErrorCodeDecryptingCypher(
                cypherText,
                senderIdentifier: Person.Alice.identifier,
                expectedError: .duplicateMessage,
                sessionDirectory: statusBob
            )
            
            XCTAssertTrue(correctObjCError)
        }
    }
    
    func testThatItCanDecodeDuplicatedMessageIfTheCacheIsDiscarded() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        let plainText = "foo".data(using: String.Encoding.utf8)!
        let cypherText = try! statusAlice.encrypt(plainText, recipientIdentifier: Person.Bob.identifier)
        _ = try! statusBob.decrypt(cypherText, senderIdentifier: Person.Alice.identifier)
        
        // WHEN
        statusBob.discardCache()
        
        // THEN
        do {
            _ = try statusBob.decrypt(cypherText, senderIdentifier: Person.Alice.identifier)
        } catch {
            XCTFail("Should decrypt")
        }
    }
    
    func testThatItCanNotDecodeDuplicatedMessageIfTheCacheIsCommitted() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        let plainText = "foo".data(using: String.Encoding.utf8)!
        let cypherText = try! statusAlice.encrypt(plainText, recipientIdentifier: Person.Bob.identifier)
        _ = try! statusBob.decrypt(cypherText, senderIdentifier: Person.Alice.identifier)
        
        // WHEN
        self.recreateStatuses() // force save
        
        // THEN
        do {
            _ = try statusBob.decrypt(cypherText, senderIdentifier: Person.Alice.identifier)
            XCTFail("Should have failed")
            return
        } catch let err as CryptoboxError where err == .duplicateMessage {
            // pass
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testThatItCanDecodeAfterSavingCache() {
        
        // GIVEN
        let plainText = "foo".data(using: String.Encoding.utf8)!
        try! statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: statusBob.generatePrekey(34))
        
        // WHEN
        self.recreateStatuses() // force save
        
        // THEN
        let prekeyMessage = try! statusAlice.encrypt(plainText, recipientIdentifier: Person.Bob.identifier)
        let decoded = try! statusBob.createClientSessionAndReturnPlaintext(Person.Alice.identifier, prekeyMessage: prekeyMessage)
        XCTAssertEqual(decoded, plainText)
    }
    
    func testThatItCanDecodeMultipleMessagesWithoutSaving() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        
        // WHEN
        checkThatAMessageCanBeSent(.Alice, saveReceiverCache: false)
        
        // THEN
        XCTAssertTrue(checkThatAMessageCanBeSent(.Alice))
        XCTAssertTrue(checkThatAMessageCanBeSent(.Alice))
        XCTAssertTrue(checkThatAMessageCanBeSent(.Alice))
    }
}


// MARK: - Session migration tests
extension EncryptionSessionsDirectoryTests {
    
    func testThatItCanMigrateASessionAndReceive() {
        
        // GIVEN
        let oldIdentifier = "aabbccdd"
        bobIdentifierOverride = oldIdentifier
        
        establishSessionBetweenAliceAndBob()
        checkThatAMessageCanBeSent(.Alice)
        checkThatAMessageCanBeSent(.Bob)
        
        // WHEN
        bobIdentifierOverride = nil
        statusAlice.migrateSession(fromIdentifier: oldIdentifier, toIdentifier: Person.Bob.identifier)
        
        
        // THEN
        XCTAssertTrue(checkThatAMessageCanBeSent(.Bob))
    }
    
    func testThatItCanMigrateASessionAndSend() {
        
        // GIVEN
        let oldIdentifier = "aabbccdd"
        bobIdentifierOverride = oldIdentifier
        
        establishSessionBetweenAliceAndBob()
        checkThatAMessageCanBeSent(.Alice)
        checkThatAMessageCanBeSent(.Bob)
        
        // WHEN
        bobIdentifierOverride = nil
        statusAlice.migrateSession(fromIdentifier: oldIdentifier, toIdentifier: Person.Bob.identifier)
        
        
        // THEN
        XCTAssertTrue(checkThatAMessageCanBeSent(.Bob))
    }
    
    func testThatItWontMigrateIfNewSessionAlreadyExists() {
        
        // GIVEN
        let oldIdentifier = "aabbccdd"
        
        establishSessionBetweenAliceAndBob()
        checkThatAMessageCanBeSent(.Alice)
        checkThatAMessageCanBeSent(.Bob)
        
        bobIdentifierOverride = oldIdentifier
        establishSessionFromAliceToBob()
        
        // WHEN
        bobIdentifierOverride = nil
        statusAlice.migrateSession(fromIdentifier: oldIdentifier, toIdentifier: Person.Bob.identifier)
        
        // THEN
        XCTAssertTrue(checkThatAMessageCanBeSent(.Bob))
    }
    
    func testThatItWontMigrateIfOldSessionDoesNotExists() {
        
        // GIVEN
        let oldIdentifier = "aabbccdd"
        
        establishSessionBetweenAliceAndBob()
        checkThatAMessageCanBeSent(.Alice)
        checkThatAMessageCanBeSent(.Bob)
        
        // WHEN
        statusAlice.migrateSession(fromIdentifier: oldIdentifier, toIdentifier: Person.Bob.identifier)
        
        // THEN
        XCTAssertTrue(checkThatAMessageCanBeSent(.Bob))
    }
}

// MARK: - Helpers

/// Custom session identifier for Bob
private var bobIdentifierOverride : String? = nil

extension EncryptionSessionsDirectoryTests {
    
    /// Recreate the statuses, reloading from disk. This also forces a save of the previous
    /// statuses, if any.
    func recreateStatuses(only: Person? = nil) {
        if only == nil || only == .Alice {
            self.statusAlice = EncryptionSessionsDirectory(generatingContext: contextAlice)
            self.statusAlice.debug_disableContextValidityCheck = true
        }
        if only == nil || only == .Bob {
            self.statusBob = EncryptionSessionsDirectory(generatingContext: contextBob)
            self.statusBob.debug_disableContextValidityCheck = true
        }
    }
    
    /// Sends a prekey message from Alice to Bob, decrypts it on Bob's side, and save both
    func establishSessionBetweenAliceAndBob() {
        self.establishSessionFromAliceToBob()
        let prekeyMessage = try! statusAlice.encrypt("foo".data(using: String.Encoding.utf8)!, recipientIdentifier: Person.Bob.identifier)
        _ = try! statusBob.createClientSessionAndReturnPlaintext(Person.Alice.identifier, prekeyMessage: prekeyMessage)
        
        /// This will force commit
        self.recreateStatuses()
    }
    
    /// Creates a client session from Alice to Bob
    func establishSessionFromAliceToBob() {
        let prekey = try! statusBob.generatePrekey(2)
        try! statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: prekey)
    }
    
    
    enum Person {
        case Alice
        case Bob
        
        var identifier : String {
            switch(self) {
            case .Alice:
                return "234ab2e4c45-a11c30"
            case .Bob:
                return bobIdentifierOverride ?? "a34affe3366-b0b0b0b"
            }
        }
        
        var other : Person {
            switch(self) {
            case .Alice:
                return .Bob
            case .Bob:
                return .Alice
            }
        }
    }
    
    /// Checks if a person already decrypted a message
    /// Reverts the session after performing the check
    /// Will only work after after calling `establishSessionBetweenAliceAndBob`
    func checkIfPersonAlreadyDecryptedMessage(_ person: Person, message: Data) -> Bool {
        let clientId = person.identifier
        let status = person == .Alice ? statusAlice : statusBob
        guard let _ = try? status?.decrypt(message, senderIdentifier: clientId) else {
            return true
        }
        status?.discardCache()
        return false
    }
    
    /// Checks if a message can be encrypted and successfully decrypted
    /// by the other person
    /// - note: it does commit the session cache
    @discardableResult func checkThatAMessageCanBeSent(_ from: Person, saveReceiverCache : Bool = true) -> Bool {
        let senderId = from.identifier
        let receiverId = from.other.identifier

        let status1 = from == .Alice ? statusAlice : statusBob
        let status2 = from == .Alice ? statusBob : statusAlice
        
        defer {
            self.recreateStatuses(only: from)
            if saveReceiverCache {
                self.recreateStatuses(only: from.other)
            }
        }
        
        let plainText = "निर्वाण".data(using: String.Encoding.utf8)!
        do {
            let cypherText = try status1?.encrypt(plainText, recipientIdentifier: receiverId)
            let decoded = try status2?.decrypt(cypherText!, senderIdentifier: senderId)
            return decoded == plainText
        } catch {
            return false
        }
    }
}
