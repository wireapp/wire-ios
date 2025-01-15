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
    private let backupPasswordValidator: any BackupPasswordValidatorProtocol

    public init(
        viewModel: BackupRestoreViewModel,
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
        let backupPasswordValidator = backupPasswordValidator
        let backupRestoreView = BackupRestoreView(
            viewModel: viewModel,
            exportBackupSheetContent: {
                ExportBackupView(
                    viewModel: .init(
                        passwordValidator: backupPasswordValidator,
                        alertPresenter: DummyAlertPresenter(), // TODO: fix
                        exportBackupUseCase: DummyUseCase { password in // TODO: fix
                            self.viewModel.backupActiveAccount(password: password)
                        }
                    )
                )
            },
            importBackupSheetContent: {
                NavigationStack {
                    ImportBackupView(viewModel: .init(importBackupAction: { fatalError() })) { password in
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
}

// TODO: remove

private struct DummyAlertPresenter: BackupRestoreAlertPresenterProtocol {
    func todo() async -> Bool {
        fatalError("not implemented")
    }
}

private struct DummyUseCase: ExportBackupUseCaseProtocol {

    let action: (String) -> Void

    func invoke(url: URL, password: String) async {
        action(password)
    }
}
