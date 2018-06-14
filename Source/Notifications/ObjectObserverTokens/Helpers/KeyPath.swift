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


/// A key path (as in key-value-coding).
public final class KeyPath : Hashable {
    
    public let rawValue: String
    public let count: Int
    public let hashValue: Int
    
    static private var KeyPathCache : [String : KeyPath] = [:]
    
    public class func keyPathForString(_ string: String) -> KeyPath {
        
        if let keyPath = KeyPathCache[string] {
            return keyPath
        }
        else {
            let instance = KeyPath(string)
            KeyPathCache[string] = instance
            return instance
        }
    }
    
    private init(_ s: String) {
        rawValue = s
        count = rawValue.filter {
            $0 == "."
        }.count + 1
        hashValue = rawValue.hashValue
    }
    
    public var isPath: Bool {
        return 1 < count
    }

    public lazy var decompose : (head: KeyPath, tail: KeyPath?)? = {
        if 1 <= self.count {
            if let i = self.rawValue.index(of: ".") {
                let head = self.rawValue[..<i]
                var tail : KeyPath?
                if i != self.rawValue.endIndex {
                    let nextIndex = self.rawValue.index(after: i)
                    let result = self.rawValue[nextIndex...]
                    tail = KeyPath.keyPathForString(String(result))
                }
                return (KeyPath.keyPathForString(String(head)), tail)
            }
            return (self, nil)
        }
        return nil
    }()
}

extension KeyPath : Equatable {
}
public func ==(lhs: KeyPath, rhs: KeyPath) -> Bool {
    // We store the hash which makes comparison very cheap.
    return (lhs.hashValue == rhs.hashValue) && (lhs.rawValue == rhs.rawValue)
}

extension KeyPath : CustomDebugStringConvertible {
    public var description: String {
        return rawValue
    }
    public var debugDescription: String {
        return rawValue
    }
}
