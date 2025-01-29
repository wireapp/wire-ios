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
    // TODO: move into ViewModel
    private let backupPasswordValidator: any BackupPasswordValidatorProtocol

    public init(
        viewModel: BackupRestoreViewModel,
        // TODO: move into ViewModel
        backupPasswordValidator: any BackupPasswordValidatorProtocol
    ) {
        self.viewModel = viewModel
        self.backupPasswordValidator = backupPasswordValidator
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
            exportBackupSheetContent: { [backupPasswordValidator] exportBackupAction in
                SetExportPasswordView(
                    viewModel: SetExportPasswordViewModel(
                    passwordValidator: /*viewModel.*/ backupPasswordValidator,
                    exportBackupAction: /*viewModel.*/ exportBackupAction
                )
                )
            },
            importBackupSheetContent: {
                NavigationStack {
                    _ImportBackupView(viewModel: .init(importBackupAction: { fatalError() })) { password in
                        if let fileURL = /*selectedFileURL*/ URL(string: "TODO: selectedFileURL") {
                            self.viewModel.restoreFromBackup(
                                at: fileURL,
                                password: password,
                                completion: { _ in }
                            )
                        }
                    }
                }
                .presentationDetents([.medium])
            },
            presentActivityViewController: { [weak self] backupURL, anchorView in
                await self?.presentExportActivity(url: backupURL, anchorView: anchorView)
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
            view.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    private func presentExportActivity(url: URL, anchorView: UIViewController) async {
        await withCheckedContinuation { continuation in
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: .none)
            activityViewController.completionWithItemsHandler = { _, _, _, _ in continuation.resume() }
            if let popoverPresentationController = activityViewController.popoverPresentationController {
                popoverPresentationController.sourceView = anchorView.view
                popoverPresentationController.sourceRect = anchorView.view.bounds.insetBy(dx: -10, dy: -10)
            }
            anchorView.present(activityViewController, animated: true)
        }
    }
}
