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

import avs
import Foundation
import WireSyncEngine

// MARK: - LoadingMessage

// The AVS library consists of several components, those are:
// - FlowManager: the component for establishing the network media flows.
// - MediaManager: the part responsible for audio routing on the device.
// - wcall: the Calling3 implementation.
// The entities must be initialized in certain expected order. The main requirement is that the MediaManager is only
// initialized after the FlowManager.

enum LoadingMessage {
    // Called when the app is starting
    case appStart
    // Called whem the FlowManager is created.
    case flowManagerLoaded
}

// MARK: - MediaManagerState

enum MediaManagerState {
    // MediaManager is not loaded.
    case initial
    // MediaManager is loaded.
    case loaded
}

// This enum is implementing the redundant Elm architecture state change. There is a single state and it's mutated by
// sending it the messages (there is no way to directly alter the state).
extension MediaManagerState {
    mutating func send(message: LoadingMessage) {
        switch (self, message) {
        case (.initial, .flowManagerLoaded):
            self = .loaded

        default:
            // already loaded
            break
        }
    }
}

// MARK: - MediaManagerLoader

final class MediaManagerLoader: NSObject {
    // MARK: Lifecycle

    override init() {
        super.init()
        self.flowManagerObserver = NotificationCenter.default.addObserver(
            forName: FlowManager.AVSFlowManagerCreatedNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { [weak self] _ in
                self?.send(message: .flowManagerLoaded)
            }
        )

        if AVSFlowManager.getInstance() != nil {
            send(message: .flowManagerLoaded)
        }
    }

    // MARK: Internal

    func send(message: LoadingMessage) {
        state.send(message: message)
    }

    // MARK: Private

    private var flowManagerObserver: AnyObject?

    private var state: MediaManagerState = .initial {
        didSet {
            switch state {
            case .loaded:
                loadMediaManager()
            default: break
            }
        }
    }

    private func loadMediaManager() {
        AVSMediaManager.sharedInstance()
        configureMediaManager()
    }

    private func configureMediaManager() {
        guard AVSFlowManager.getInstance() != nil,
              let mediaManager = AVSMediaManager.sharedInstance() else {
            return
        }

        mediaManager.configureSounds()
        mediaManager.observeSoundConfigurationChanges()
        mediaManager.isMicrophoneMuted = false
        mediaManager.isSpeakerEnabled = false
    }
}
