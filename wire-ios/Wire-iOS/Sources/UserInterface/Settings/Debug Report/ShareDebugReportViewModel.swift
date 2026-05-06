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

import MessageUI
import SwiftUI
import UIKit
import WireCommonComponents
import WireDataModel
import WireLogging
import WireMainNavigationUI
import WireReusableUIComponents
import WireSyncEngine

@MainActor
final class ShareDebugReportViewModel: ObservableObject {

    @Published var isShowingOptions = false
    @Published var mailComposeItem: MailComposeItem?

    let canShareViaWire: Bool
    let canSendEmail: Bool

    private let userSession: UserSession?
    private let mainCoordinator: (any MainCoordinatorProtocol)?
    private let mailRecipient: String
    private let createReport: CreateDebugReportUseCaseProtocol

    init(
        userSession: UserSession?,
        mainCoordinator: (any MainCoordinatorProtocol)?,
        selfUserID: UUID? = nil,
        mailRecipient: String = WireEmail.shared.supportEmail,
        createReport: CreateDebugReportUseCaseProtocol? = nil
    ) {
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.mailRecipient = mailRecipient
        self.createReport = createReport ?? CreateDebugReportUseCase(selfUserID: selfUserID)
        self.canShareViaWire = userSession != nil && mainCoordinator != nil
        self.canSendEmail = MFMailComposeViewController.canSendMail()
    }

    func showOptions() {
        isShowingOptions = true
    }

    func shareViaWire() async {
        guard let userSession, let mainCoordinator else { return }
        guard let viewController = topViewController() else { return }
        await withReport(from: viewController) { url in
            let shareFile = ShareFileUseCase(contextProvider: userSession.contextProvider)
            let fetchConversations = FetchShareableConversationsUseCase(contextProvider: userSession.contextProvider)
            let conversations = fetchConversations.invoke()
            let metadata = await FileMetaDataGenerator().metadataForFile(at: url)
            let report = ShareableDebugReport(logFileMetadata: metadata, shareFile: shareFile)
            let shareVC = ShareViewController<ZMConversation, ShareableDebugReport>(
                shareable: report,
                destinations: conversations,
                showPreview: true,
                userSession: userSession,
                mainCoordinator: mainCoordinator
            )
            shareVC.onDismiss = { vc, _ in vc.dismiss(animated: true) }
            viewController.present(shareVC, animated: true)
        }
    }

    func shareViaActivitySheet() async {
        guard let viewController = topViewController() else { return }
        await withReport(from: viewController) { url in
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            viewController.present(activityVC, animated: true)
        }
    }

    func sendEmail() async {
        guard let viewController = topViewController() else { return }
        let indicator = BlockingActivityIndicator(
            view: viewController.view,
            accessibilityAnnouncement: nil,
            style: .card
        )
        indicator.start(text: L10n.Localizable.Self.Settings.ShareDebugReport.creatingReport)
        do {
            let data = try await createReport.invokeData()
            indicator.stop()
            mailComposeItem = MailComposeItem(
                recipient: mailRecipient,
                subject: L10n.Localizable.Self.Settings.TechnicalReport.Mail.subject,
                messageBody: MFMailComposeViewController.prefilledBody(),
                attachmentData: data
            )
        } catch {
            indicator.stop()
            WireLogger.system.error("failed to create debug report: \(error)")
        }
    }

    // MARK: - Private

    private func withReport(
        from viewController: UIViewController,
        then action: @escaping @MainActor (URL) async -> Void
    ) async {
        let indicator = BlockingActivityIndicator(
            view: viewController.view,
            accessibilityAnnouncement: nil,
            style: .card
        )
        indicator.start(text: L10n.Localizable.Self.Settings.ShareDebugReport.creatingReport)
        do {
            let url = try await createReport.invoke()
            indicator.stop()
            await action(url)
        } catch {
            indicator.stop()
            WireLogger.system.error("failed to create debug report: \(error)")
        }
    }

    private func topViewController() -> UIViewController? {
        UIApplication.shared.topmostViewController(onlyFullScreen: false)
    }
}

