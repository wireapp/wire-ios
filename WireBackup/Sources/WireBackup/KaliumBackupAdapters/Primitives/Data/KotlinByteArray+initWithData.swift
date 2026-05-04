//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import KaliumBackup

extension KotlinByteArray {

    convenience init(_ data: Data) {
        let bytes = [UInt8](data)
        let intArray = bytes.map(Int8.init(bitPattern:))
        self.init(size: Int32(bytes.count))
        for (index, element) in intArray.enumerated() {
            set(index: Int32(index), value: element)
        }
    }

}
