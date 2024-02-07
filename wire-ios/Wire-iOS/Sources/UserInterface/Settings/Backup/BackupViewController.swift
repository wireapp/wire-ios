//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import UIKit

final class BackupViewController: UIViewController, SpinnerCapable {
    var dismissSpinner: SpinnerCompletion?

    private let tableView = UITableView(frame: .zero)
    private var cells: [UITableViewCell.Type] = []
    let backupSource: BackupSource

    init(backupSource: BackupSource) {
        self.backupSource = backupSource
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationTitle()
        setupViews()
        setupLayout()
    }

    private func setupViews() {
        view.backgroundColor = .clear

        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor(white: 1, alpha: 0.1)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self

        // this is necessary to remove the placeholder cells
        tableView.tableFooterView = UIView()
        cells = [BackupStatusCell.self, BackupActionCell.self]

        cells.forEach {
            tableView.register($0.self, forCellReuseIdentifier: $0.reuseIdentifier)
        }
    }

    private func setupLayout() {
        tableView.fitIn(view: view)
    }

    private func setupNavigationTitle() {
        let title = L10n.Localizable.Self.Settings.HistoryBackup.title.capitalized
        navigationItem.setupNavigationBarTitle(title: title)
    }

    var loadingHostController: SpinnerCapableViewController {
        return (navigationController as? SpinnerCapableViewController) ?? self
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension BackupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: cells[indexPath.row].reuseIdentifier, for: indexPath)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row == 1 else { return }
        backupActiveAccount(indexPath: indexPath)
    }
}

// MARK: - Backup Logic

private extension BackupViewController {

    func backupActiveAccount(indexPath: IndexPath) {
        requestBackupPassword { [weak self] result in
            guard let self, let password = result else { return }
            self.loadingHostController.isLoadingViewVisible = true

            self.backupSource.backupActiveAccount(password: password) { backupResult in
                self.loadingHostController.isLoadingViewVisible = false

                switch backupResult {
                case .failure(let error):
                    self.presentAlert(for: error)
                    BackupEvent.exportFailed.track()
                case .success(let url):
                    self.presentShareSheet(with: url, from: indexPath)
                }
            }
        }
    }

    private func requestBackupPassword(completion: @escaping (String?) -> Void) {
        let passwordController = BackupPasswordViewController()
        passwordController.onCompletion = { [weak passwordController] password in
            passwordController?.dismiss(animated: true) {
                completion(password)
            }
        }
        let navigationController = KeyboardAvoidingViewController(viewController: passwordController).wrapInNavigationController()
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }

    private func presentAlert(for error: Error) {
        let alert = UIAlertController(
            title: L10n.Localizable.Self.Settings.HistoryBackup.Error.title,
            message: error.localizedDescription,
            alertAction: .ok(style: .cancel)
        )

        present(alert, animated: true)
    }

    private func presentShareSheet(with url: URL, from indexPath: IndexPath) {
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityController.completionWithItemsHandler = { _, _, _, _ in
            SessionManager.clearPreviousBackups()
        }
        activityController.popoverPresentationController.apply {
            $0.sourceView = tableView
            $0.sourceRect = tableView.rectForRow(at: indexPath)
        }
        self.present(activityController, animated: true)
    }
}
