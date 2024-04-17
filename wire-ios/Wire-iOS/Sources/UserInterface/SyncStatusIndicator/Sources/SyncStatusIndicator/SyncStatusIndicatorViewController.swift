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

import SwiftUI

/// A container view controller for the `SyncStatusIndicatorView`.
final class SyncStatusIndicatorViewController: UIViewController {

    var syncStatus: SyncStatus? {
        didSet {
            guard oldValue != syncStatus else { return }
            Task { await applySyncStatus() }
        }
    }

    private var isApplyingSyncStatus = false

    private let syncStatusIndicatorView = SyncStatusIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        setupSubviews()
    }

    private func setupSubviews() {
        syncStatusIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(syncStatusIndicatorView)
        syncStatusIndicatorView.alpha = 0
        NSLayoutConstraint.activate([
            syncStatusIndicatorView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
            syncStatusIndicatorView.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: syncStatusIndicatorView.trailingAnchor, multiplier: 1)
        ])
    }

    private func applySyncStatus() async {

        guard
            !isApplyingSyncStatus,
            syncStatusIndicatorView.syncStatus != syncStatus,
            let syncStatusWindow = view.window,
            let keyWindow = syncStatusWindow.windowScene?.keyWindow
        else { return }

        // set a flag and keep a copy of the value, in case the status will be changed
        isApplyingSyncStatus = true
        let syncStatus = syncStatus

        // fade out current status and set the new value
        if syncStatusIndicatorView.alpha != 0 {
            await UIView.animate(withDuration: 0.5) {
                self.syncStatusIndicatorView.alpha = 0
            }
        }
        syncStatusIndicatorView.syncStatus = syncStatus

        if syncStatus == .none {
            // hide the sync status window and expand the key window to full screen again
            await UIView.animate(withDuration: 0.5) {
                syncStatusWindow.frame.size = .zero
                keyWindow.frame = keyWindow.screen.bounds
            }

        } else if syncStatusWindow.frame.origin != .zero {

            // determine the final size
            view.setNeedsLayout()
            view.layoutIfNeeded()
            let newHeight = view.convert(syncStatusIndicatorView.frame, to: syncStatusWindow).maxY + 8
            syncStatusWindow.frame = .init(
                origin: .init(x: 0, y: -newHeight),
                size: .init(width: keyWindow.frame.width, height: newHeight)
            )
            print("syncStatusWindow.frame:", syncStatusWindow.frame)
            // show the sync status window
            print("syncStatusWindow.frame.origin: .zero")
            print("keyWindow.frame:", CGRect(
                origin: CGPoint(x: 0, y: newHeight),
                size: .init(
                    width: keyWindow.screen.bounds.size.width,
                    height: keyWindow.screen.bounds.size.width - newHeight
                )
            ))
            await UIView.animate(withDuration: 0.5) {
                syncStatusWindow.frame.origin = .zero
                keyWindow.frame = .init(
                    origin: CGPoint(x: 0, y: newHeight),
                    size: .init(
                        width: keyWindow.screen.bounds.size.width,
                        height: keyWindow.screen.bounds.size.height - newHeight
                    )
                )
            }
            // fade in current status
            await UIView.animate(withDuration: 0.5) {
                self.syncStatusIndicatorView.alpha = 1
            }

        } else {

            // update the status
            fatalError("TODO")
        }

        // clear flag and if the status changed in the mean time, start overs
        isApplyingSyncStatus = false
        if self.syncStatus != syncStatus {
            Task { await applySyncStatus() }
        }
    }

    /// TODO: description
    private func showSyncStatusView(_ syncStatusWindow: UIWindow, _ keyWindow: UIWindow) {

        // make the sync status window visible
        syncStatusWindow.isHidden = false

        // fade out the current status
        UIView.animate(withDuration: 0.5) { [self] in
            syncStatusIndicatorView.alpha = 0
        } completion: {  [self] _ in

            syncStatusIndicatorView.syncStatus = syncStatus

            // make the key window full screen again
            UIView.animate(withDuration: 0.5) {
                syncStatusWindow.frame.size = .zero
                keyWindow.frame = keyWindow.screen.bounds
            } completion: { _ in

                // hide the sync status window
                syncStatusWindow.isHidden = true
            }
        }
    }

    /// Restores key window to full screen and hide sync status window.
    private func hideSyncStatusView() async {
        guard
            let syncStatusWindow = view.window,
            !syncStatusWindow.isHidden,
            let keyWindow = syncStatusWindow.windowScene?.keyWindow
        else { return }

        // fade out the current status
        UIView.animate(withDuration: 0.5) { [self] in
            syncStatusIndicatorView.alpha = 0
        } completion: {  [self] _ in

            syncStatusIndicatorView.syncStatus = syncStatus

            // make the key window full screen again
            UIView.animate(withDuration: 0.5) {
                syncStatusWindow.frame.size = .zero
                keyWindow.frame = keyWindow.screen.bounds
            } completion: { _ in

                // hide the sync status window
                syncStatusWindow.isHidden = true
            }
        }
    }
}

private struct SyncStatusIndicatorViewControllerRepresentable: UIViewControllerRepresentable {

    @State private(set) var syncStatus: SyncStatus?

    func makeUIViewController(context: Context) -> SyncStatusIndicatorViewController {
        .init()
    }

    func updateUIViewController(_ viewController: SyncStatusIndicatorViewController, context: Context) {}
}

#Preview("no status") {
    SyncStatusIndicatorViewControllerRepresentable(syncStatus: .none)
}

#Preview("no connectivity") {
    SyncStatusIndicatorViewControllerRepresentable(syncStatus: .noConnectivity)
}
