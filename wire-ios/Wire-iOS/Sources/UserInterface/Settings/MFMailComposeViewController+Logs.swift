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

import Foundation
import MessageUI
import WireCommonComponents
import WireSystem

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

        if let datadogUserIdentifier = WireAnalytics.Datadog.userIdentifier {
            // display only when enabled
            body.append("\nDatadog ID: \(datadogUserIdentifier)")
        }

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

        var logFiles = WireLogger.provider?.logFiles ?? []
        logFiles.append(contentsOf: ZMSLog.pathsForExistingLogs)

        if let data = FileManager.default.zipData(from: logFiles) {
            addAttachmentData(data, mimeType: "application/zip", fileName: "logs.zip")
        } else {
            WireLogger.system.debug("no logs for WireLogger to send \(logFiles.description)")
        }
    }
}
