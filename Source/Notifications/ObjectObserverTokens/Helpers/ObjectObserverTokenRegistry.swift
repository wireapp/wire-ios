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



public protocol RegisteredObjectObserverToken : NSObjectProtocol {
    var object: NSObject { get }
}



/// Tokens can be registered for their object. And a closure can be applied to all tokens for a given object.
public final class ObjectObserverTokenRegistry {
    
    public typealias Token = RegisteredObjectObserverToken
    
    public func registerToken(_ token: Token) -> Void {
        registeredTokens.append(token)
    }
    public func unregisterToken(_ token: Token) -> Void {
        for idx in registeredTokens.indices {
            if registeredTokens[idx] === token {
                registeredTokens.remove(at: idx)
                return
            }
        }
    }
    
    var registeredTokens: [Token] = []
    
    public init() {
    }
    
    /// Will apply then given function to all tokens for the given object.
    public func applyTokensForObject<T: Token>(_ object: NSObject, function: (T)->Void) {
        for token in self.registeredTokens {
            if let t = token as? T {
                if t.object === object {
                    function(t)
                }
            }
        }
    }
}
