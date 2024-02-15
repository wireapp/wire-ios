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
import WireCommonComponents

extension MFMailComposeViewController {

    func prefilledBody(withMessage message: String = "") -> String {
        let date = Date()
        let device = UIDevice.current.zm_model()

        var body = """
        --DO NOT EDIT--
        App Version: \(Bundle.main.appInfo.fullVersion)
        Bundle id: \(Bundle.main.bundleIdentifier ?? "-")
        Device: \(device)
        iOS version: \(UIDevice.current.systemVersion)
        Date: \(date.transportString())
        """

#if DATADOG_IMPORT
        // datadogId has always a value. NONE by default
        // display only when enabled
        if let datadogId = DatadogWrapper.shared?.datadogUserId {
            body.append("\nDatadog ID: \(datadogId)")
        }
#endif
        body.append("\n---------------\n")
        typealias l10n = L10n.Localizable.Self.Settings.TechnicalReport.MailBody
        let details = """
        \(l10n.firstline)

        - \(l10n.section1)


        - \(l10n.section2)
        \(message)

        - \(l10n.section3)


        """
        body.append("\n\(details)\n")
        return body
    }

    func attachLogs() async {
        defer {
            // because we don't rotate file for this one, we clean it once sent
            // this regenerated from os_log anyway
            if let url = LogFileDestination.main.log {
                try? FileManager.default.removeItem(at: url)
            }
        }
        // save current logs to file in order to send them
        await WireLogger.provider?.persist(fileDestination: LogFileDestination.main)

        for destination in LogFileDestination.allCases {
            if let data = FileManager.default.zipData(from: destination.log) {
                addAttachmentData(data, mimeType: "application/zip", fileName: "\(destination.filename).zip")
            } else {
                WireLogger.system.debug("no logs for WireLogger to send \(destination.filename)")
            }
        }
        

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
