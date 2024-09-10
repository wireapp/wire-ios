//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import CoreData
import Foundation

public struct SwiftDebugging {
    public static func address(_ object: AnyObject) -> Int {
        return unsafeBitCast(object, to: Int.self)
    }

    public static func pointerDescription(_ object: NSManagedObject) -> String {
        return "<\(type(of: object)) 0x\(String(self.address(object), radix: 16))>"
    }

    public static func sequenceDescription<T>(_ sequence: AnySequence<T>) -> String {
        let formattedSequence = sequence
            .map { shortDescription($0) }
            .joined(separator: ", ")
        return "( \(formattedSequence) )"
    }

    public static func sequenceDescription<S: Sequence>(_ sequence: S) -> String {
        let formattedSequence = sequence
            .map { Self.shortDescription($0) }
            .joined(separator: ", ")
        return "( \(formattedSequence) )"
    }

    public static func shortDescription(_ value: Any) -> String {
        switch value {
        case let managedObject as NSManagedObject:
            return pointerDescription(managedObject)
        case let collection as AnySequence<Any>:
            return sequenceDescription(collection)
        default:
            return "\(value)"
        }
    }
}
