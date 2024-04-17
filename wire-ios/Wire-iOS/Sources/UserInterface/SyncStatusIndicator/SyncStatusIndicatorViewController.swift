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

    let syncStatusIndicatorView = SyncStatusIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    private func setupSubviews() {
        syncStatusIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(syncStatusIndicatorView)
        NSLayoutConstraint.activate([
            syncStatusIndicatorView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
            syncStatusIndicatorView.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: syncStatusIndicatorView.trailingAnchor, multiplier: 1)
        ])
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
