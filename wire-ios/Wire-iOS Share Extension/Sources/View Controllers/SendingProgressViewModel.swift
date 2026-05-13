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

import WireCommonComponents

struct SendingProgressViewModel {

    enum ProgressMode {
        case preparing
        case sending
    }

    enum Action {
        case cancelTapped
        case updateMode(ProgressMode)
        case updateProgress(Float)
        case updateReachability(ServerReachability)
    }

    enum Effect {
        case cancel
    }

    struct DisplayState {
        let mode: ProgressMode
        let title: String
        let progress: Float
        let isProgressDeterministic: Bool
        let isConnectionStatusHidden: Bool
        let connectionStatusText: String
    }

    private let minimumProgress: Float

    private var mode: ProgressMode
    private var progress: Float
    private var reachability: ServerReachability

    init(
        mode: ProgressMode = .preparing,
        progress: Float = 0,
        reachability: ServerReachability = .ok,
        minimumProgress: Float = 0.125
    ) {
        self.mode = mode
        self.progress = progress
        self.reachability = reachability
        self.minimumProgress = minimumProgress
    }

    var displayState: DisplayState {
        DisplayState(
            mode: mode,
            title: title,
            progress: displayedProgress,
            isProgressDeterministic: mode == .sending,
            isConnectionStatusHidden: reachability == .ok,
            connectionStatusText: L10n.ShareExtension.NoInternetConnection.title
        )
    }

    @discardableResult
    mutating func perform(_ action: Action) -> [Effect] {
        switch action {
        case .cancelTapped:
            return [.cancel]

        case let .updateMode(mode):
            self.mode = mode

        case let .updateProgress(progress):
            mode = .sending
            self.progress = progress

        case let .updateReachability(reachability):
            self.reachability = reachability
        }

        return []
    }

    private var title: String {
        switch mode {
        case .preparing:
            L10n.ShareExtension.Preparing.title
        case .sending:
            L10n.ShareExtension.SendingProgress.title
        }
    }

    private var displayedProgress: Float {
        switch mode {
        case .preparing:
            minimumProgress
        case .sending:
            (progress / (1 + minimumProgress)) + minimumProgress
        }
    }

}
