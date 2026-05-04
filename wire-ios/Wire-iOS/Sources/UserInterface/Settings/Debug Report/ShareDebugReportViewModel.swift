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

import UIKit
import WireLogging
import WireReusableUIComponents

@MainActor
final class ShareDebugReportViewModel {

    private let createReport: CreateDebugReportUseCaseProtocol
    private let shareReport: ShareDebugReportUseCaseProtocol

    init(
        createReport: CreateDebugReportUseCaseProtocol = CreateDebugReportUseCase(),
        shareReport: ShareDebugReportUseCaseProtocol
    ) {
        self.createReport = createReport
        self.shareReport = shareReport
    }

    func share(from viewController: UIViewController) async {
        let indicator = BlockingActivityIndicator(
            view: viewController.view,
            accessibilityAnnouncement: nil
        )
        indicator.start(text: L10n.Localizable.Self.Settings.ShareDebugReport.creatingReport)

        do {
            let url = try await createReport.invoke()
            indicator.stop()
            await shareReport.invoke(logFileURL: url, from: viewController)
        } catch {
            indicator.stop()
            WireLogger.system.error("failed to create debug report: \(error)")
        }
    }
}
