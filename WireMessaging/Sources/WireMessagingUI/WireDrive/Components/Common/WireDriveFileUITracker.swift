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
public import WireMessagingDomain

/// Intended for tracking the UI state of Drive files in different parts of the app.
/// Consumes state changes from `WireDriveLocalAsset.DownloadState` and provides observable state changes specifically
/// for the UI that represents the file.
/// Also notifies if and when a file should be opened automatically after download.
@MainActor
public final class WireDriveFileUITracker: ObservableObject {
    public enum State: Sendable {
        /// The file hasn't been downloaded yet.
        case notDownloaded

        /// The file is currently being downloaded.
        case downloading(progress: Double)

        /// The file has been downloaded.
        /// `downloaded(showReadyToOpen: true)` indicates that the file should be shown in a specific "ready to open"
        /// state in the UI.
        /// Will automatically change to `downloaded(showReadyToOpen: false)` state after a few seconds.
        case downloaded(showReadyToOpen: Bool)

        /// The download has failed.
        case failed(error: any Error)
    }

    public private(set) var state: State {
        didSet {
            switch (oldValue, state) {
            case (.downloading, .downloaded):
                // state is changing from downloading to downloaded:

                // if the download takes longer than this amount of time, the file is considered "big"
                let downloadTimeForBigFiles: TimeInterval = 0.3

                let fileIsBig = downloadingTimerStart
                    .flatMap { Date().timeIntervalSince($0) > downloadTimeForBigFiles } ?? true

                state = .downloaded(showReadyToOpen: fileIsBig)

                if fileIsBig {
                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        self.state = .downloaded(showReadyToOpen: false)
                    }
                } else {
                    fileShouldOpen?()
                }
            default:
                break
            }

            if case .downloading = state {
                if downloadingTimerStart == nil {
                    downloadingTimerStart = Date()
                }
            } else {
                downloadingTimerStart = nil
            }
        }
    }

    /// This closure will be called when a file should be automatically opened after the download.
    public var fileShouldOpen: (() -> Void)?

    private var downloadingTimerStart: Date?

    public init(downloadState: WireDriveLocalAsset.DownloadState) {
        self.state = Self.stateFromDownloadState(downloadState)
    }

    public func handleDownloadState(_ downloadState: WireDriveLocalAsset.DownloadState) {
        state = Self.stateFromDownloadState(downloadState)
    }

    private static func stateFromDownloadState(_ downloadState: WireDriveLocalAsset.DownloadState) -> State {
        switch downloadState {
        case .pending:
            .notDownloaded
        case let .downloading(progress):
            .downloading(progress: progress)
        case .downloaded:
            .downloaded(showReadyToOpen: false)
        case let .failed(error):
            .failed(error: error)
        }
    }
}
