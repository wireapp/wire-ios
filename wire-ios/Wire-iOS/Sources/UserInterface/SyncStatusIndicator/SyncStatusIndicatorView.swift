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

final class SyncStatusIndicatorView: UIView {

    // MARK: Constants

    private let minHeight: CGFloat = 4

    var syncStatus: SyncStatus? {
        didSet { applySyncStatus() }
    }

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        applySyncStatus()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
        applySyncStatus()
    }

    private func setupSubviews() {
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1),
            label.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1),
            trailingAnchor.constraint(equalToSystemSpacingAfter: label.trailingAnchor, multiplier: 1),
            bottomAnchor.constraint(equalToSystemSpacingBelow: label.bottomAnchor, multiplier: 1),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight)
        ])

        label.text = syncStatus == .noConnectivity ? "TODO" : ""
        label.textAlignment = .center
        label.backgroundColor = .green
    }

    private func applySyncStatus() {
        //
    }
}

private struct SyncStatusIndicatorViewRepresentable: UIViewRepresentable {

    @State private(set) var syncStatus: SyncStatus?

    func makeUIView(context: Context) -> SyncStatusIndicatorView {
        let view = SyncStatusIndicatorView()
        view.syncStatus = syncStatus
        return view
    }

    func updateUIView(_ view: SyncStatusIndicatorView, context: Context) {
        view.syncStatus = syncStatus
    }
}

#Preview("no status") {
    SyncStatusIndicatorViewRepresentable(syncStatus: .none)
}

#Preview("no connectivity") {
    SyncStatusIndicatorViewRepresentable(syncStatus: .noConnectivity)
}
