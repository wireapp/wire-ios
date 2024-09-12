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

    func attachLogs() {
        do {
            let data = try LogFilesProvider().generateLogFilesData()
            addAttachmentData(data, mimeType: "application/zip", fileName: "logs.zip")
        } catch {
            WireLogger.system.debug("no logs for WireLogger to send: \(String(describing: error))")
        }
    }
}
