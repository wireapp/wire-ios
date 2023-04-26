//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import UIKit

class FastLogin {
    private let name: String

    private var sourcePath: String? {
        guard let path = Bundle.main.path(forResource: name, ofType: "plist") else { return nil }
        return path
    }

    private var destPath: String? {
        guard sourcePath != nil else { return nil }
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return (dir as NSString).appendingPathComponent("\(name).plist")
    }

    // MARK: - Lifecycle

    required init?(name: String) {
        self.name = name

        let fileManager = FileManager.default

        guard let source = sourcePath else { return nil }
        guard let destination = destPath else { return nil }
        guard fileManager.fileExists(atPath: source) else { return nil }

        if !fileManager.contentsEqual(atPath: source, andPath: destination) {
            if !fileManager.fileExists(atPath: destination) {
                do {
                    try fileManager.copyItem(atPath: source, toPath: destination)
                } catch let error as NSError {
                    print("Unable to copy file. ERROR: \(error.localizedDescription)")
                    return nil
                }
            }
        }
    }

    // MARK: - Helper Methods

    func getValuesInPlistFile() -> Dictionary<String, AnyObject>? {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: destPath!) {
            guard let dict = NSDictionary(contentsOfFile: destPath!) as? Dictionary<String, AnyObject> else { return nil }
            return dict
        } else {
            return nil
        }
    }

    func addValuesToPlistFile(userDict:NSDictionary) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destPath!) {
            if !userDict.write(toFile: destPath!, atomically: false) {
                print("Plist file not written successfully.")
            }
        }
        else {
            print("Not able to write")
        }
    }
}
