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
import WireLogging

final class IncrementalSyncObserver: IncrementalSyncObserverProtocol {

    enum DecryptionState {
        case notStarted
        case inProgress
        case done
    }

    private let syncAgent: any SyncAgentProtocol
    private let notificationCenter: NotificationCenter = .default
    private let notificationContext: NotificationContext

    private let decryptionQueue = DispatchQueue(label: "decryptionQueue")

    @Published private var decryptionState: DecryptionState = .notStarted

    private var cancellables = Set<AnyCancellable>()

    init(
        syncAgent: any SyncAgentProtocol,
        notificationContext: NotificationContext
    ) {
        self.syncAgent = syncAgent
        self.notificationContext = notificationContext

        setupObservation()
    }

    private func setupObservation() {
        if syncAgent.isSyncV2Enabled {
            syncAgent
                .syncStatePublisher
                .receive(on: decryptionQueue)
                .sink { [weak self] syncState in
                    switch syncState {
                    case .incrementalSyncing(.pullPendingEvents),
                         .incrementalSyncing(.receivingLiveEvents):
                        self?.decryptionState = .inProgress
                    case .incrementalSyncing(.processPendingEvents),
                         .suspended,
                         .liveSyncing:
                        self?.decryptionState = .done
                    default:
                        self?.decryptionState = .notStarted
                    }
                }
                .store(in: &cancellables)
        } else {
            notificationCenter
                .publisher(for: .didStartDecryptingEventsNotification)
                .receive(on: decryptionQueue)
                .sink { [weak self] _ in
                    self?.decryptionState = .inProgress
                }
                .store(in: &cancellables)

            notificationCenter
                .publisher(for: .didStopDecryptingEventsNotification)
                .receive(on: decryptionQueue)
                .sink { [weak self] _ in
                    self?.decryptionState = .done
                }
                .store(in: &cancellables)
        }
    }

    func waitUntilCanSendMessage() async {
        if syncAgent.isSyncV2Enabled {
            await waitUntilCanSendMessageV2()
        } else {
            await waitUntilCanSendMessageV1()
        }
    }

    private func waitUntilCanSendMessageV2() async {
        if decryptionState == .done {
            return
        } else {
            WireLogger.messaging.info(
                "waiting for decryption to finish before sending message",
                attributes: .safePublic
            )

            var cancellable: AnyCancellable?
            await withCheckedContinuation { continuation in
                var resumed = false
                cancellable = $decryptionState.sink { newDecryptionState in
                    if newDecryptionState == .done, !resumed {
                        resumed = true
                        continuation.resume()
                        cancellable?.cancel()
                    }
                }
            }

            WireLogger.messaging.info(
                "decryption finished",
                attributes: .safePublic
            )
        }
    }

    private func waitUntilCanSendMessageV1() async {
        if syncAgent.isLive || decryptionState == .done {
            WireLogger.messaging.info(
                "no need to wait, decryption finished",
                attributes: .safePublic
            )
            return
        }

        WireLogger.messaging.info(
            "Waiting for app to finish decrypting during incremental sync before sending message",
            attributes: .safePublic
        )

        for await _ in notificationCenter.notifications(
            named: .didStopDecryptingEventsNotification,
            object: notificationContext
        ) {
            WireLogger.messaging.info(
                "Decryption finished",
                attributes: .safePublic
            )
            break
        }
    }

}
