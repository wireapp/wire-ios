//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging

// sourcery: AutoMockable
public protocol QuickSyncObserverInterface {
    func waitForDecryptionOfEventsToFinish() async
}

enum DecryptionState {
    case notStarted
    case inProgress
    case done
}

public extension Notification.Name {

    /// Published before the first event is decrypted and stored.
    static let didStartDecryptingEventsNotification = Self("EventProcessorDidStartDecryptingEventsNotification")

    /// Published after the last event has been decrypted and stored.
    static let didStopDecryptingEventsNotification = Self("EventProcessorDidFinishDecryptingEventsNotification")
}

import Combine

public final class QuickSyncObserver: QuickSyncObserverInterface {

    private let context: NSManagedObjectContext
    private let applicationStatus: ApplicationStatus
    private let notificationCenter: NotificationCenter = .default
    private let notificationContext: NotificationContext

    private let decryptionQueue = DispatchQueue(label: "decryptionQueue")

    private var decryptionState: DecryptionState = .notStarted
    private var cancellables = Set<AnyCancellable>()

    public init(
        context: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        notificationContext: NotificationContext
    ) {
        self.context = context
        self.applicationStatus = applicationStatus
        self.notificationContext = notificationContext

        setupObservation()
    }

    private func setupObservation() {
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

    public func waitForDecryptionOfEventsToFinish() async {
        if await quickSyncHasCompleted() || finishedDecrypting {
            WireLogger.messaging.info(
                "no need to wait, because app has finished quick sync, so decryption too",
                attributes: .safePublic
            )
            return
        }

        WireLogger.messaging.info(
            "Waiting for app to finish decrypting during quickSync before sending message",
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

    private var finishedDecrypting: Bool {
        decryptionState == .done
    }
    
    
    private func quickSyncHasCompleted() async -> Bool {
        await context.perform {
            self.applicationStatus.synchronizationState == .online
        }
    }
}
