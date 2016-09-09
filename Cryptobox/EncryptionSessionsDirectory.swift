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

@objc enum EncryptionSessionError : Int {
    
    case unknown, encryptionFailed, decryptionFailed
    
    internal var userInfo : [String : AnyObject] {
        var info : String
        
        switch self {
        case .unknown:
            info = "Unknown EncryptionSessionError"
        case .encryptionFailed:
            info = "Encryption Failed"
        case .decryptionFailed:
            info = "Decryption Failed"
        }
        
        return [kCFErrorLocalizedDescriptionKey as String : info as AnyObject]
    }
    
    var error : NSError {
        return NSError(domain: "EncryptionSessionsDirectoryDomain", code: rawValue, userInfo: userInfo)
    }
    
}

class _CBoxSession : PointerWrapper {}

/// An encryption state that is usable to encrypt/decrypt messages
/// It maintains an in-memory cache of encryption sessions with other clients
/// that is persisted to disk as soon as it is deallocated.
public final class EncryptionSessionsDirectory : NSObject {
    
    /// Used for testing only. If set to true,
    /// will not try to validate with the generating context
    var debug_disableContextValidityCheck = false
    
    /// Context that created this status
    fileprivate weak var generatingContext: EncryptionContext!
    
    /// Local fingerprint
    public var localFingerprint : Data
    
    /// Cache of transient sessions, indexed by client ID.
    /// Transient sessions are session that are (potentially) modified in memory
    /// and not yet committed to disk. When trying to load a session,
    /// and that session is already in the list of transient sessions,
    /// the transient session will be returned without any loading
    /// occurring. As soon as a session is saved, it is removed from the cache.
    ///
    /// - note: This is an optimization: instead of loading, decrypting,
    /// saving, unloading every time, if the same session is reused within
    /// the same execution block, we don't need to spend time reading
    /// and writing to disk every time we use the session, we can just
    /// load once and save once at the end.
    fileprivate var pendingSessionsCache : [String : EncryptionSession] = [:]
    
    init(generatingContext: EncryptionContext) {
        self.generatingContext = generatingContext
        self.localFingerprint = generatingContext.implementation.localFingerprint
        super.init()
    }
    
    /// The underlying implementation of the box
    var box : _CBox {
        return self.generatingContext!.implementation
    }
    
    /// Checks whether self is in a valid state, i.e. the generating context is still open and
    /// this is the current status. If not, it means that we are using this status after
    /// the context was done using this status.
    /// Will assert if this is the case.
    fileprivate func validateContext() -> EncryptionContext {
        guard self.debug_disableContextValidityCheck || self.generatingContext.currentSessionsDirectory === self else {
            // If you hit this line, check if the status was stored in a variable for later use,
            // or if it was used from different threads - it should never be.
            fatalError("Using encryption status outside of a context")
        }
        return self.generatingContext!
    }
    
    deinit {
        self.commitCache()
    }
}

// MARK: - Accessing sessions
extension EncryptionSessionsDirectory {
    
    /// Creates a session to a client using a prekey of that client
    /// The session is not saved to disk until the cache is committed
    /// - throws: CryptoBox error in case of lower-level error
    public func createClientSession(_ clientId: String, base64PreKeyString: String) throws {
        
        // validate
        guard let prekeyData = Data(base64Encoded: base64PreKeyString, options: []) else {
            fatalError("String is not base64 encoded")
        }
        let context = self.validateContext()

        // check if pre-existing
        if clientSessionById(clientId) != nil {
            return
        }
        
        // init
        let cbsession = _CBoxSession()
        let result = prekeyData.withUnsafeBytes { (prekeyDataPointer : UnsafePointer<UInt8>) -> CBoxResult in
            cbox_session_init_from_prekey(context.implementation.ptr,
                                          clientId,
                                          prekeyDataPointer,
                                          prekeyData.count,
                                          &cbsession.ptr)
        }
        
        guard result == CBOX_SUCCESS else {
            throw CryptoboxError(rawValue: result.rawValue)!
        }
        let session = EncryptionSession(id: clientId,
                                        session: cbsession,
                                        requiresSave: true)
        self.pendingSessionsCache[clientId] = session
    }
    
    /// Creates a session to a client using a prekey message from that client
    /// The session is not saved to disk until the cache is committed
    /// - returns: the plaintext
    /// - throws: CryptoBox error in case of lower-level error
    public func createClientSessionAndReturnPlaintext(_ clientId: String, prekeyMessage: Data) throws -> Data {
        let context = self.validateContext()
        let cbsession = _CBoxSession()
        var plainTextBacking : OpaquePointer? = nil
        
        let result = prekeyMessage.withUnsafeBytes { (prekeyMessagePointer : UnsafePointer<UInt8>) -> CBoxResult in
            cbox_session_init_from_message(context.implementation.ptr,
                                           clientId,
                                           prekeyMessagePointer,
                                           prekeyMessage.count,
                                           &cbsession.ptr,
                                           &plainTextBacking)
        }
        
        guard result == CBOX_SUCCESS else {
            throw CryptoboxError(rawValue: result.rawValue)!
        }
        let plainText = Data.moveFromCBoxVector(plainTextBacking)!
        let session = EncryptionSession(id: clientId,
                                        session: cbsession,
                                        requiresSave: true)
        self.pendingSessionsCache[clientId] = session
        return plainText
    }
    
    /// Deletes a session with a client
    public func delete(_ clientId: String) {
        let context = self.validateContext()
        self.discardFromCache(clientId)
        let result = cbox_session_delete(context.implementation.ptr, clientId)
        guard result == CBOX_SUCCESS else {
            fatalError("Error in deletion in cbox: \(result)")
        }
    }
}

// MARK: - Prekeys
extension EncryptionSessionsDirectory {
    
    /// Generates one prekey of the given ID. If the prekey exists already,
    /// it will replace that prekey
    /// - returns: base 64 encoded string
    public func generatePrekey(_ id: UInt16) throws -> String {
        guard id <= CBOX_LAST_PREKEY_ID else {
            // this should never happen, as CBOX_LAST_PREKEY_ID is UInt16.max
            fatalError("Prekey out of bound")
        }
        var vectorBacking : OpaquePointer?
        let context = self.validateContext()
        let result = cbox_new_prekey(context.implementation.ptr, id, &vectorBacking)
        let prekey = Data.moveFromCBoxVector(vectorBacking)
        
        guard result == CBOX_SUCCESS else {
            throw CryptoboxError(rawValue: result.rawValue)!
        }
        
        return prekey!.base64EncodedString(options: [])
    }
    
    /// Generates the last prekey. If the prekey exists already,
    /// it will replace that prekey
    public func generateLastPrekey() throws -> String {
        return try generatePrekey(CBOX_LAST_PREKEY_ID)
    }
    
    /// Generates prekeys from a range of IDs. If prekeys with those IDs exist already,
    /// they will be replaced
    public func generatePrekeys(_ range: CountableRange<UInt16>) throws -> [(id: UInt16, prekey: String)] {
        return try range.map {
            let prekey = try self.generatePrekey($0)
            return (id: $0, prekey: prekey)
        }
    }
    
    /// Generates prekeys from a range of IDs. If prekeys with those IDs exist already,
    /// they will be replaced
    /// This method wraps the Swift only method generatePrekeys(range: Range<UInt16>) for objC interoparability
    @objc public func generatePrekeys(_ nsRange: NSRange) throws -> [[String : AnyObject]] {
        let prekeys = try generatePrekeys(UInt16(nsRange.location)..<UInt16(nsRange.length))
        return prekeys.map{ ["id": NSNumber(value: $0.id as UInt16), "prekey": $0.prekey as AnyObject] }
    }
}

// MARK: - Fingerprint
extension _CBox {
    
    /// Local fingerprint
    fileprivate var localFingerprint : Data {
        var vectorBacking : OpaquePointer? = nil
        let result = cbox_fingerprint_local(self.ptr, &vectorBacking)
        guard result == CBOX_SUCCESS else {
            fatalError("Can't get local fingerprint") // this is so rare, that we don't even throw
        }
        return Data.moveFromCBoxVector(vectorBacking)!
    }
}

extension EncryptionSessionsDirectory {
    
    /// Returns the remote fingerprint of a client session
    public func fingerprintForClient(_ clientId: String) -> Data? {
        guard let session = self.clientSessionById(clientId) else {
            return nil
        }
        return session.remoteFingerprint
    }
}


// MARK: - Sessions cache management
extension EncryptionSessionsDirectory {
    
    /// Returns an existing session for a client
    /// - returns: a session if it exists, or nil if not there
    fileprivate func clientSessionById(_ clientId: String) -> EncryptionSession? {
        let context = self.validateContext()
        
        // check cache
        if let transientSession = self.pendingSessionsCache[clientId] {
            return transientSession
        }
        
        let cbsession = _CBoxSession()
        let result = cbox_session_load(context.implementation.ptr, clientId, &cbsession.ptr)
        switch(result) {
        case CBOX_SESSION_NOT_FOUND:
            return nil
        case CBOX_SUCCESS:
            let session = EncryptionSession(id: clientId,
                                            session: cbsession,
                                            requiresSave: false)
            self.pendingSessionsCache[clientId] = session
            return session
        default:
            fatalError("Error in loading from cbox: \(result)")
        }
    }
    
    /// Returns true if there is an existing session for this client ID
    public func hasSessionForID(_ clientId: String) -> Bool {
        return (clientSessionById(clientId) != nil)
    }
    
    /// Closes all transient sessions without saving them
    public func discardCache() {
        self.pendingSessionsCache = [:]
    }
    
    /// Save and unload all transient sessions
    fileprivate func commitCache() {
        for (_, session) in self.pendingSessionsCache {
            session.save(self.box)
        }
        discardCache()
    }
    
    /// Closes a transient session. Any unsaved change will be lost
    fileprivate func discardFromCache(_ clientId: String) {
        self.pendingSessionsCache.removeValue(forKey: clientId)
    }

    /// Saves the cached session for a client and removes it from the cache
    fileprivate func saveSession(_ clientId: String) {
        guard let session = pendingSessionsCache[clientId] else {
            return
        }
        session.save(self.box)
        discardFromCache(clientId)
    }
}

/// A cryptographic session used to encrypt/decrypt data send to and received from
/// another client
/// - note: This class is private because we want to make sure that no one can use
/// sessions outside of a status, that only dirty sessions are kept in memory, and
/// that sessions are unloaded as soon as possible, and that sessions are closed as soon
/// as they are unloaded.
/// We let the status manages closing sessions as there is no
/// other easy way to enforce (other than asserting) that we don't use a session to encrypt/decrypt
/// after it has been closed, and there is no easy way to ensure that sessions are always closed.
/// By hiding the implementation inside this file, only code in this file has the chance to screw up!
private class EncryptionSession {
    
    /// Whether this session has changes that require saving
    var hasChanges : Bool
    
    /// client ID
    let id: String
    
    /// Underlying C-style implementation
    let implementation: _CBoxSession
    
    /// The fingerpint of the client
    let remoteFingerprint: Data
    
    /// Creates a session from a C-level session pointer
    /// - parameter id: id of the client
    /// - parameter requiresSave: if true, mark this session as having pending changes to save
    init(id: String,
         session: _CBoxSession,
         requiresSave: Bool
        ) {
        self.id = id
        self.implementation = session
        self.remoteFingerprint = session.remoteFingerprint
        self.hasChanges = requiresSave
    }
    
    /// Closes the session in CBox
    fileprivate func closeInCryptobox() {
        cbox_session_close(self.implementation.ptr)
    }
    
    /// Save the session to disk
    fileprivate func save(_ cryptobox: _CBox) {
        if self.hasChanges {
            let result = cbox_session_save(cryptobox.ptr, self.implementation.ptr)
            switch(result) {
            case CBOX_SUCCESS:
                return
            default:
                fatalError("Can't save session: error \(result)")
            }
        }
    }
    
    deinit {
        closeInCryptobox()
    }
}

// MARK: - Encryption and decryption
extension EncryptionSessionsDirectory {
    
    /// Encrypts data for a client
    /// It immediately saves the session
    /// - returns: nil if there is no session with that client
    @objc public func encrypt(_ plainText: Data, recipientClientId: String) throws -> Data {
        _ = self.validateContext()
        guard let session = self.clientSessionById(recipientClientId) else {
            throw EncryptionSessionError.encryptionFailed.error
        }
        let cypherText = try session.encrypt(plainText)
        self.saveSession(recipientClientId)
        return cypherText
    }
    
    /// Decrypts data from a client
    /// The session is not saved to disk until the cache is committed
    /// - returns: nil if there is no session with that client
    @objc public func decrypt(_ cypherText: Data, senderClientId: String) throws -> Data {
        _ = self.validateContext()
        guard let session = self.clientSessionById(senderClientId) else {
            throw EncryptionSessionError.decryptionFailed.error
        }
        return try session.decrypt(cypherText)
    }
}


extension EncryptionSession {
    
    /// Decrypts data using the session. This function modifies the session
    /// and it should be saved later
    fileprivate func decrypt(_ cypher: Data) throws -> Data {
        var vectorBacking : OpaquePointer? = nil

        let result = cypher.withUnsafeBytes { (cypherPointer: UnsafePointer<UInt8>) -> CBoxResult in
            cbox_decrypt(self.implementation.ptr,
                         cypherPointer,
                         cypher.count,
                         &vectorBacking)
        }
        
        guard result == CBOX_SUCCESS else {
            throw CryptoboxError(rawValue: result.rawValue)!
        }
        self.hasChanges = true
        return Data.moveFromCBoxVector(vectorBacking)!
    }
    
    /// Encrypts data using the session. This function modifies the session
    /// and it should be saved later
    fileprivate func encrypt(_ plainText: Data) throws -> Data {
        var vectorBacking : OpaquePointer? = nil
        
        let result = plainText.withUnsafeBytes { (plainTextPointer: UnsafePointer<UInt8>) -> CBoxResult in
            cbox_encrypt(self.implementation.ptr,
                         plainTextPointer,
                         plainText.count,
                         &vectorBacking)
        }
        
        guard result == CBOX_SUCCESS else {
            throw CryptoboxError(rawValue: result.rawValue)!
        }
        self.hasChanges = true
        return Data.moveFromCBoxVector(vectorBacking)!
    }
}

// MARK: - Fingerprint
extension _CBoxSession {
    
    /// Returns the remote fingerprint associated with a session
    fileprivate var remoteFingerprint : Data {
        var backingVector : OpaquePointer? = nil
        let result = cbox_fingerprint_remote(self.ptr, &backingVector)
        guard result == CBOX_SUCCESS else {
            fatalError("Can't access remote fingerprint of session")
        }
        return Data.moveFromCBoxVector(backingVector)!
    }
}
