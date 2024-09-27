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

import MessageUI
import WireCommonComponents
import WireSyncEngine

// MARK: - SettingsDebugReportViewModelProtocol

// sourcery: AutoMockable
protocol SettingsDebugReportViewModelProtocol {
    /// Send a debug report via email or shows fallback alert if email is not available
    func sendReport(sender: UIView)

    /// Presents a list of conversation for the user to share the debug report with
    func shareReport()
}

// MARK: - SettingsDebugReportViewModel

class SettingsDebugReportViewModel: SettingsDebugReportViewModelProtocol {
    // MARK: Lifecycle

    init(
        router: SettingsDebugReportRouterProtocol,
        shareFile: ShareFileUseCaseProtocol,
        fetchShareableConversations: FetchShareableConversationsUseCaseProtocol,
        logsProvider: LogFilesProviding = LogFilesProvider(),
        fileMetaDataGenerator: FileMetaDataGenerating = FileMetaDataGenerator()
    ) {
        self.router = router
        self.shareFile = shareFile
        self.fetchShareableConversations = fetchShareableConversations
        self.logsProvider = logsProvider
        self.fileMetaDataGenerator = fileMetaDataGenerator
    }

    // MARK: Internal

    // MARK: - Interface

    func sendReport(sender: UIView) {
        if MFMailComposeViewController.canSendMail() {
            Task {
                await router.presentMailComposer()
            }
        } else {
            router.presentFallbackAlert(sender: sender)
        }
    }

    func shareReport() {
        do {
            let conversations = fetchShareableConversations.invoke()
            let logsURL = try logsProvider.generateLogFilesZip()

            fileMetaDataGenerator.metadataForFileAtURL(
                logsURL,
                UTI: logsURL.UTI(),
                name: logsURL.lastPathComponent
            ) { [weak self] metadata in

                guard let `self` else { return }

                let shareableDebugReport = ShareableDebugReport(
                    logFileMetadata: metadata,
                    shareFile: shareFile
                )

                router.presentShareViewController(
                    destinations: conversations,
                    debugReport: shareableDebugReport
                )
            }
        } catch {
            WireLogger.system.error("failed to generate log files \(error)")
        }
    }

    // MARK: Private

    // MARK: - Properties

    private let router: SettingsDebugReportRouterProtocol
    private let shareFile: ShareFileUseCaseProtocol
    private let fetchShareableConversations: FetchShareableConversationsUseCaseProtocol
    private let logsProvider: LogFilesProviding
    private let fileMetaDataGenerator: FileMetaDataGenerating
}
