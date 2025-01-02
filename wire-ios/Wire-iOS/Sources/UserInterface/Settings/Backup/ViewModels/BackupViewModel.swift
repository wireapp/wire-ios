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

public final class BackupViewModel: ObservableObject {
    @Published var sections: [BackupSection] = []

    init() {
        sections = [
            BackupSection(
                type: .backup,
                action: {
                    print("Action for Section 1 triggered!")
                }
            )
//            BackupSection(
//                type: .restore,
//                action: {
//                    print("Action for Section 2 triggered!")
//                }
//            )
        ]
    }

//    private func backupActiveAccount() {
//        requestBackupPassword { [weak self] result in
//            guard let self, let password = result else { return }
//           // activityIndicator.start()
//
//            backupSource.backupActiveAccount(password: password) { backupResult in
//               // self.activityIndicator.stop()
//
//                switch backupResult {
//                case let .failure(error):
//                    self.presentAlert(for: error)
//                case let .success(url):
//                    self.presentShareSheet(with: url, from: indexPath)
//                }
//            }
//        }
//    }

//    private func requestBackupPassword(completion: @escaping (String?) -> Void) {
//        let passwordController = BackupPasswordViewController()
//        passwordController.onCompletion = { [weak passwordController] password in
//            passwordController?.dismiss(animated: true) {
//                completion(password)
//            }
//        }
//        let navigationController = KeyboardAvoidingViewController(viewController: passwordController)
//            .wrapInNavigationController()
//        navigationController.modalPresentationStyle = .formSheet
//        present(navigationController, animated: true)
//    }

}
