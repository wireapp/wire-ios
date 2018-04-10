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

import XCTest
import WireCryptobox

class ChaCha20EncryptionTests: XCTestCase {
    
    var directoryURL: URL!
    
    override func setUp() {
        super.setUp()
        let docments = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        directoryURL = docments.appendingPathComponent("ChaCha20EncryptionTests")
        
        do {
            try FileManager.default.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Unable to create directory: \(error)")
        }
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: directoryURL)
        directoryURL = nil
        super.tearDown()
    }
    
    private func createTemporaryURL() -> URL {
        return directoryURL.appendingPathComponent(UUID().uuidString)
    }
    
    func encrypt(_ message: Data, key: ChaCha20Encryption.Key) throws -> Data {
        let inputStream = InputStream(data: message)
        var outputBuffer = Array<UInt8>(repeating: 0, count: 256)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 256)
        
        let bytesWritten = try ChaCha20Encryption.encrypt(input: inputStream, output: outputStream, key: key)
        
        return Data(bytes: outputBuffer.prefix(bytesWritten))
    }
    
    func decrypt(_ chipherMessage: Data, key: ChaCha20Encryption.Key) throws -> Data {
        var outputBuffer = Array<UInt8>(repeating: 0, count: 256)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 256)
        let inputStream = InputStream(data: chipherMessage)
        let decryptedBytes = try ChaCha20Encryption.decrypt(input: inputStream, output: outputStream, key: key)
        
        return Data(bytes: outputBuffer.prefix(decryptedBytes))
    }
    
    func encryptToURL(_ message: Data, key: ChaCha20Encryption.Key) throws -> URL {
        let inputURL = createTemporaryURL()
        let outputURL = createTemporaryURL()
        try message.write(to: inputURL)
        let inputStream = InputStream(url: inputURL)!
        let outputStream = OutputStream(url: outputURL, append: false)!
        try ChaCha20Encryption.encrypt(input: inputStream, output: outputStream, key: key)
        return outputURL
    }
    
    func decryptFromURL(_ url: URL, key: ChaCha20Encryption.Key, file: StaticString = #file, line: UInt = #line) throws -> Data {
        let outputURL = createTemporaryURL()
        let outputStream = OutputStream(url: outputURL, append: false)!
        let inputStream = InputStream(url: url)!
        let decryptedBytes = try ChaCha20Encryption.decrypt(input: inputStream, output: outputStream, key: key)
        XCTAssertGreaterThan(decryptedBytes, 0, file: file, line: line)
        return try Data(contentsOf: outputURL)
    }
    
    // MARK: - Encryption
    
    func testThatEncryptionAndDecryptionWorks() throws {
        
        // given
        let key = ChaCha20Encryption.Key()
        let message = "123456789"
        let messageData =  message.data(using: .utf8)!
        
        // when
        let encryptedMessage = try encrypt(messageData, key: key)
        let decryptedMessage = try decrypt(encryptedMessage, key: key)
        
        // then
        XCTAssertEqual(decryptedMessage, messageData)
    }
    
    func testThatEncryptionAndDecryptionWorksWithPassphrase() throws {
        
        // given
        let passphrase = "helloworld"
        let message = "123456789"
        let messageData =  message.data(using: .utf8)!
        
        // when
        let encryptedMessage = try encrypt(messageData, key: ChaCha20Encryption.Key(passphrase: passphrase)!)
        let decryptedMessage = try decrypt(encryptedMessage, key: ChaCha20Encryption.Key(passphrase: passphrase)!)
        
        // then
        XCTAssertEqual(decryptedMessage, messageData)
    }
    
    func testThatEncryptionAndDecryptionWorks_ToDisk() throws {
        
        // given
        let key = ChaCha20Encryption.Key()
        let message = "123456789"
        let messageData =  message.data(using: .utf8)!
        
        // when
        let encryptedDataURL = try encryptToURL(messageData, key: key)
        let decryptedMessage = try decryptFromURL(encryptedDataURL, key: key)
        
        // then
        XCTAssertEqual(decryptedMessage, messageData)
    }
    
    func testThatEncryptionAndDecryptionWorksWithPassphrase_ToDisk() throws {
        
        // given
        let passphrase = "helloworld"
        let message = "123456789"
        let messageData =  message.data(using: .utf8)!
        
        // when
        let encryptedDataURL = try encryptToURL(messageData, key: ChaCha20Encryption.Key(passphrase: passphrase)!)
        let decryptedMessage = try decryptFromURL(encryptedDataURL, key: ChaCha20Encryption.Key(passphrase: passphrase)!)
        
        // then
        XCTAssertEqual(decryptedMessage, messageData)
    }
    
    func testThatItThrowsWriteErrorWhenOutputStreamFailsWhileEncrypting() throws {
        
        // given
        let message = "123456789"
        let messageData =  message.data(using: .utf8)!
        let inputStream = InputStream(data: messageData)
        var outputBuffer = Array<UInt8>(repeating: 0, count: 1)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 1)
        let key = ChaCha20Encryption.Key()
        
        // then when
        do {
            try ChaCha20Encryption.encrypt(input: inputStream, output: outputStream, key: key)
        } catch ChaCha20Encryption.EncryptionError.writeError {
            return // success
        } catch {
            XCTFail()
        }
    }
    
    // MARK: - Decryption
    
    func testThatItThrowsReadErrorOnEmptyData() {
        
        // given
        let key = ChaCha20Encryption.Key()
        let malformedMessageData =  "".data(using: .utf8)!
        var outputBuffer = Array<UInt8>(repeating: 0, count: 256)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 256)
        let inputStream = InputStream(data: malformedMessageData)
        
        // then when
        do {
            try ChaCha20Encryption.decrypt(input: inputStream, output: outputStream, key: key)
        } catch ChaCha20Encryption.EncryptionError.readError {
            return // success
        } catch {
            XCTFail()
        }
        
        XCTFail()
    }
    
    func testThatItThrowsDecryptionFailedOnBadData() {
        
        // given
        let key = ChaCha20Encryption.Key()
        let malformedMessageData =  "malformed12345678901234567890123456789012345678901234567890".data(using: .utf8)!
        var outputBuffer = Array<UInt8>(repeating: 0, count: 256)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 256)
        let inputStream = InputStream(data: malformedMessageData)
        
        // then when
        do {
            try ChaCha20Encryption.decrypt(input: inputStream, output: outputStream, key: key)
        } catch ChaCha20Encryption.EncryptionError.decryptionFailed {
            return // success
        } catch {
            XCTFail()
        }
        
        XCTFail()
    }
    
    func testThatItThrowsWriteErrorWhenOutputStreamFailsWhileDecrypting() {
        
        // given
        let key = ChaCha20Encryption.Key()
        let message = "123456789".data(using: .utf8)!
        let encryptedData = try! encrypt(message, key: key)
        
        let inputStream = InputStream(data: encryptedData)
        var outputBuffer = Array<UInt8>(repeating: 0, count: 1)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 1)
        
        // then when
        do {
            try ChaCha20Encryption.decrypt(input: inputStream, output: outputStream, key: key)
        } catch ChaCha20Encryption.EncryptionError.writeError {
            return // success
        } catch {
            XCTFail()
        }
    }
    
}
