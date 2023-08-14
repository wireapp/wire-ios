//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

protocol PTMPFilesManager {
    func removeTemporaryData()
}

class TMPFilesManager: PTMPFilesManager {
    func removeTemporaryData() {
        guard let tmpDirectoryPath = URL(string: NSTemporaryDirectory()) else { return }
        let manager = FileManager.default
        try? manager
            .contentsOfDirectory(at: tmpDirectoryPath, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            .forEach { file in
                try? manager.removeItem(atPath: file.path)
            }
    }
}
