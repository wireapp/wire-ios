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
import CoreData



final class ObserverTokenDirectory<I: ObjectChangeInfoProtocol, T: ObjectObserverTokenContainer, O: NSObject where O: ObjectInSnapshot> : NSObject {
    
    typealias TokenType = ObjectObserverToken<I, T>
    
    private var tokens: [NSObject : TokenType] = [:]
    
    /// Returns an existing token for the given object or stores and returns the token returned by the createBlock
    func tokenForObject(object: O, createBlock: () -> TokenType) -> TokenType {
        if let token = existingTokenForObject(object) {
            return token
        }
        let token = createBlock()
        self.tokens[object] = token
        return token
    }
    
    /// Returns an existing token for the given object or nil if there is no token in the directory
    func existingTokenForObject(object: O) -> TokenType? {
        return tokens[object]
    }
    
    func removeTokenForObject(object: NSObject) {
        self.tokens.removeValueForKey(object)
    }
    
	private override init() {
        super.init()
	}
	
    static func directoryInManagedObjectContext(moc: NSManagedObjectContext, keyForDirectoryInUserInfo: String) -> ObserverTokenDirectory<I, T, O> {
        let completeKey = "ZMObserverTokenDirectory-\(keyForDirectoryInUserInfo)"
        if let dir = moc.userInfo[completeKey] as? ObserverTokenDirectory<I, T, O> {
            return dir
        }
		let dir = ObserverTokenDirectory<I, T, O>()
		moc.userInfo[completeKey] = dir
        return dir
	}
}
