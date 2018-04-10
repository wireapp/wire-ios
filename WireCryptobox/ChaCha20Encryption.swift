//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public final class ChaCha20Encryption {
    
    private static let bufferSize = 1024 * 1024
    
    public enum EncryptionError: Error {
        /// Couldn't read  corrupt message header
        case malformedHeader
        /// Encryption failed
        case encryptionFailed
        /// Decryption failed to incorrect key, malformed message
        case decryptionFailed
        /// Failure reading input stream
        case readError(Error)
        /// Failure writing to output stream
        case writeError(Error)
        /// Stream end was reached while expecting more data
        case unexpectedStreamEnd
        /// Unknown error
        case unknown
    }
    
    /// ChaCha20 Key
    public struct Key {
        fileprivate static let salt = "WVBPkDGfcijYPCcduAnkxBdBuMNbRQkB"
        fileprivate let buffer: Array<UInt8>
        
        /// Generate a key
        public init() {
            var buffer = Array<UInt8>(repeating: 0, count: Int(crypto_secretstream_xchacha20poly1305_KEYBYTES))
            crypto_secretstream_xchacha20poly1305_keygen(&buffer)
            self.buffer = buffer
        }
        
        /// Generate a key from a passphrase.
        /// - passphrase: string which is used to derive the key
        ///
        /// NOTE: this can fail if the system runs out of memory.
        public init?(passphrase: String) {
            var buffer = Array<UInt8>(repeating: 0, count: Int(crypto_secretstream_xchacha20poly1305_KEYBYTES))
            
            guard crypto_pwhash(&buffer,
                                UInt64(crypto_secretstream_xchacha20poly1305_KEYBYTES),
                                passphrase,
                                UInt64(passphrase.lengthOfBytes(using: .utf8)),
                                Key.salt,
                                UInt64(crypto_pwhash_OPSLIMIT_MODERATE),
                                Int(crypto_pwhash_MEMLIMIT_MODERATE),
                                crypto_pwhash_ALG_DEFAULT) == 0 else {
                                    return nil
            }
            
            self.buffer = buffer
        }
    }
    
    /// Encrypts an input stream using xChaCha20
    /// - input: plaintext input stream
    /// - output: decrypted output stream
    ///
    /// - Throws: Stream errors.
    /// - Returns: number of encrypted bytes written to the output stream
    @discardableResult
    public static func encrypt(input: InputStream, output: OutputStream, key: Key) throws -> Int {
        input.open()
        output.open()
        
        defer {
            input.close()
            output.close()
        }

        var header = Array<UInt8>(repeating: 0, count: Int(crypto_secretstream_xchacha20poly1305_HEADERBYTES))
        var state = crypto_secretstream_xchacha20poly1305_state()
        
        guard crypto_secretstream_xchacha20poly1305_init_push(&state, &header, key.buffer) == 0 else {
            throw EncryptionError.encryptionFailed
        }
        
        var messageBuffer = Array<UInt8>(repeating: 0, count: bufferSize)
        var messageBufferReadAhead = Array<UInt8>(repeating: 0, count: bufferSize)
        
        let cipherBufferSize = bufferSize + Int(crypto_secretstream_xchacha20poly1305_ABYTES)
        var cipherBuffer = Array<UInt8>(repeating: 0, count: cipherBufferSize)
        
        var totalBytesWritten = 0
        var bytesWritten = -1
        var bytesRead = -1
        var bytesReadReadAhead = -1
        
        bytesWritten = output.write(header, maxLength: Int(crypto_secretstream_xchacha20poly1305_HEADERBYTES))
        totalBytesWritten += bytesWritten
        
        guard bytesWritten > 0 else {
            throw EncryptionError.writeError(output.streamError ?? EncryptionError.unexpectedStreamEnd)
        }
        
        repeat {
            if bytesRead < 0 {
                bytesRead = input.read(&messageBuffer, maxLength: bufferSize)
                if let error = input.streamError {
                    throw EncryptionError.readError(error)
                }
            } else {
                (bytesRead, messageBuffer) = (bytesReadReadAhead, messageBufferReadAhead)
            }
            
            bytesReadReadAhead = input.read(&messageBufferReadAhead, maxLength: bufferSize)
            
            guard bytesRead > 0 else { break }
            
            let messageLength: UInt64 = UInt64(bytesRead)
            var cipherLength: UInt64 = 0
            let tag: UInt8 = input.hasBytesAvailable ? 0 : UInt8(crypto_secretstream_xchacha20poly1305_TAG_FINAL)

            guard crypto_secretstream_xchacha20poly1305_push(&state, &cipherBuffer, &cipherLength, messageBuffer, messageLength, nil, 0, tag) == 0 else {
                throw EncryptionError.encryptionFailed
            }
            
            bytesWritten = output.write(cipherBuffer, maxLength: Int(cipherLength))
            if let error = output.streamError {
                throw EncryptionError.writeError(error)
            }
            
            totalBytesWritten += bytesWritten
        } while bytesRead > 0 && bytesWritten > 0
        
        if bytesRead < 0 {
            throw EncryptionError.readError(input.streamError ?? EncryptionError.unknown)
        }
        
        if bytesWritten < 0 {
            throw EncryptionError.writeError(output.streamError ?? EncryptionError.unknown)
        }
        
        return totalBytesWritten
    }
    
    /// Decrypts an input stream using xChaCha20
    /// - input: encrypted input stream
    /// - output: plaintext output stream
    ///
    /// - Throws: Stream errors and `malformedHeader` or `decryptionFailed` if decryption fails.
    /// - Returns: number of decrypted bytes written to the output stream.
    @discardableResult
    public static func decrypt(input: InputStream, output: OutputStream, key: Key) throws -> Int {
        input.open()
        output.open()
        
        defer {
            input.close()
            output.close()
        }
        
        var totalBytesWritten = 0
        var bytesWritten = -1
        var bytesRead = -1
        
        var state = crypto_secretstream_xchacha20poly1305_state()
        var header = Array<UInt8>(repeating: 0, count: Int(crypto_secretstream_xchacha20poly1305_HEADERBYTES))
        
        guard input.read(&header, maxLength: Int(crypto_secretstream_xchacha20poly1305_HEADERBYTES)) > 0  else {
            throw EncryptionError.readError(input.streamError ?? EncryptionError.unexpectedStreamEnd)
        }

        guard crypto_secretstream_xchacha20poly1305_init_pull(&state, header, key.buffer) == 0 else {
            throw EncryptionError.malformedHeader
        }
        
        var messageBuffer = Array<UInt8>(repeating: 0, count: bufferSize)
        let cipherBufferSize = bufferSize + Int(crypto_secretstream_xchacha20poly1305_ABYTES)
        var cipherBuffer = Array<UInt8>(repeating: 0, count: cipherBufferSize)
        var tag: UInt8 = 0
        
        repeat {
            bytesRead = input.read(&cipherBuffer, maxLength: cipherBufferSize)
            
            guard bytesRead > 0 else { continue }
            
            var messageLength: UInt64 = 0
            let cipherLength: UInt64 = UInt64(bytesRead)
            
            guard crypto_secretstream_xchacha20poly1305_pull(&state, &messageBuffer, &messageLength, &tag, cipherBuffer, cipherLength, nil, 0) == 0 else {
                throw EncryptionError.decryptionFailed
            }
            
            bytesWritten = output.write(messageBuffer, maxLength: Int(messageLength))
            if let error = output.streamError {
                throw EncryptionError.writeError(error)
            }

            totalBytesWritten += bytesWritten
            
            if tag == crypto_secretstream_xchacha20poly1305_TAG_FINAL {
                break // avoid reading data after final message is decrypted
            }
        } while bytesRead > 0 && bytesWritten > 0
        
        guard tag == crypto_secretstream_xchacha20poly1305_TAG_FINAL else {
            throw EncryptionError.decryptionFailed
        }
        
        if bytesRead < 0 {
            throw EncryptionError.readError(input.streamError ?? EncryptionError.unknown)
        }
        
        if bytesWritten < 0 {
            throw EncryptionError.writeError(output.streamError ?? EncryptionError.unknown)
        }
        
        return totalBytesWritten
    }
    
}
