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
import Swift

/// START https://gist.github.com/anonymous/9bb5f5d9f6918b1482b6
/// Taken from that gist & slightly adapted.
public struct SetGenerator<Element: Hashable>: IteratorProtocol {
    var dictGenerator: DictionaryIterator<Element, Void>

    public init(_ d: [Element: Void]) {
        dictGenerator = d.makeIterator()
    }

    public mutating func next() -> Element? {
        if let tuple = dictGenerator.next() {
            let (k, _) = tuple
            return k
        } else {
            return nil
        }
    }
}
