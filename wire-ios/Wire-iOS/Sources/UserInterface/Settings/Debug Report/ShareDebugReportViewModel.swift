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

import Combine
import Foundation
import MessageUI
import WireLogging
import WireMainNavigationUI
import WireSyncEngine

@MainActor
protocol ShareDebugReportViewModelOutput: AnyObject {
    func shareDebugReportViewModelDidStartCreatingReport(_ viewModel: ShareDebugReportViewModel)
    func shareDebugReportViewModelDidFinishCreatingReport(_ viewModel: ShareDebugReportViewModel)
    func shareDebugReportViewModel(_ viewModel: ShareDebugReportViewModel, presentWireReportAt url: URL) async
    func shareDebugReportViewModel(_ viewModel: ShareDebugReportViewModel, presentActivityReportAt url: URL) async
}

@MainActor
final class ShareDebugReportViewModel: ObservableObject {

    @Published var mailComposeItem: MailComposeItem?

    let canShareViaWire: Bool
    let canSendEmail: Bool

    weak var output: ShareDebugReportViewModelOutput?

    private let mailRecipient: String
    private let createReport: CreateDebugReportUseCaseProtocol

    init(
        userSession: UserSession?,
        mainCoordinator: (any MainCoordinatorProtocol)?,
        selfUserID: UUID? = nil,
        mailRecipient: String = WireEmail.shared.supportEmail,
        createReport: CreateDebugReportUseCaseProtocol? = nil
    ) {
        self.mailRecipient = mailRecipient
        self.createReport = createReport ?? CreateDebugReportUseCase(selfUserID: selfUserID)
        self.canShareViaWire = userSession != nil && mainCoordinator != nil
        self.canSendEmail = MFMailComposeViewController.canSendMail()
    }

    func shareViaWire() async {
        guard canShareViaWire else { return }
        await withReport { [weak self] url in
            guard let self else { return }
            await output?.shareDebugReportViewModel(self, presentWireReportAt: url)
        }
    }

    func shareViaActivitySheet() async {
        await withReport { [weak self] url in
            guard let self else { return }
            await output?.shareDebugReportViewModel(self, presentActivityReportAt: url)
        }
    }

    func sendEmail() async {
        output?.shareDebugReportViewModelDidStartCreatingReport(self)
        do {
            let data = try await createReport.invokeData()
            output?.shareDebugReportViewModelDidFinishCreatingReport(self)
            mailComposeItem = MailComposeItem(
                recipient: mailRecipient,
                subject: L10n.Localizable.Self.Settings.TechnicalReport.Mail.subject,
                messageBody: MFMailComposeViewController.prefilledBody(),
                attachmentData: data
            )
        } catch {
            output?.shareDebugReportViewModelDidFinishCreatingReport(self)
            WireLogger.system.error("failed to create debug report: \(error)")
        }
    }

    // MARK: - Private

    private func withReport(
        then action: @escaping @MainActor (URL) async -> Void
    ) async {
        output?.shareDebugReportViewModelDidStartCreatingReport(self)
        do {
            let url = try await createReport.invoke()
            output?.shareDebugReportViewModelDidFinishCreatingReport(self)
            await action(url)
        } catch {
            output?.shareDebugReportViewModelDidFinishCreatingReport(self)
            WireLogger.system.error("failed to create debug report: \(error)")
        }
    }
}
