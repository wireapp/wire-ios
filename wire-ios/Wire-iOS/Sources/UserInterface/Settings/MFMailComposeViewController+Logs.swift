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
import MessageUI
import WireSystem

extension MFMailComposeViewController {

    func attachLogs() {

        if let crashLog = ZMLastAssertionFile(),
           FileManager.default.fileExists(atPath: crashLog.path) {
            do {
                let data = try Data(contentsOf: crashLog)
                addAttachmentData(data, mimeType: "text/plain", fileName: "last_crash.log")
            } catch {
                // ignore error for now, it's possible a file does not exist.
            }
        }

        if let currentLog = ZMSLog.currentZipLog {
            addAttachmentData(currentLog, mimeType: "application/zip", fileName: "current.log.zip")
        }

        ZMSLog.previousZipLogURLs.forEach { url in
            do {
                let data = try Data(contentsOf: url)
                addAttachmentData(data, mimeType: "application/zip", fileName: url.lastPathComponent)
            } catch {
                // ignore error for now, it's possible a file does not exist.
            }
        }
    }
}
