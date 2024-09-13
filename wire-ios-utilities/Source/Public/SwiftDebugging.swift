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

public enum SwiftDebugging {
    public static func address(_ object: AnyObject) -> Int {
        unsafeBitCast(object, to: Int.self)
    }

    public static func pointerDescription(_ object: NSManagedObject) -> String {
        "<\(type(of: object)) 0x\(String(address(object), radix: 16))>"
    }

    public static func sequenceDescription(_ sequence: AnySequence<some Any>) -> String {
        let formattedSequence = sequence
            .map { shortDescription($0) }
            .joined(separator: ", ")
        return "( \(formattedSequence) )"
    }

    public static func sequenceDescription(_ sequence: some Sequence) -> String {
        let formattedSequence = sequence
            .map { Self.shortDescription($0) }
            .joined(separator: ", ")
        return "( \(formattedSequence) )"
    }

    public static func shortDescription(_ value: Any) -> String {
        switch value {
        case let managedObject as NSManagedObject:
            pointerDescription(managedObject)
        case let collection as AnySequence<Any>:
            sequenceDescription(collection)
        default:
            "\(value)"
        }
    }
}
