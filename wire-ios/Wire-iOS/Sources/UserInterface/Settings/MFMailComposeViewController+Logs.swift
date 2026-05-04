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
import MessageUI
import WireCommonComponents
import WireLogging
import WireSystem

extension MFMailComposeViewController {

    func prefilledBody(withMessage message: String = "") -> String {
        var body = """
        --DO NOT EDIT--
        \(LogFilesProvider().info())
        ---------------\n
        """

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
