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

public import Foundation

/// Information of a Wire Drive local asset (e.g file) including it's download state.

public struct WireDriveLocalAsset: Equatable, Sendable {

    /// The current download state of the asset.

    public enum DownloadState: Equatable, Sendable {

        /// The asset is pending download.

        case pending

        /// The asset is currently being downloaded.

        case downloading(progress: Double)

        /// The asset has been downloaded and is available at the given cache key.

        case downloaded(cacheKey: String)

        /// The asset download failed with an error.

        case failed(error: any Error)

        public static func == (lhs: DownloadState, rhs: DownloadState) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending):
                true
            case let (.downloading(lhs), .downloading(rhs)):
                lhs == rhs
            case let (.downloaded(lhs), .downloaded(rhs)):
                lhs == rhs
            case (.failed, .failed):
                true
            default:
                false
            }
        }
    }

    /// The identifier of the asset on the Wire Drive backend.

    public let nodeID: UUID

    /// The eTag of the asset.
    ///
    /// If this changes the file represented by `nodeID` has changed and should be re-downloaded.

    public var eTag: String

    /// The path representing the asset in the Wire Drive file system.
    ///
    /// This is **not** the path on the local file system. It encodes information such as file name and extension.

    public var path: String

    /// The content type of the asset as defined by the backend.
    ///
    /// This is a MIME type (e.g. "image/png", "application/pdf").

    public var contentType: String?

    /// The size of the asset in bytes.

    public var size: UInt64?

    /// The download state of the asset.

    public var downloadState: DownloadState

    package init(
        nodeID: UUID,
        eTag: String,
        path: String,
        contentType: String?,
        size: UInt64?,
        downloadState: DownloadState
    ) {
        self.nodeID = nodeID
        self.eTag = eTag
        self.path = path
        self.contentType = contentType
        self.size = size
        self.downloadState = downloadState
    }
}

package extension WireDriveLocalAsset.DownloadState {

    var cacheKey: String? {
        switch self {
        case let .downloaded(key):
            key
        default:
            nil
        }
    }

    var isDownloading: Bool {
        switch self {
        case .downloading:
            true
        default:
            false
        }
    }
}

//TODO: move this type to its own file

/// Intended for tracking the UI state of Drive files in different parts of the app.
/// Consumes state changes from `WireDriveLocalAsset.DownloadState` and provides observable state changes specifically for the UI that represents the file.
/// Also notifies if and when a file should be opened automatically after download.
@MainActor
public final class WireDriveFileUITracker: Sendable, ObservableObject {
    public enum State: Sendable {
        /// The file hasn't been downloaded yet.
        case notDownloaded
        
        /// The file is currently being downloaded.
        case downloading(progress: Double)
        
        /// The file has been downloaded.
        /// `downloaded(showReadyToOpen: true)` indicates that the file should be shown in a specific "ready to open" state in the UI.
        /// Will automatically change to `downloaded(showReadyToOpen: false)` state after a few seconds.
        case downloaded(showReadyToOpen: Bool)
        
        /// The download has failed.
        case failed(error: any Error)
    }
    
    private(set) public var state: State {
        didSet {
            switch (oldValue, state) {
            case (.downloading, .downloaded):
                // state is changing from downloading to downloaded:
                
                // if the download takes longer than this amount of time, the file is considered "big"
                let downloadTimeForBigFiles: TimeInterval = 0.3
                
                let fileIsBig = downloadingTimerStart.flatMap { Date().timeIntervalSince($0) > downloadTimeForBigFiles } ?? true
                
                self.state = .downloaded(showReadyToOpen: fileIsBig)
                
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
    public var fileShouldOpen: (() -> ())?
    
    private var downloadingTimerStart: Date? = nil
    
    public init(downloadState: WireDriveLocalAsset.DownloadState) {
        state = Self.stateFromDownloadState(downloadState)
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
