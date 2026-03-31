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
public import Observation

/// Intended for tracking the UI state of Drive files in different parts of the app.
/// Consumes state changes from `WireDriveLocalAsset.DownloadState` or
/// `AttachmentsCarouselItem.State` and provides observable state changes specifically
/// for the UI that represents the file.
/// Also notifies if and when a file should be opened automatically after download or upload.
@MainActor
@Observable
public final class WireDriveFileUITracker {
    public enum State: Sendable, Hashable {
        /// The file hasn't been downloaded or uploaded yet.
        case notLoaded

        /// The file is currently being downloaded or uploaded.
        case loading(progress: Double, isLargeFile: Bool)

        /// The file has been downloaded or uploaded.
        /// `loaded(showReadyToOpen: true)` indicates that the file should be shown in a specific "ready to open"
        /// state in the UI.
        /// Will automatically change to `loaded(showReadyToOpen: false)` state after a few seconds.
        case loaded(showReadyToOpen: Bool)

        /// The download or upload has failed.
        case failed
    }

    public private(set) var state: State = .notLoaded {
        didSet {
            switch (oldValue, state) {
            case let (.loading(_, isLargeFile), .loaded):
                // state is changing from loading to loaded:
                state = .loaded(showReadyToOpen: isLargeFile)

                if isLargeFile {
                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        self.state = .loaded(showReadyToOpen: false)
                    }
                } else {
                    onSmallFileLoaded?()
                }
            default:
                break
            }
        }
    }

    /// This closure will be called when a file should be automatically opened after the download or upload.
    public var onSmallFileLoaded: (() -> Void)?

    public func handleDownloadState(fromAsset asset: WireDriveLocalAsset) {
        state = Self.stateFromAsset(asset)
    }

    // MARK: - State mapping from `WireDriveLocalAsset` (downloading a Drive file)

    private static func stateFromAsset(_ asset: WireDriveLocalAsset) -> State {
        switch asset.downloadState {
        case .pending:
            .notLoaded
        case let .downloading(progress):
            .loading(progress: progress, isLargeFile: asset.fileSize == .large)
        case .downloaded:
            .loaded(showReadyToOpen: false)
        case .failed:
            .failed
        }
    }

    // MARK: - State mapping from `AttachmentsCarouselItem` (uploading a Drive file)

    public func handleDownloadState(fromCarouselItem item: AttachmentsCarouselItem) {
        state = Self.stateFromCarouselItem(item)
    }

    private static func stateFromCarouselItem(_ carouselItem: AttachmentsCarouselItem) -> State {
        switch carouselItem.state {
        case let .uploading(progress):
            .loading(progress: Double(progress), isLargeFile: false)
        case .uploaded:
            .loaded(showReadyToOpen: false)
        case .failed:
            .failed
        }
    }
}
