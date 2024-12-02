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

/*
 - injectable logger (protocol)
 - interpolation with strict types (stringinterpolation should trigger warning or error)
 - force public flag
 - check the current attributes
 - additional info
 - ?
 */


// public struct WireLoggerInterpolation: ExpressibleByStringInterpolation {
//    public init(stringInterpolation: DefaultStringInterpolation) {
//    }
// }

public struct MyStruct {
    public let id: Int
    public let name: String
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

func something() {
    let myStruct = MyStruct(id: 42, name: "Alice")
    let anotherStruct = MyStruct(id: 7, name: "Bob")

    let myString: WireLogMessage = "This is \(myStruct), and here is \(anotherStruct)."
    print(myString.valuee)
    // Output: This is MyStruct(id: 42, name: Alice), and here is MyStruct(id: 7, name: Bob).
}
