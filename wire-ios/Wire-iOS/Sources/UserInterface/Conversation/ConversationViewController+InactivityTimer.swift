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

import SwiftUI
import UIKit
import WireDesign

private let inactivityTimeout: TimeInterval = 5
private let countdownSeconds = 30

// MARK: - Activity Observing Gesture Recognizer

/// A gesture recognizer that observes touches without consuming them.
private final class ActivityObservingGestureRecognizer: UIGestureRecognizer {
    var onActivity: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        onActivity?()
        state = .failed
    }
}

// MARK: - InactivityTimer

extension ConversationViewController {

    func setupActivityObserver() {
        let recognizer = ActivityObservingGestureRecognizer()
        recognizer.onActivity = { [weak self] in
            self?.resetInactivityTimerIfNeeded()
        }
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesEnded = false
        view.addGestureRecognizer(recognizer)

        let titleRecognizer = ActivityObservingGestureRecognizer()
        titleRecognizer.onActivity = { [weak self] in
            self?.handleTitleViewActivity()
        }
        titleRecognizer.cancelsTouchesInView = false
        titleRecognizer.delaysTouchesEnded = false
        navigationItem.titleView?.addGestureRecognizer(titleRecognizer)
    }

    private func handleTitleViewActivity() {
        guard inactivityOverlayHostingController != nil else { return }
        dismissInactivityTimerOverlay()
    }

    func startInactivityTimerIfNeeded() {
        guard conversation.confidentialityLevel == .highlySensitive else { return }
        scheduleInactivityTimer()
        registerForForegroundNotification()
    }

    func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        removeForegroundNotificationObserver()
    }

    private func registerForForegroundNotification() {
        guard foregroundObserverToken == nil else { return }
        foregroundObserverToken = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showInactivityTimerOverlay()
        }
    }

    private func removeForegroundNotificationObserver() {
        if let token = foregroundObserverToken {
            NotificationCenter.default.removeObserver(token)
            foregroundObserverToken = nil
        }
    }

    func resetInactivityTimerIfNeeded() {
        guard inactivityOverlayHostingController == nil else { return }
        guard conversation.confidentialityLevel == .highlySensitive else { return }
        stopInactivityTimer()
        scheduleInactivityTimer()
    }

    private func scheduleInactivityTimer() {
        inactivityTimer = Timer.scheduledTimer(
            withTimeInterval: inactivityTimeout,
            repeats: false
        ) { [weak self] _ in
            self?.showInactivityTimerOverlay()
        }
    }

    private func showInactivityTimerOverlay() {
        guard inactivityOverlayHostingController == nil else { return }

        let overlayView = InactivityTimerOverlayView(
            initialSeconds: countdownSeconds,
            onTap: { [weak self] in
                self?.dismissInactivityTimerOverlay()
            },
            onExpired: { [weak self] in
                self?.handleInactivityOverlayTap()
            }
        )

        let hostingController = UIHostingController(rootView: overlayView)
        hostingController.view.backgroundColor = .clear

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: conversationBarController.view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
        inactivityOverlayHostingController = hostingController
    }

    private func dismissInactivityTimerOverlay() {
        guard let hostingController = inactivityOverlayHostingController else { return }
        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
        inactivityOverlayHostingController = nil
        resetInactivityTimerIfNeeded()
    }

    private func handleInactivityOverlayTap() {
        dismissInactivityTimerOverlay()
        showUnlockView()
    }

    func showUnlockView() {
        let unlockView = SensitiveChatUnlockView(
            conversationName: conversation.displayName ?? "",
            mainColor: ColorTheme.Base.error.color,
            onUnlocked: { [weak self] in
                self?.unlockHostingController?.dismiss(animated: true) {
                    self?.unlockHostingController = nil
                    self?.startInactivityTimerIfNeeded()
                }
            },
            onDismiss: { [weak self] in
                self?.unlockHostingController?.dismiss(animated: true) {
                    self?.unlockHostingController = nil
                    self?.showInactivityTimerOverlay()
                }
            }
        )

        let hostingController = UIHostingController(rootView: unlockView)
        hostingController.modalPresentationStyle = .fullScreen
        unlockHostingController = hostingController
        present(hostingController, animated: true)
    }
}
