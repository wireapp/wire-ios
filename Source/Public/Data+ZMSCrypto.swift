//
//  Data+ZMSCrypto.swift
//  ZMUtilities
//
//  Created by Mihail Gerasimenko on 9/9/16.
//
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
