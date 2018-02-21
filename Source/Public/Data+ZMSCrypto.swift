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

// Mapping of @c NSData helper methods to Swift 3 @c Data. See original methods for description.
public extension Data {
    
    public func zmMD5Digest() -> Data {
        return (self as NSData).zmMD5Digest()
    }
    
    public func zmHMACSHA256Digest(key: Data) -> Data {
        return (self as NSData).zmHMACSHA256Digest(withKey: key)
    }
    
    public func zmHexEncodedString() -> String {
        let hexDigits = Array("0123456789abcdef".utf16)
        var characters : [unichar] = []
        characters.reserveCapacity(count * 2)
        
        self.forEach { byte in
            characters.append(hexDigits[Int(byte / 16)])
            characters.append(hexDigits[Int(byte % 16)])
        }
        
        return String(utf16CodeUnits: characters, count: characters.count)
    }
        
    public static func zmRandomSHA256Key() -> Data {
        return NSData.zmRandomSHA256Key()
    }
    
    public func zmSHA256Digest() -> Data {
        return (self as NSData).zmSHA256Digest()
    }
    
    public func base64String() -> String {
        return (self as NSData).base64String()
    }
    
    public func zmEncryptPrefixingIV(key: Data) -> Data {
        return (self as NSData).zmEncryptPrefixingIV(withKey: key)
    }
    
    public func zmDecryptPrefixedIV(key: Data) -> Data {
        return (self as NSData).zmDecryptPrefixedIV(withKey: key)
    }
    
    public func zmEncryptPrefixingPlainTextIV(key: Data) -> Data {
        return (self as NSData).zmEncryptPrefixingPlainTextIV(withKey: key)
    }
    
    public func zmDecryptPrefixedPlainTextIV(key: Data) -> Data? {
        return (self as NSData).zmDecryptPrefixedPlainTextIV(withKey: key)
    }
    
    public static func secureRandomData(length: UInt) -> Data {
        return NSData.secureRandomData(ofLength: length)
    }
    
    public static func randomEncryptionKey() -> Data {
        return NSData.randomEncryptionKey()
    }
    
}
