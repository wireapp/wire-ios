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

import SwiftUI

public final class BackupRestoreViewController: UIViewController {

    private let viewModel: BackupRestoreViewModel

    public init(viewModel: BackupRestoreViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        let backupRestoreView = BackupRestoreView(
            viewModel: viewModel,
            exportBackupSheetContent: {
                ExportBackupView(
                    viewModel: .init(passwordValidator: self.viewModel.passwordValidator),
                    exportBackup: { password in
                        self.viewModel.backupActiveAccount(password: password)
                    }
                )
            }
        )
        let hostingController = UIHostingController(rootView: backupRestoreView)
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: hostingController.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
    }
}
