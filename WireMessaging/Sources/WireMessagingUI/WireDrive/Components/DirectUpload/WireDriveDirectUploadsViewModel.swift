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

package import Combine
package import Foundation
import SwiftUI
package import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells.Files.Upload
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells.Files.Upload
private typealias FilesStrings = L10n.Localizable.Conversation.WireCells.Files

/// Drives the Shared Drive uploads tracker: the collapsed pill and the expanded sheet.
///
/// Deliberately owned by `FilesViewContainer` rather than `FilesViewModel`, because a
/// `FilesViewModel` is created per navigation destination and this must survive it.
@MainActor
package final class WireDriveDirectUploadsViewModel: ObservableObject {

    /// What the tracker is currently showing.
    package enum Presentation: Equatable {

        /// Nothing to show.
        case hidden

        /// The collapsed pill.
        case pill

        /// The expanded sheet.
        case sheet
    }

    @Published package private(set) var summary: WireDriveDirectUploadsSummary = .empty
    @Published package var presentation: Presentation = .hidden

    /// Fires whenever an upload finishes, so the file list can refresh and show it.
    package let uploadCompleted = PassthroughSubject<Void, Never>()

    /// Whether `apply(_:)` has seen a first emission from the current `folderSubscription` yet.
    /// The first emission after `observe(folderPath:folderName:)` only establishes a baseline —
    /// otherwise a folder that already has finished uploads would read as one just completing.
    private var hasBaseline = false

    private let observeFolderUploads: any WireDriveObserveFolderDirectUploadsUseCaseProtocol
    private let cancelUpload: any WireDriveCancelDirectUploadUseCaseProtocol
    private let cancelUploads: any WireDriveCancelDirectUploadsUseCaseProtocol
    private let retryUpload: any WireDriveRetryDirectUploadUseCaseProtocol
    private let retryFailedUploads: any WireDriveRetryFailedDirectUploadsUseCaseProtocol
    private let clearFinishedUploads: any WireDriveClearFinishedDirectUploadsUseCaseProtocol

    package private(set) var currentFolderName = FilesStrings.navigationTitle
    private var currentFolderPath: String
    private var folderSubscription: AnyCancellable?

    package init(
        rootFolderPath: String,
        observeFolderUploads: any WireDriveObserveFolderDirectUploadsUseCaseProtocol,
        cancelUpload: any WireDriveCancelDirectUploadUseCaseProtocol,
        cancelUploads: any WireDriveCancelDirectUploadsUseCaseProtocol,
        retryUpload: any WireDriveRetryDirectUploadUseCaseProtocol,
        retryFailedUploads: any WireDriveRetryFailedDirectUploadsUseCaseProtocol,
        clearFinishedUploads: any WireDriveClearFinishedDirectUploadsUseCaseProtocol
    ) {
        self.observeFolderUploads = observeFolderUploads
        self.cancelUpload = cancelUpload
        self.cancelUploads = cancelUploads
        self.retryUpload = retryUpload
        self.retryFailedUploads = retryFailedUploads
        self.clearFinishedUploads = clearFinishedUploads
        self.currentFolderPath = rootFolderPath

        observe(folderPath: rootFolderPath, folderName: FilesStrings.navigationTitle)
    }

    /// Re-scopes the tracker to the folder the user is currently browsing.
    package func observe(folderPath: String, folderName: String) {
        currentFolderName = folderName
        currentFolderPath = folderPath
        hasBaseline = false
        folderSubscription = observeFolderUploads.invoke(folderPath: folderPath)
            .map { WireDriveDirectUploadsSummary(items: $0) }
            .sink { [weak self] summary in
                self?.apply(summary)
            }
    }

    // MARK: - Presentation

    private func apply(_ summary: WireDriveDirectUploadsSummary) {
        let hadItems = !self.summary.items.isEmpty
        let previousUploadedCount = self.summary.uploadedCount
        self.summary = summary

        if hasBaseline, summary.uploadedCount > previousUploadedCount {
            uploadCompleted.send()
        }
        hasBaseline = true

        guard !summary.items.isEmpty else {
            presentation = .hidden
            return
        }

        // A new batch surfaces itself, but must never yank an already expanded sheet shut.
        if !hadItems || presentation == .hidden {
            presentation = .pill
        }
    }

    package func expand() {
        presentation = .sheet
    }

    package func collapse() {
        Task {
            await clearFinishedUploads.invoke(destinationFolderPath: currentFolderPath)
        }

        presentation = summary.activeCount > 0 || summary.failedCount > 0 ? .pill : .hidden
    }

    package func dismiss() async {
        await clearFinishedUploads.invoke(destinationFolderPath: currentFolderPath)

        if summary.activeCount == 0 {
            presentation = .hidden
        } else {
            presentation = .pill
        }
    }

    // MARK: - Copy

    package var title: String {
        let total = summary.trackedCount

        if summary.activeCount > 0 {
            return total == 1 ? Strings.uploadingOne : Strings.uploadingMany(total)
        }

        if summary.uploadedCount == 0, summary.failedCount > 0 {
            return summary.failedCount == 1 ? Strings.failedOne : Strings.failedMany(summary.failedCount)
        }

        if total == 1 {
            return Strings.completeOne
        }

        return Strings.completeMany(summary.uploadedCount, total)
    }

    package var subtitle: String {
        if summary.failedCount > 0, summary.uploadedCount > 0 || summary.activeCount > 0 {
            return summary.failedCount == 1
                ? Strings.someFailedOne
                : Strings.someFailedMany(summary.failedCount)
        }

        if summary.failedCount > 0, summary.activeCount == 0, summary.uploadedCount == 0 {
            return Strings.destination(currentFolderName)
        }

        if summary.activeCount > 0, summary.trackedCount > 1, summary.uploadedCount > 0 {
            return Strings.progress(summary.uploadedCount, summary.trackedCount)
        }

        return Strings.destination(currentFolderName)
    }

    package enum HeaderAction: Equatable {
        case cancelAll
        case retryAll

        package var title: String {
            switch self {
            case .cancelAll: Strings.cancelAll
            case .retryAll: Strings.retryAll
            }
        }

        package var accessibilityLabel: String {
            switch self {
            case .cancelAll: Accessibility.cancelAll
            case .retryAll: Accessibility.retryAll
            }
        }
    }

    package var headerAction: HeaderAction? {
        if summary.activeCount > 0 {
            return .cancelAll
        }

        return summary.hasRetryableFailures ? .retryAll : nil
    }

    package var isFailureState: Bool {
        summary.activeCount == 0 && summary.failedCount > 0
    }

    // MARK: - Actions

    package func perform(_ action: HeaderAction) async {
        switch action {
        case .cancelAll:
            await cancelUploads.invoke(destinationFolderPath: currentFolderPath)
        case .retryAll:
            await retryFailedUploads.invoke(destinationFolderPath: currentFolderPath)
        }
    }

    package func cancel(uploadID: UUID) async {
        await cancelUpload.invoke(uploadID: uploadID)
    }

    package func retry(uploadID: UUID) async {
        await retryUpload.invoke(uploadID: uploadID)
    }
}
