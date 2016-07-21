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

public struct SwiftDebugging {
    
    public static func address(object: AnyObject) -> Int {
        return unsafeBitCast(object, Int.self)
    }
    
    public static func pointerDescription(object: NSManagedObject) -> String {
        return "<\(object.dynamicType) 0x\(String(self.address(object), radix:16))>"
    }
    
    public static func sequenceDescription<T>(sequence : AnySequence<T>) -> String {
        
        return "( " + sequence.map({ obj -> String in self.shortDescription(obj) + ", " })
            .reduce("", combine: +) + " )"
    }
    
    public static func sequenceDescription<S : SequenceType>(sequence : S) -> String {
        
        return "( " + sequence.map( { obj -> String in self.shortDescription(obj) + ", " })
            .reduce("", combine: +) + " )"
    }
    
    
    public static func shortDescription(value: Any) -> String {
        switch (value) {
        case let managedObject as NSManagedObject:
            return pointerDescription(managedObject)
        case let collection as AnySequence<Any>:
            return sequenceDescription(collection)
        default:
            return "\(value)"
        }
    }
}
