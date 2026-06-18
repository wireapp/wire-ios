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
import SwiftUI
import UIKit
import WireDataModel
import WireLogging
import WireMainNavigationUI
import WireSyncEngine
import ZIPFoundation

// MARK: - Form option types

enum Reproducibility: String, CaseIterable, Identifiable {
    case always, sometimes, once, unknown
    var id: String { rawValue }
    var label: String {
        switch self {
        case .always: L10n.Localizable.BugReport.Reproducibility.always
        case .sometimes: L10n.Localizable.BugReport.Reproducibility.sometimes
        case .once: L10n.Localizable.BugReport.Reproducibility.once
        case .unknown: L10n.Localizable.BugReport.Reproducibility.unknown
        }
    }
}

enum BugImpact: String, CaseIterable, Identifiable {
    case widespread, broad, limited, isolated
    var id: String { rawValue }
    var label: String {
        switch self {
        case .widespread: L10n.Localizable.BugReport.Impact.widespread
        case .broad: L10n.Localizable.BugReport.Impact.broad
        case .limited: L10n.Localizable.BugReport.Impact.limited
        case .isolated: L10n.Localizable.BugReport.Impact.isolated
        }
    }
    var description: String {
        switch self {
        case .widespread: L10n.Localizable.BugReport.Impact.Widespread.description
        case .broad: L10n.Localizable.BugReport.Impact.Broad.description
        case .limited: L10n.Localizable.BugReport.Impact.Limited.description
        case .isolated: L10n.Localizable.BugReport.Impact.Isolated.description
        }
    }
}

enum BugSeverity: String, CaseIterable, Identifiable {
    case s1, s2, s3, s4
    var id: String { rawValue }
    var label: String {
        switch self {
        case .s1: L10n.Localizable.BugReport.Severity.s1
        case .s2: L10n.Localizable.BugReport.Severity.s2
        case .s3: L10n.Localizable.BugReport.Severity.s3
        case .s4: L10n.Localizable.BugReport.Severity.s4
        }
    }
    var description: String {
        switch self {
        case .s1: L10n.Localizable.BugReport.Severity.S1.description
        case .s2: L10n.Localizable.BugReport.Severity.S2.description
        case .s3: L10n.Localizable.BugReport.Severity.S3.description
        case .s4: L10n.Localizable.BugReport.Severity.S4.description
        }
    }
}

enum TriState: String, CaseIterable, Identifiable {
    case yes, no, unknown
    var id: String { rawValue }
    var label: String {
        switch self {
        case .yes: L10n.Localizable.BugReport.Tristate.yes
        case .no: L10n.Localizable.BugReport.Tristate.no
        case .unknown: L10n.Localizable.BugReport.Tristate.unknown
        }
    }
}

enum WorkaroundStatus: String, CaseIterable, Identifiable {
    case no, unknown, yes
    var id: String { rawValue }
    var label: String {
        switch self {
        case .no: L10n.Localizable.BugReport.Workaround.no
        case .unknown: L10n.Localizable.BugReport.Workaround.unknown
        case .yes: L10n.Localizable.BugReport.Workaround.yes
        }
    }
}

/// An image or video attachment selected by the user.
struct BugReportAttachment: Identifiable, Sendable {
    let id = UUID()
    let filename: String
    let data: Data
    let isVideo: Bool
    let thumbnailData: Data?
    var thumbnail: UIImage? {
        isVideo ? thumbnailData.flatMap { UIImage(data: $0) } : UIImage(data: data)
    }
}

// 25 MB — conservative limit matching the personal account asset upload cap.
let bugReportMaxAttachmentSize = 25 * 1024 * 1024

// MARK: - Flow model

/// Holds the guided bug-report form state, assembles `bug-report-package.zip`,
/// and submits it into a conversation the user picks (no default selection).
@MainActor
final class BugReportFlowModel: ObservableObject {

    private typealias MainCoordinator = WireMainNavigationUI.MainCoordinator<MainCoordinatorDependencies>

    // Page 1 — Description
    @Published var summary = ""
    @Published var expectedBehavior = ""
    @Published var actualBehavior = ""
    @Published var timeframe = Date()

    // Page 2 — Reproduction
    @Published var stepsToReproduce = "• \n• \n• "
    @Published var reproducibility: Reproducibility = .unknown
    @Published var workaroundStatus: WorkaroundStatus = .no
    @Published var workaroundDetail = ""

    // Page 3 — Classification
    @Published var impact: BugImpact? = nil
    @Published var severity: BugSeverity? = nil
    @Published var regression: TriState = .unknown
    @Published var lastKnownWorkingVersion = ""

    // Page 4 — Evidence & notes
    @Published var attachments: [BugReportAttachment] = []

    // Conversation picker
    @Published var conversations: [ZMConversation] = []
    @Published var relatedReports = ""
    @Published var additionalNotes = ""

    // Submission state
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    /// Invoked to dismiss the whole modal flow.
    var requestClose: (() -> Void)?

    private let userSession: UserSession?
    private let mainCoordinator: (any MainCoordinatorProtocol)?
    private let selfUserID: UUID?
    private let createDebugReport: CreateDebugReportUseCaseProtocol

    init(
        userSession: UserSession?,
        mainCoordinator: (any MainCoordinatorProtocol)?,
        selfUserID: UUID?,
        createDebugReport: CreateDebugReportUseCaseProtocol? = nil
    ) {
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.selfUserID = selfUserID
        self.createDebugReport = createDebugReport ?? CreateDebugReportUseCase(selfUserID: selfUserID)
    }

    var canSubmit: Bool {
        !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canProceedFromClassification: Bool {
        impact != nil && severity != nil
    }

    // MARK: - Submission

    func loadConversations() {
        guard let userSession else { return }
        conversations = FetchShareableConversationsUseCase(contextProvider: userSession.contextProvider).invoke()
    }

    /// Builds the package, sends it to the given conversation, then navigates into that conversation.
    func submitViaWire(to conversation: ZMConversation) async {
        guard let userSession else {
            errorMessage = L10n.Localizable.BugReport.Error.noSession
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let url = try await buildPackage()
            let metadata = ZMFileMetadata(fileURL: url, name: BugReportPackage.fileName)
            ShareFileUseCase(contextProvider: userSession.contextProvider)
                .invoke(fileMetadata: metadata, conversations: [conversation])
            requestClose?()
            if let coordinator = mainCoordinator as? MainCoordinator {
                await coordinator.showConversationList(conversationFilter: nil)
                coordinator.showConversation(conversation: conversation, message: nil)
            }
        } catch {
            WireLogger.system.error("failed to build bug report package: \(error)")
            errorMessage = L10n.Localizable.BugReport.Error.buildFailed
        }
    }

    /// Fallback path: hand the ZIP to the system share sheet (useful if Wire messaging itself is broken).
    func shareViaActivitySheet() async {
        guard let presenter = topViewController() else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let url = try await buildPackage()
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(activityVC, from: presenter)
        } catch {
            WireLogger.system.error("failed to build bug report package: \(error)")
            errorMessage = L10n.Localizable.BugReport.Error.buildFailed
        }
    }

    // MARK: - Package assembly

    private func buildPackage() async throws -> URL {
        let logsURL = try await createDebugReport.invoke()
        let manifest = makeManifest()
        let attachments = self.attachments
        return try await Task.detached(priority: .userInitiated) {
            try BugReportPackage.assemble(manifest: manifest, logsURL: logsURL, attachments: attachments)
        }.value
    }

    private func makeManifest() -> BugReportManifest {
        let filenames = [BugReportPackage.logsFileName] + attachments.map(\.filename)
        return BugReportManifest(
            schemaVersion: "1.0",
            metadata: .harvested(selfUserID: selfUserID, environment: userSession?.selfUser.domain ?? "unknown"),
            report: makeReport(),
            attachments: filenames
        )
    }


    private func makeReport() -> BugReportManifest.Report {
        let steps = stepsToReproduce
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let workaround: String = switch workaroundStatus {
        case .no: "none"
        case .unknown: "unknown"
        case .yes: workaroundDetail.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return BugReportManifest.Report(
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            expectedBehavior: nilIfBlank(expectedBehavior),
            actualBehavior: nilIfBlank(actualBehavior),
            timeframe: BugReportDateFormatter.iso8601.string(from: timeframe),
            stepsToReproduce: steps,
            reproducibility: reproducibility.rawValue,
            knownWorkaround: workaround,
            impact: impact?.rawValue ?? "",
            severity: severity?.rawValue ?? "",
            regression: regression.rawValue,
            lastKnownWorkingVersion: regression == .yes ? nilIfBlank(lastKnownWorkingVersion) : nil,
            relatedReports: nilIfBlank(relatedReports),
            additionalNotes: nilIfBlank(additionalNotes)
        )
    }

    private func nilIfBlank(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Presentation helpers

    private func topViewController() -> UIViewController? {
        UIApplication.shared.topmostViewController(onlyFullScreen: false)
    }

    private func present(_ controller: UIViewController, from presenter: UIViewController) {
        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        presenter.present(controller, animated: true)
    }
}

// MARK: - Package assembly helper

/// Assembles the on-disk `bug-report-package.zip`.
enum BugReportPackage {

    static let fileName = "bug-report-package.zip"
    static let logsFileName = "logs.zip"
    static let manifestFileName = "manifest.json"

    /// Writes the manifest, the logs archive, and any attachments into a folder and zips it.
    /// Runs off the main actor — all inputs are value types.
    nonisolated static func assemble(
        manifest: BugReportManifest,
        logsURL: URL,
        attachments: [BugReportAttachment]
    ) throws -> URL {
        let fileManager = FileManager.default
        let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("bug-report-\(UUID().uuidString)", isDirectory: true)
        let contents = root.appendingPathComponent("bug-report-package", isDirectory: true)
        try? fileManager.removeItem(at: root)
        try fileManager.createDirectory(at: contents, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let manifestData = try encoder.encode(manifest)
        try manifestData.write(to: contents.appendingPathComponent(manifestFileName))

        try fileManager.copyItem(at: logsURL, to: contents.appendingPathComponent(logsFileName))

        for attachment in attachments {
            try attachment.data.write(to: contents.appendingPathComponent(attachment.filename))
        }

        let zipURL = root.appendingPathComponent(fileName)
        try fileManager.zipItem(at: contents, to: zipURL, shouldKeepParent: false, compressionMethod: .deflate)
        try? fileManager.removeItem(at: contents)
        return zipURL
    }

}

// MARK: - Shareable

/// Adapts the package ZIP to the existing `ShareViewController` conversation picker.
struct ShareableBugReport: Shareable {

    typealias I = ZMConversation

    let fileMetadata: ZMFileMetadata
    let shareFile: ShareFileUseCaseProtocol

    func share(to: [some Any], userSession: UserSession) {
        guard let conversations = to as? [ZMConversation] else { return }
        shareFile.invoke(fileMetadata: fileMetadata, conversations: conversations)
    }

    func previewView(userSession: UserSession) -> UIView? {
        UIView()
    }
}

extension ShareableBugReport: Equatable {
    static func == (lhs: ShareableBugReport, rhs: ShareableBugReport) -> Bool {
        lhs.fileMetadata == rhs.fileMetadata
    }
}
