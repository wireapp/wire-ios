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

//import SwiftUI
//
//public final class BackupActionsViewModel: ObservableObject {
//    @Published var sections: [BackupActionsSection] = []
//
//    private let backupSource: BackupSource
//    private let onSuccessHandler: ((URL, @escaping Completion) -> Void)
//    private let onFailureHandler: ((Error) -> Void)
//
//    init(
//        backupSource: BackupSource,
//        onSuccessHandler: @escaping ((URL, @escaping Completion) -> Void),
//        onFailureHandler: @escaping ((Error) -> Void)
//    ) {
//        self.backupSource = backupSource
//        self.onSuccessHandler = onSuccessHandler
//        self.onFailureHandler = onFailureHandler
//
//        sections = [
//            BackupActionsSection(type: .backup)
//            //BackupActionsSection(type: .restore)
//        ]
//    }
//
//    func backupActiveAccount(password: String) {
//        backupSource.backupActiveAccount(password: password) { [weak self] backupResult in
//            switch backupResult {
//            case let .failure(error):
//                self?.onFailureHandler(error)
//            case let .success(url):
//                self?.onSuccessHandler(url) { [weak self] in
//                    self?.backupSource.clearPreviousBackups()
//                }
//            }
//        }
//    }
//}
